#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# speed.sh — Download & upload speed test (standalone tool)
#
#   ./speed.sh  →  Measure download speed via Cloudflare and print Mbps
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

_do_measure() {
  curl -s --max-time "$max_time" "https://speed.cloudflare.com/__down?bytes=$bytes" \
    -o /dev/null -w "%{speed_download}" > "$tmp" 2>/dev/null
}

_do_upload() {
  dd if=/dev/urandom bs=1M count=4 2>/dev/null |
    curl -s --max-time "$max_time" -X POST "https://nghttp2.org/anything" \
      --data-binary @- -o /dev/null -w "%{speed_upload}" > "$tmp" 2>/dev/null || true
}

measure_upload_speed() {
  local max_time=15
  local tmp
  tmp=$(mktemp)

  run_with_spinner \
    "Testing upload speed..." \
    _do_upload >&2 || true
  unset -f _do_upload 2>/dev/null || true

  local speed_kbps
  speed_kbps=$(cat "$tmp" 2>/dev/null || echo "0")
  rm -f "$tmp"

  echo "scale=1; $speed_kbps * 8 / 1000 / 1000" | bc -l 2>/dev/null || echo "?"
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
  local dl ul
  dl=$(measure_speed)
  log "Download speed: ${BOLD}${dl} Mbps${NC}"
  ul=$(measure_upload_speed)
  log "Upload speed:   ${BOLD}${ul} Mbps${NC}"
  printf "\n"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # shellcheck disable=SC1091
  source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/common.sh"
  main "$@"
fi
