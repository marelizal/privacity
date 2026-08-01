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

@test "parse_servers rejects empty file" {
  : > "$CSV"
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

@test "parse_servers outputs protocol in field 6" {
  cp "${BATS_TEST_DIRNAME}/fixtures/servers.csv" "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; parse_servers "'"$CSV"'" | head -1'
  [ "$status" -eq 0 ]
  proto=$(echo "$output" | cut -d'|' -f6)
  [[ "$proto" == "ovpn" ]]
}

@test "parse_servers outputs ping in field 5" {
  cp "${BATS_TEST_DIRNAME}/fixtures/servers.csv" "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; parse_servers "'"$CSV"'" | head -1'
  [ "$status" -eq 0 ]
  [[ "$output" == *"|10|"* ]]
}

@test "parse_servers sorts by ping when --fast is true" {
  cp "${BATS_TEST_DIRNAME}/fixtures/servers.csv" "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; parse_servers "'"$CSV"'" "" true'
  [ "$status" -eq 0 ]
  local first_ping
  first_ping=$(echo "$output" | head -1 | cut -d'|' -f5)
  [ "$first_ping" -le 20 ]
}

@test "parse_servers skips rows with non-numeric score" {
  cp "${BATS_TEST_DIRNAME}/fixtures/servers.csv" "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; parse_servers "'"$CSV"'"'
  [ "$status" -eq 0 ]
  [[ "$output" != *"Brazil"* ]]
}

@test "parse_servers skips rows with empty hostname" {
  cp "${BATS_TEST_DIRNAME}/fixtures/servers.csv" "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; parse_servers "'"$CSV"'"'
  [ "$status" -eq 0 ]
  [[ "$output" != *"Canada"* ]]
}

@test "parse_servers skips rows with fewer than 15 columns" {
  cp "${BATS_TEST_DIRNAME}/fixtures/servers.csv" "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; parse_servers "'"$CSV"'"'
  [ "$status" -eq 0 ]
  [[ "$output" != *"short.example.com"* ]]
}

@test "parse_servers filters by country" {
  cp "${BATS_TEST_DIRNAME}/fixtures/servers.csv" "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; parse_servers "'"$CSV"'" "Korea"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Korea, Republic of"* ]]
  [[ "$output" != *"Japan"* ]]
  [[ "$output" != *"United States"* ]]
}

# ──────── list_countries ────────────────────────────────────────────────────

@test "list_countries returns unique countries" {
  cp "${BATS_TEST_DIRNAME}/fixtures/servers.csv" "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; list_countries "'"$CSV"'"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Japan"* ]]
  [[ "$output" == *"Korea"* ]]
  [[ "$output" == *"United States"* ]]
}

@test "list_countries returns empty for missing file" {
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; list_countries /nonexistent.csv || true'
  [ "$status" -eq 0 ]
  [[ -z "$output" ]]
}

# ──────── _cache_fresh ──────────────────────────────────────────────────────

@test "_cache_fresh returns false for missing file" {
  run bash -c '
    source "'"$PRIVACITY"'" 2>/dev/null
    _cache_fresh /nonexistent.csv
  '
  [ "$status" -ne 0 ]
}

@test "_cache_fresh returns true for recently written file" {
  echo "data" > "$CSV"
  run bash -c '
    source "'"$PRIVACITY"'" 2>/dev/null
    _cache_fresh "'"$CSV"'"
  '
  [ "$status" -eq 0 ]
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

# ──────── find_server_entry / pick_entry ────────────────────────────────────

@test "parse_servers carries provider and auth fields" {
  printf 'vpn1.example.com|Japan|JP|9999|10|ovpn|YmFk|vpngate|vpn:vpn\n' > "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; parse_servers "'"$CSV"'" | head -1'
  [ "$status" -eq 0 ]
  [[ "$(echo "$output" | cut -d'|' -f8)" == "vpngate" ]]
  [[ "$(echo "$output" | cut -d'|' -f9)" == "vpn:vpn" ]]
}

@test "find_server_entry matches by hostname substring" {
  printf 'vpn1.example.com|Japan|JP|9999|10|ovpn|YmFk|vpngate|vpn:vpn\n' > "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; find_server_entry vpn1'
  [ "$status" -eq 0 ]
  [[ "$output" == *"vpn1.example.com"* ]]
}

@test "find_server_entry honors country filter" {
  printf 'vpn1.example.com|Japan|JP|9999|10|ovpn|YmFk|vpngate|vpn:vpn\n' > "$CSV"
  printf 'us1.example.com|United States|US|1000|30|ovpn|YmFk|vpngate|vpn:vpn\n' >> "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; find_server_entry example US'
  [ "$status" -eq 0 ]
  [[ "$output" == *"us1.example.com"* ]]
  [[ "$output" != *"vpn1.example.com"* ]]
}

@test "pick_entry returns specific server when --server given" {
  printf 'vpn1.example.com|Japan|JP|9999|10|ovpn|YmFk|vpngate|vpn:vpn\n' > "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; pick_entry "" false "vpn1"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"vpn1.example.com"* ]]
}

@test "pick_entry dies when --server not found" {
  printf 'vpn1.example.com|Japan|JP|9999|10|ovpn|YmFk|vpngate|vpn:vpn\n' > "$CSV"
  run bash -c 'source "'"$PRIVACITY"'" 2>/dev/null; pick_entry "" false auto "nope"'
  [ "$status" -ne 0 ]
  [[ "$output" == *"Server not found"* ]]
}

@test "connect_daemon writes auth file from entry field 9" {
  local b64
  b64=$(base64 < "${BATS_TEST_DIRNAME}/fixtures/valid.ovpn" | tr -d '\n')
  run bash -c '
    source "'"$PRIVACITY"'" 2>/dev/null
    _sudo() { "$@"; }
    openvpn() { echo "$*" > "$DIR/mock_args"; }
    connect_daemon "vpn1.example.com|Japan|JP|9999|10|ovpn|'"$b64"'|vpngate|vpn:vpn" >/dev/null 2>&1
    echo "---AUTH---"; cat "$DIR/auth.txt"
    echo "---ARGS---"; grep -o "\-\-auth-user-pass [^ ]*" "$DIR/mock_args"
  '
  [[ "$output" == *"---AUTH---"*"vpn"*"---ARGS---"*"--auth-user-pass"* ]]
}

@test "connect_daemon defaults vpngate auth to vpn:vpn" {
  local b64
  b64=$(base64 < "${BATS_TEST_DIRNAME}/fixtures/valid.ovpn" | tr -d '\n')
  run bash -c '
    source "'"$PRIVACITY"'" 2>/dev/null
    _sudo() { "$@"; }
    openvpn() { echo "$*" > "$DIR/mock_args"; }
    connect_daemon "vpn1.example.com|Japan|JP|9999|10|ovpn|'"$b64"'|vpngate" >/dev/null 2>&1
    cat "$DIR/auth.txt"
  '
  [[ "$output" == *"vpn"* ]]
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

# ──────── version parsing ──────────────────────────────────────────────────

@test "VERSION is parseable via bash eval" {
  local vers
  vers=$(bash -c 'source "'"${BATS_TEST_DIRNAME}"'/../lib/common.sh" 2>/dev/null; echo "$VERSION"' 2>/dev/null || echo "?")
  [ "$vers" != "?" ]
  # Accept semver (1.0.0) or git hash (e45b77f) — both are valid outputs
  [[ "$vers" =~ ^v?[0-9]+\.[0-9]+\.[0-9] || "$vers" =~ ^[0-9a-f]{7,}$ ]]
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
