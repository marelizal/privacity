#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# ovpn.sh — OpenVPN connection lifecycle (module)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

_append_ovpn() {
  local key="$1" line="$2"
  grep -qiE "^[[:space:]]*${key}([[:space:]]|$)" "$OVPN_CONFIG" || echo "$line" >> "$OVPN_CONFIG"
}

# Hardening: force server-cert verification, TLS 1.2+, and block IPv6
# (VPN Gate is IPv4-only, so IPv6 can otherwise leak around the tunnel).
_harden_config() {
  _append_ovpn remote-cert-tls "remote-cert-tls server"
  _append_ovpn tls-version-min "tls-version-min 1.2"

  local major minor
  major=$(openvpn --version 2>/dev/null | head -1 | sed -n 's/.*OpenVPN \([0-9]*\)\.[0-9]*.*/\1/p')
  minor=$(openvpn --version 2>/dev/null | head -1 | sed -n 's/.*OpenVPN [0-9]*\.\([0-9]*\).*/\1/p')
  if [[ -n "$major" && "$major" -ge 2 && -n "$minor" && "$minor" -ge 5 ]] &&
     ! grep -qiE '^[[:space:]]*block-ipv6' "$OVPN_CONFIG"; then
    echo "ifconfig-ipv6 fd15:53b6:dead::2/64 fd15:53b6:dead::1" >> "$OVPN_CONFIG"
    echo "redirect-gateway ipv6" >> "$OVPN_CONFIG"
    echo "block-ipv6" >> "$OVPN_CONFIG"
  fi
}

write_config() {
  local base64_data="$1"
  mkdir -p "$DIR"

  local decoded
  decoded=$(echo "$base64_data" | base64 -d 2>/dev/null) || die "Failed to decode OpenVPN config."

  decoded=$(echo "$decoded" | grep -viE '^\s*(script-security|up\b|down\b|route-up|ipchange|client-connect|client-disconnect|learn-address|auth-user-pass-verify|tls-verify|plugin|persist-key)' 2>/dev/null || true)

  echo "$decoded" > "$OVPN_CONFIG"

  if ! grep -q "data-ciphers" "$OVPN_CONFIG"; then
    echo "" >> "$OVPN_CONFIG"
    echo "data-ciphers DEFAULT:AES-128-CBC" >> "$OVPN_CONFIG"
  fi

  _harden_config
}

save_pid() { echo "$1" > "$PID_FILE"; }

read_pid() {
  if [[ -f "$PID_FILE" ]]; then
    cat "$PID_FILE"
  fi
}

save_host() { echo "$1|$2" > "$LAST_HOST"; }

read_host() {
  if [[ -f "$LAST_HOST" ]]; then
    cat "$LAST_HOST"
  fi
}

# Force DNS through the tunnel so queries can't leak to the ISP resolver.
_set_tunnel_dns() {
  command -v resolvectl &>/dev/null || return 0
  _sudo resolvectl dns tun0 1.1.1.1 1.0.0.1 2>/dev/null || true
  _sudo resolvectl domain tun0 "~." 2>/dev/null || true
  _sudo resolvectl flush-caches 2>/dev/null || true
}

_verify_ip_change() {
  local pre_ip="$1"
  [[ -n "$pre_ip" && "$pre_ip" != "-" ]] || return 0
  local post_ip
  post_ip=$(get_external_ip 2>/dev/null || true)
  if [[ -n "$post_ip" && "$post_ip" != "-" ]]; then
    if [[ "$post_ip" == "$pre_ip" ]]; then
      warn "External IP unchanged ($pre_ip) — possible leak, tunnel may be dead"
    else
      log "External IP: $pre_ip → $post_ip"
    fi
  fi
}

connect_daemon() {
  local entry="$1"
  local hostname country_long base64_data provider auth
  hostname=$(echo "$entry" | cut -d'|' -f1)
  country_long=$(echo "$entry" | cut -d'|' -f2)
  base64_data=$(echo "$entry" | cut -d'|' -f7)
  provider=$(echo "$entry" | cut -d'|' -f8)
  auth=$(echo "$entry" | cut -d'|' -f9)

  local pre_ip
  pre_ip=$(timeout 8 get_external_ip 2>/dev/null || true)

  write_config "$base64_data"
  save_host "$hostname" "$country_long"

  # VPN Gate public servers always use vpn/vpn.
  if [[ -z "$auth" && "$provider" == "vpngate" ]]; then
    auth="vpn:vpn"
  fi

  local -a auth_args=()
  if [[ -n "$auth" ]]; then
    local creds="$DIR/auth.txt"
    printf '%s\n%s\n' "${auth%%:*}" "${auth#*:}" > "$creds"
    chmod 600 "$creds"
    auth_args=(--auth-user-pass "$creds" --auth-nocache)
  fi

  log "Starting OpenVPN in daemon mode..."
  _sudo openvpn --config "$OVPN_CONFIG" --cd "$DIR" \
    "${auth_args[@]}" \
    --daemon \
    --log "$DIR/openvpn.log" \
    --writepid "$PID_FILE"

  local connected=false
  for _ in $(seq 1 20); do
    if ip link show tun0 &>/dev/null 2>&1 && [[ -s "$PID_FILE" ]]; then
      connected=true
      break
    fi
    sleep 1
  done

  if $connected; then
    notify "Connected to $hostname ($country_long)"
    log "Connected to ${hostname} (${country_long})"
    _set_tunnel_dns
    check_internet
    _verify_ip_change "$pre_ip"
    printf "\n"
    dim "  Run ${BOLD}privacity status${NC}${DIM} to check the connection${NC}"
    dim "  Run ${BOLD}privacity disconnect${NC}${DIM} to tear it down${NC}"
  else
    warn "Daemon started but no tunnel detected – check $DIR/openvpn.log"
  fi
}

