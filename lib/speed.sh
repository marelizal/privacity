#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# speed.sh — Download speed test (standalone tool)
#
#   ./speed.sh  →  Measure download speed via Cloudflare and print Mbps
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

_do_measure() {
  curl -s --max-time "$max_time" "https://speed.cloudflare.com/__down?bytes=$bytes" \
    -o /dev/null -w "%{speed_download}" > "$tmp" 2>/dev/null
}

measure_speed() {
  local bytes=12500000
  local max_time=15
  local tmp
  tmp=$(mktemp)

  run_with_spinner \
    "Testing download speed..." \
    _do_measure >&2 || true
  unset -f _do_measure 2>/dev/null || true

  local speed_kbps
  speed_kbps=$(cat "$tmp" 2>/dev/null || echo "0")
  rm -f "$tmp"

  echo "scale=1; $speed_kbps * 8 / 1000 / 1000" | bc -l 2>/dev/null || echo "?"
}

main() {
  printf "\n"
  local speed_mbps
  speed_mbps=$(measure_speed)
  log "Download speed: ${BOLD}${speed_mbps} Mbps${NC}"
  printf "\n"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/common.sh"
  main "$@"
fi
