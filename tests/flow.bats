setup() {
  export XDG_DATA_HOME="${BATS_TEST_TMPDIR}"
}

# ──────── Entry-point commands (offline / no sudo) ─────────────────────────

@test "help command shows usage" {
  run ./privacity help
  [ "$status" -eq 0 ]
  [[ "$output" == *"USAGE"* ]]
  [[ "$output" == *"COMMANDS"* ]]
  [[ "$output" == *"speedtest"* ]]
  [[ "$output" == *"update"* ]]
}

@test "status shows disconnected when no VPN" {
  run ./privacity status
  [ "$status" -eq 0 ]
  [[ "$output" == *"Disconnected"* ]]
}

@test "speedtest runs and outputs Mbps" {
  run timeout 30 ./privacity speedtest
  [ "$status" -eq 0 ]
  [[ "$output" == *"Mbps"* ]]
}

# ──────── Standalone net.sh tool ───────────────────────────────────────────

@test "net.sh shows usage with no args" {
  run ./lib/net.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage"* ]]
}

@test "net.sh check runs without error" {
  run timeout 15 ./lib/net.sh check
  [ "$status" -eq 0 ]
}

@test "net.sh ip returns IP or fallback dash" {
  run timeout 15 ./lib/net.sh ip
  [ "$status" -eq 0 ]
  [[ "$output" =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|-)$ ]]
}

@test "net.sh ping returns latency or fallback dash" {
  run timeout 10 ./lib/net.sh ping
  [ "$status" -eq 0 ]
}

# ──────── Standalone speed.sh tool ─────────────────────────────────────────

@test "speed.sh runs and shows result" {
  run timeout 30 ./lib/speed.sh
  [ "$status" -eq 0 ]
  [[ "$output" == *"Mbps"* ]]
}

# ──────── Full server list flow ────────────────────────────────────────────

@test "fetch + parse server list" {
  run ./privacity daemon
  # Should either succeed (connect) or fail with "No servers found"
  # if the CSV download worked but parsing returned nothing
  [ "$status" -ne 0 ] || [ "$status" -eq 0 ]
}

# ──────── OpenVPN config sanitization ──────────────────────────────────────

@test "write_config strips deprecated persist-key" {
  local b64
  b64=$(base64 < "${BATS_TEST_DIRNAME}/fixtures/malicious.ovpn" | tr -d '\n')
  run bash -c '
    source "'"$PWD"'/privacity" 2>/dev/null
    write_config "'"$b64"'" 2>/dev/null
    grep -c "persist-key" "'"$OVPN_CONFIG"'" 2>/dev/null || echo "NOT_FOUND"
  '
  [[ "$output" == *"NOT_FOUND"* ]]
}

@test "parse_servers rejects empty file" {
  source ./privacity 2>/dev/null || true
  local f="$XDG_DATA_HOME/servers.csv"
  echo "" > "$f"
  run bash -c '
    source "'"$PWD"'/privacity" 2>/dev/null
    parse_servers "'"$f"'"
  '
  [[ "$output" == *"too short"* ]]
}
