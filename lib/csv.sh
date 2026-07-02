#!/usr/bin/env bash
# csv.sh — Server list orchestrator + unified pipe parser (module)
set -euo pipefail

PROVIDERS=(vpngate vpnbook)

fetch_servers() {
  mkdir -p "$DIR/providers"
  chmod 700 "$DIR" 2>/dev/null || true

  local ok=false err
  for prov in "${PROVIDERS[@]}"; do
    if type "provider_${prov}_fetch" &>/dev/null 2>&1; then
      "provider_${prov}_fetch" && ok=true || err="$err $prov"
    fi
  done

  : > "$CSV"
  for prov in "${PROVIDERS[@]}"; do
    local db="$DIR/providers/${prov}.db"
    [[ -s "$db" ]] && cat "$db" >> "$CSV"
  done

  if [[ ! -s "$CSV" ]]; then
    warn "No servers fetched from any provider."
    [[ -n "${err:-}" ]] && warn "Failed providers:${err}"
    return 1
  fi

  log "Loaded $(wc -l < "$CSV") servers from ${#PROVIDERS[@]} provider(s)"
}

parse_servers() {
  local file="$1"
  local country_filter="${2:-}"
  local sort_by_ping="${3:-false}"
  local protocol_filter="${4:-auto}"

  if [[ ! -f "$file" ]]; then
    warn "Server list not found."
    return
  fi
  if [[ $(wc -l < "$file") -lt 1 ]]; then
    warn "Server list is too short (less than 1 line)."
    return
  fi

  python3 -c "
import sys
country_filter = sys.argv[1].strip().lower() if len(sys.argv) > 1 else ''
sort_by_ping = sys.argv[2].strip().lower() == 'true' if len(sys.argv) > 2 else False
protocol_filter = sys.argv[3].strip().lower() if len(sys.argv) > 3 else 'auto'
rows = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    parts = line.split('|')
    if len(parts) < 7:
        continue
    hostname, country_long, country_short, score_s, ping_s, protocol, b64 = parts[:7]
    score_s = score_s.strip()
    ping_s = ping_s.strip()
    if not score_s.isdigit():
        continue
    score = int(score_s)
    ping = int(ping_s) if ping_s.isdigit() else 999
    if not (hostname and country_short and b64):
        continue
    if country_filter and country_filter not in country_long.lower() and country_filter not in country_short.lower():
        continue
    if protocol_filter and protocol_filter != 'auto' and protocol != protocol_filter:
        continue
    rows.append((score, ping, hostname, country_long, country_short, protocol, b64))
if sort_by_ping:
    rows.sort(key=lambda r: (r[1], -r[0]))
else:
    rows.sort(key=lambda r: -r[0])
for score, ping, hostname, country_long, country_short, protocol, b64 in rows:
    print(f'{hostname}|{country_long}|{country_short}|{score}|{ping}|{protocol}|{b64}')
" "$country_filter" "$sort_by_ping" "$protocol_filter" 2>/dev/null < "$file"
}

list_countries() {
  local file="$1"
  [[ -f "$file" ]] || return
  [[ $(wc -l < "$file") -ge 1 ]] || return

  python3 -c "
import sys
seen = set()
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    parts = line.split('|')
    if len(parts) < 3:
        continue
    long_name = parts[1].strip()
    short_code = parts[2].strip()
    if long_name and short_code and short_code not in seen:
        seen.add(short_code)
        print(f'{long_name} ({short_code})')
" 2>/dev/null < "$file" | sort -u
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
