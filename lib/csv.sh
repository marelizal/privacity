#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# csv.sh — VPN Gate server list fetch & parse (module)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

_fetch_servers_cmd() {
  wget -q -O "$CSV" --timeout=15 "https://www.vpngate.net/api/iphone/" 2>/dev/null ||
    wget -q -O "$CSV" --timeout=15 "http://www.vpngate.net/api/iphone/"
}

fetch_servers() {
  mkdir -p "$DIR"
  chmod 700 "$DIR" 2>/dev/null || true
  run_with_spinner \
    "Downloading server list from VPN Gate..." \
    _fetch_servers_cmd \
    || die "Failed to download server list. Check your connection."
}

parse_servers() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    warn "Server list not found."
    return
  fi
  if [[ $(wc -l < "$file") -lt 3 ]]; then
    warn "Server list is too short (less than 3 lines)."
    return
  fi

  tail -n +3 "$file" | head -n 50 | tr -d '\r' |
  python3 -c "
import csv, sys
reader = csv.reader(sys.stdin)
rows = []
for row in reader:
    if len(row) < 15:
        continue
    hostname = row[0].strip()
    country_long = row[5].strip()
    country_short = row[6].strip()
    score_s = row[2].strip()
    if not score_s.isdigit():
        continue
    score = int(score_s)
    b64 = row[14].strip()
    if hostname and country_short and b64:
        rows.append((score, hostname, country_long, country_short, b64))
rows.sort(key=lambda r: -r[0])
for score, hostname, country_long, country_short, b64 in rows:
    print(f'{hostname}|{country_long}|{country_short}|{score}|{b64}')
" 2>/dev/null
}

_cache_fresh() {
  local file="$1"
  local ttl="${2:-300}"
  [[ -f "$file" ]] || return 1
  local now mtime
  now=$(date +%s)
  mtime=$(_stat_mtime "$file")
  (( now - mtime <= ttl ))
}
