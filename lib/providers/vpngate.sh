#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# vpngate.sh — VPN Gate provider (module)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PROVIDER_VPNGATE_PRIORITY=50

_provider_vpngate_fetch_csv() {
  timeout 25 wget -q -O "$DIR/providers/vpngate.csv" --timeout=10 --tries=2 \
    "https://www.vpngate.net/api/iphone/" 2>/dev/null ||
  timeout 25 wget -q -O "$DIR/providers/vpngate.csv" --timeout=10 --tries=2 \
    "http://www.vpngate.net/api/iphone/"
}

provider_vpngate_fetch() {
  mkdir -p "$DIR/providers"
  chmod 700 "$DIR" 2>/dev/null || true

  _provider_vpngate_fetch_csv || return 1

  local csv="$DIR/providers/vpngate.csv"
  [[ -f "$csv" ]] || return 1

  tail -n +3 "$csv" | head -n 50 | tr -d '\r' |
  python3 -c "
import csv, sys
reader = csv.reader(sys.stdin)
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
    if not (hostname and country_short):
        continue
    score = int(score_s)
    ping = int(ping_s) if ping_s.isdigit() else 999
    b64 = row[14].strip()
    if not b64:
        continue
    print(f'{hostname}|{country_long}|{country_short}|{score}|{ping}|ovpn|{b64}|vpngate|vpn:vpn')
" 2>/dev/null > "$DIR/providers/vpngate.db"

  [[ -s "$DIR/providers/vpngate.db" ]]
}