_cleanup_tunnel() {
  for _ in $(seq 1 10); do
    ip link show tun0 &>/dev/null || return 0
    sleep 0.5
  done
  ip link show tun0 &>/dev/null && _sudo ip link delete tun0 2>/dev/null || true
}

_restore_network() {
  _sudo ip route flush cache 2>/dev/null || true

  if command -v resolvectl &>/dev/null; then
    _sudo resolvectl revert tun0 2>/dev/null || true
    _sudo resolvectl flush-caches 2>/dev/null || true
  fi

  if command -v systemd-resolve &>/dev/null; then
    _sudo systemd-resolve --flush-caches 2>/dev/null || true
  fi

  if command -v systemctl &>/dev/null; then
    _sudo systemctl restart systemd-resolved 2>/dev/null || true
  fi
}

cmd_disconnect() {
  local pid found=false
  pid=$(read_pid)

  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    found=true
    log "Disconnecting (PID $pid)..."
    _sudo kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  else
    log "No saved PID found – looking for active OpenVPN processes..."
    local pids
    pids=$(pgrep -f "openvpn.*$OVPN_CONFIG" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
      found=true
      # shellcheck disable=SC2086
      _sudo kill $pids 2>/dev/null || true
      # shellcheck disable=SC2086
      wait $pids 2>/dev/null || true
    fi
  fi

  rm -f "$PID_FILE" "$LAST_HOST" "$DIR/auth.txt"
  _cleanup_tunnel
  _restore_network

  if $found; then
    notify "Disconnected"
    log "Disconnected"
  else
    warn "No active VPN connection found."
  fi
}

cmd_status() {
  local hostname country_long
  if [[ -f "$LAST_HOST" ]]; then
    IFS='|' read -r hostname country_long < "$LAST_HOST"
  fi

  local vpn_intf=""
  ip link show tun0 &>/dev/null 2>&1 && vpn_intf="tun0"

  printf "\n  %sPrivacity%s %sstatus%s\n" "${BOLD}${WHITE}" "${NC}" "${DIM}" "${NC}"

  if [[ -n "$vpn_intf" ]]; then
    printf "  %s%-14s%s %sConnected%s\n" "${BOLD}" "Status" "${NC}" "${GREEN}" "${NC}"
    printf "  %s%-14s%s %s\n" "${BOLD}" "Server" "${NC}" "${hostname:---}"
    printf "  %s%-14s%s %s\n" "${BOLD}" "Country" "${NC}" "${country_long:---}"

    local ext_ip ping_ms
    ext_ip=$(get_external_ip)
    ping_ms=$(get_ping)
    printf "  %s%-14s%s %s\n" "${BOLD}" "External IP" "${NC}" "$ext_ip"
    printf "  %s%-14s%s %s ms\n" "${BOLD}" "Ping" "${NC}" "$ping_ms"

    local rx1 rx2 tx1 tx2
    rx1=$(cat "/sys/class/net/$vpn_intf/statistics/rx_bytes" 2>/dev/null || echo 0)
    tx1=$(cat "/sys/class/net/$vpn_intf/statistics/tx_bytes" 2>/dev/null || echo 0)
    sleep 2
    rx2=$(cat "/sys/class/net/$vpn_intf/statistics/rx_bytes" 2>/dev/null || echo 0)
    tx2=$(cat "/sys/class/net/$vpn_intf/statistics/tx_bytes" 2>/dev/null || echo 0)
    local rx_speed=$(( (rx2 - rx1) / 2048 ))
    local tx_speed=$(( (tx2 - tx1) / 2048 ))

    printf "  %s%-14s%s ↓ %d KB/s  ↑ %d KB/s\n" "${BOLD}" "Speed" "${NC}" "$rx_speed" "$tx_speed"
  else
    printf "  %s%-14s%s %sDisconnected%s\n" "${BOLD}" "Status" "${NC}" "${RED}" "${NC}"
  fi

  printf "\n"
}

cmd_reconnect() {
  local country="${1:-}"
  local fast="${2:-false}"
  local server="${3:-}"
  cmd_disconnect 2>/dev/null || true
  sleep 1
  local entry
  entry=$(pick_entry "$country" "$fast" "$server")
  local h c
  h=$(echo "$entry" | cut -d'|' -f1)
  c=$(echo "$entry" | cut -d'|' -f2)
  log "Best option found: ${h} (${c})"
  connect_tunnel "$entry"
}
