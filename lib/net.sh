#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# net.sh — Network helpers (standalone tool)
#
#   ./net.sh check      → Internet connectivity test (DNS + HTTP)
#   ./net.sh ip         → Show external IP
#   ./net.sh ping       → Ping 8.8.8.8 and show latency
#   ./net.sh ping 1.1   → Ping a custom host
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

get_external_ip() {
  local ip
  ip=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null) || ip=""
  if [[ -z "$ip" ]]; then
    ip=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null) || ip=""
  fi
  if [[ -z "$ip" ]]; then
    ip=$(curl -s --max-time 5 https://icanhazip.com 2>/dev/null) || ip=""
  fi
  echo "${ip:--}"
}

get_ping() {
  ping -c 1 -W 3 "${1:-8.8.8.8}" 2>/dev/null |
    sed -n 's/.*time=\([0-9.]*\) ms/\1/p' || echo "-"
}

check_internet() {
  local dns_ok=false http_ok=false

  if host google.com 8.8.8.8 &>/dev/null || nslookup google.com 8.8.8.8 &>/dev/null || dig +short google.com @8.8.8.8 &>/dev/null; then
    dns_ok=true
  fi

  if curl -s --max-time 5 -o /dev/null -w "%{http_code}" https://www.google.com/generate_204 2>/dev/null | grep -q 204 ||
     curl -s --max-time 5 -o /dev/null https://clients3.google.com/generate_204 2>/dev/null; then
    http_ok=true
  fi

  if $dns_ok && $http_ok; then
    log "Internet OK — DNS + HTTP reachable"
  elif $dns_ok; then
    warn "DNS resolves but HTTP check failed — check firewall / routing"
  elif $http_ok; then
    warn "HTTP reachable but DNS resolution failed"
  else
    warn "No internet access detected through the VPN tunnel"
  fi
}

main() {
  case "${1:-}" in
    check|internet)
      check_internet
      ;;
    ip|external)
      get_external_ip
      ;;
    ping)
      get_ping "${2:-8.8.8.8}"
      ;;
    *)
      echo "Usage: net.sh {check|ip|ping [host]}" >&2
      exit 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # shellcheck disable=SC1091
  source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/common.sh"
  main "$@"
fi
