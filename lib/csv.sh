#!/usr/bin/env bash
# csv.sh — Server list orchestrator + unified pipe parser (module)
set -euo pipefail

PROVIDERS=(vpngate)

fetch_servers() {
  mkdir -p "$DIR/providers"
  chmod 700 "$DIR" 2>/dev/null || true

  local err=""
  for prov in "${PROVIDERS[@]}"; do
    if type "provider_${prov}_fetch" &>/dev/null 2>&1; then
      "provider_${prov}_fetch" || err="${err} ${prov}"
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
rows = []
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    parts = line.split('|')
    if len(parts) < 7:
        continue
    hostname, country_long, country_short, score_s, ping_s, protocol, b64 = parts[:7]
    provider = parts[7].strip() if len(parts) > 7 else ''
    auth = parts[8].strip() if len(parts) > 8 else ''
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
    rows.append((score, ping, hostname, country_long, country_short, protocol, b64, provider, auth))
if sort_by_ping:
    rows.sort(key=lambda r: (r[1], -r[0]))
else:
    rows.sort(key=lambda r: -r[0])
for score, ping, hostname, country_long, country_short, protocol, b64, provider, auth in rows:
    print(f'{hostname}|{country_long}|{country_short}|{score}|{ping}|{protocol}|{b64}|{provider}|{auth}')
" "$country_filter" "$sort_by_ping" 2>/dev/null < "$file"
}

# Pick the single server to connect to: explicit --server match, else best of the list.
pick_entry() {
  local country="${1:-}"
  local fast="${2:-false}"
  local server="${3:-}"

  if ! _cache_fresh "$CSV"; then
    fetch_servers
  else
    log "Using cached server list..."
  fi

  if [[ -n "$server" ]]; then
    local entry
    entry=$(find_server_entry "$server" "$country")
    [[ -n "$entry" ]] || die "Server not found: $server${country:+ in '$country'}. Run 'privacity list' to see available servers."
    printf '%s\n' "$entry"
    return 0
  fi

  local -a servers
  mapfile -t servers < <(parse_servers "$CSV" "$country" "$fast")
  ((${#servers[@]})) || _no_servers_hint "$country"
  printf '%s\n' "${servers[0]}"
}

# Find a server entry by hostname or country (case-insensitive substring).
# Optional country filter narrows the match.
find_server_entry() {
  local want="${1:-}"
  local country="${2:-}"
  want="${want,,}"
  country="${country,,}"
  [[ -s "$CSV" ]] || return 1
  awk -F'|' -v w="$want" -v c="$country" '
    (c == "" || tolower($2)==c || index(tolower($2), c) || tolower($3)==c || index(tolower($3), c)) &&
    (tolower($1)==w || index(tolower($1), w) || tolower($2)==w || index(tolower($2), w))
  ' "$CSV" 2>/dev/null | head -1
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
  [[ -s "$file" ]] || return 1
  local now mtime
  now=$(date +%s)
  mtime=$(_stat_mtime "$file")
  (( now - mtime <= ttl ))
}
