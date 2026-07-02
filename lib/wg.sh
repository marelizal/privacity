#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# wg.sh — WireGuard connection lifecycle (module)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

write_wg_config() {
  local base64_data="$1"
  mkdir -p "$DIR"

  local decoded
  decoded=$(echo "$base64_data" | base64 -d 2>/dev/null) || die "Failed to decode WireGuard config."

  decoded=$(echo "$decoded" | grep -viE '^\s*(PreUp|PostUp|PreDown|PostDown)' 2>/dev/null || true)

  echo "$decoded" > "$WG_CONF"
}

connect_wireguard() {
  local entry="$1"
  local hostname country_long base64_data
  hostname=$(echo "$entry" | cut -d'|' -f1)
  country_long=$(echo "$entry" | cut -d'|' -f2)
  base64_data=$(echo "$entry" | cut -d'|' -f7)

  write_wg_config "$base64_data"
  save_host "$hostname" "$country_long"

  log "Starting WireGuard tunnel..."
  _sudo wg-quick up "$WG_CONF" 2>/dev/null || {
    _sudo ip link add "$WG_INTERFACE" type wireguard 2>/dev/null || true
    _sudo wg setconf "$WG_INTERFACE" "$WG_CONF"

    local wg_addr
    wg_addr=$(grep -i '^Address\s*=' "$WG_CONF" | head -1 | cut -d= -f2 | tr -d ' ')
    if [[ -n "$wg_addr" ]]; then
      _sudo ip addr add "$wg_addr" dev "$WG_INTERFACE"
    fi

    local wg_dns
    wg_dns=$(grep -i '^DNS\s*=' "$WG_CONF" | head -1 | cut -d= -f2 | tr -d ' ')
    if [[ -n "$wg_dns" ]] && command -v resolvectl &>/dev/null; then
      _sudo resolvectl dns "$WG_INTERFACE" "$wg_dns"
    fi

    _sudo ip link set "$WG_INTERFACE" up
    _sudo ip route add default dev "$WG_INTERFACE" 2>/dev/null || true
  }

  local connected=false
  for _ in $(seq 1 20); do
    if ip link show "$WG_INTERFACE" &>/dev/null 2>&1; then
      connected=true
      break
    fi
    sleep 1
  done

  if $connected; then
    notify "Connected to $hostname ($country_long) [WireGuard]"
    log "Connected to ${hostname} (${country_long}) [WireGuard]"
    check_internet
    printf "\n"
    dim "  Run ${BOLD}privacity status${NC}${DIM} to check the connection${NC}"
    dim "  Run ${BOLD}privacity disconnect${NC}${DIM} to tear it down${NC}"
  else
    warn "WireGuard tunnel not detected – check $WG_CONF"
  fi
}

disconnect_wireguard() {
  if ! ip link show "$WG_INTERFACE" &>/dev/null 2>&1; then
    return 0
  fi

  notify "Disconnected"
  log "Tearing down WireGuard tunnel..."

  _sudo wg-quick down "$WG_CONF" 2>/dev/null || {
    _sudo ip link set "$WG_INTERFACE" down 2>/dev/null || true
    _sudo ip link delete "$WG_INTERFACE" 2>/dev/null || true
  }

  _restore_network
  rm -f "$WG_CONF" "$LAST_HOST"
  log "Disconnected"
}
