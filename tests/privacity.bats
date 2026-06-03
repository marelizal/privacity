setup() {
  export XDG_DATA_HOME="${BATS_TEST_TMPDIR}"
  export DIR="${XDG_DATA_HOME}/privacity"
  export CSV="$DIR/servers.csv"
  export OVPN_CONFIG="$DIR/active.ovpn"
  mkdir -p "$DIR"
}

PRIVACITY="${BATS_TEST_DIRNAME}/../privacity"

# ──────── parse_servers ────────────────────────────────────────────────────

@test "parse_servers rejects missing file" {
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; parse_servers /nonexistent.csv'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Server list not found"* ]]
}

@test "parse_servers rejects file with less than 3 lines" {
  echo "line1" > "$CSV"
  echo "line2" >> "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; parse_servers "'"$CSV"'"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"too short"* ]]
}

@test "parse_servers parses valid CSV and sorts by score descending" {
  cp "${BATS_TEST_DIRNAME}/fixtures/servers.csv" "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; parse_servers "'"$CSV"'"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Japan"* ]]
  [[ "$output" == *"Korea, Republic of"* ]]
  [[ "$output" == *"United States"* ]]
  [[ "$(echo "$output" | head -1)" == *"Japan"* ]]
}

@test "parse_servers handles quoted commas in country field" {
  cp "${BATS_TEST_DIRNAME}/fixtures/servers.csv" "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; parse_servers "'"$CSV"'"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Korea, Republic of"* ]]
}

# ──────── write_config ─────────────────────────────────────────────────────

@test "write_config strips script-security directive" {
  local b64
  b64=$(base64 < "${BATS_TEST_DIRNAME}/fixtures/malicious.ovpn" | tr -d '\n')
  run bash -c '
    source "'"$PRIVACITY"'" 2>/dev/null
    write_config "'"$b64"'" 2>/dev/null
    grep -c "script-security" "'"$OVPN_CONFIG"'" 2>/dev/null || echo "NOT_FOUND"
  '
  [[ "$output" == *"NOT_FOUND"* ]]
}

@test "write_config strips up directive" {
  local b64
  b64=$(base64 < "${BATS_TEST_DIRNAME}/fixtures/malicious.ovpn" | tr -d '\n')
  run bash -c '
    source "'"$PRIVACITY"'" 2>/dev/null
    write_config "'"$b64"'" 2>/dev/null
    grep -c "/bin/malicious.sh" "'"$OVPN_CONFIG"'" 2>/dev/null || echo "NOT_FOUND"
  '
  [[ "$output" == *"NOT_FOUND"* ]]
}

@test "write_config keeps valid config intact" {
  local b64
  b64=$(base64 < "${BATS_TEST_DIRNAME}/fixtures/valid.ovpn" | tr -d '\n')
  run bash -c '
    source "'"$PRIVACITY"'" 2>/dev/null
    write_config "'"$b64"'" 2>/dev/null
    grep -c "dev tun" "'"$OVPN_CONFIG"'" 2>/dev/null || echo "NOT_FOUND"
  '
  [[ "$output" != *"NOT_FOUND"* ]]
}

@test "write_config adds data-ciphers if missing" {
  local b64
  b64=$(base64 < "${BATS_TEST_DIRNAME}/fixtures/valid.ovpn" | tr -d '\n')
  run bash -c '
    source "'"$PRIVACITY"'" 2>/dev/null
    write_config "'"$b64"'" 2>/dev/null
    grep -c "data-ciphers" "'"$OVPN_CONFIG"'" 2>/dev/null || echo "NOT_FOUND"
  '
  [[ "$output" != *"NOT_FOUND"* ]]
}

@test "write_config fails on invalid base64" {
  run bash -c '
    source "'"$PRIVACITY"'" 2>/dev/null
    write_config "NOT_VALID_BASE64!!!"
  '
  [ "$status" -ne 0 ]
}

# ──────── _stat_mtime ──────────────────────────────────────────────────────

@test "_stat_mtime returns 0 for missing file" {
  run bash -c '
    source "'"$PRIVACITY"'" 2>/dev/null
    _stat_mtime /nonexistent_file_xyz
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "0" ]]
}

@test "_stat_mtime returns mtime for existing file" {
  local tmpfile="${BATS_TEST_TMPDIR}/testfile"
  touch "$tmpfile"
  run bash -c '
    source "'"$PRIVACITY"'" 2>/dev/null
    _stat_mtime "'"$tmpfile"'"
  '
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]
}

# ──────── get_external_ip ──────────────────────────────────────────────────

@test "get_external_ip returns dash on failure" {
  run bash -c '
    source "'"$PRIVACITY"'" 2>/dev/null
    curl() { return 1; }
    get_external_ip
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "-" ]]
}
