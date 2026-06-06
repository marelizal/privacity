#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# csv.sh — VPN Gate server list fetch & parse (module)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

_fetch_servers_cmd() {
  timeout 25 wget -q -O "$CSV" --timeout=10 --tries=2 "https://www.vpngate.net/api/iphone/" 2>/dev/null ||
    timeout 25 wget -q -O "$CSV" --timeout=10 --tries=2 "http://www.vpngate.net/api/iphone/"
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
  local country_filter="${2:-}"
  local sort_by_ping="${3:-false}"
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
country_filter = sys.argv[1].strip().lower() if len(sys.argv) > 1 else ''
sort_by_ping = sys.argv[2].strip().lower() == 'true' if len(sys.argv) > 2 else False
reader = csv.reader(sys.stdin)
rows = []
for row in reader:
    if len(row) < 15:
        continue
    hostname = row[0].strip()
    country_long = row[5].strip()
    country_short = row[6].strip()
    score_s = row[2].strip()
    ping_s = row[3].strip()
    if not score_s.isdigit():
        continue
    score = int(score_s)
    ping = int(ping_s) if ping_s.isdigit() else 999
    b64 = row[14].strip()
    if not (hostname and country_short and b64):
        continue
    if country_filter and country_filter not in country_long.lower() and country_filter not in country_short.lower():
        continue
    rows.append((score, ping, hostname, country_long, country_short, b64))
if sort_by_ping:
    rows.sort(key=lambda r: (r[1], -r[0]))
else:
    rows.sort(key=lambda r: -r[0])
for score, ping, hostname, country_long, country_short, b64 in rows:
    print(f'{hostname}|{country_long}|{country_short}|{score}|{ping}|{b64}')
" "$country_filter" "$sort_by_ping" 2>/dev/null
}

list_countries() {
  local file="$1"
  [[ -f "$file" ]] || return
  [[ $(wc -l < "$file") -ge 3 ]] || return
  tail -n +3 "$file" | tr -d '\r' |
  python3 -c "
import csv, sys
seen = set()
reader = csv.reader(sys.stdin)
for row in reader:
    if len(row) < 15:
        continue
    long_name = row[5].strip()
    short_code = row[6].strip()
    if long_name and short_code and short_code not in seen:
        seen.add(short_code)
        print(f'{long_name} ({short_code})')
" 2>/dev/null | sort -u
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
