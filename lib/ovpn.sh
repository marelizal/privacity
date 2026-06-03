#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# ovpn.sh — OpenVPN connection lifecycle (module)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

write_config() {
  local base64_data="$1"

  local decoded
  decoded=$(echo "$base64_data" | base64 -d 2>/dev/null) || die "Failed to decode OpenVPN config."

  decoded=$(echo "$decoded" | grep -viE '^\s*(script-security|up\b|down\b|route-up|ipchange|client-connect|client-disconnect|learn-address|auth-user-pass-verify|tls-verify|plugin)' 2>/dev/null || true)

  echo "$decoded" > "$OVPN_CONFIG"

  if ! grep -q "data-ciphers" "$OVPN_CONFIG"; then
    echo "" >> "$OVPN_CONFIG"
    echo "data-ciphers DEFAULT:AES-128-CBC" >> "$OVPN_CONFIG"
  fi
}

_tunnel_is_up() {
  local pid=$1
  ip link show tun0 &>/dev/null || return 1
  kill -0 "$pid" 2>/dev/null || return 1
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

connect_interactive() {
  local entry="$1"
  local hostname country_long base64_data
  hostname=$(echo "$entry" | cut -d'|' -f1)
  country_long=$(echo "$entry" | cut -d'|' -f2)
  base64_data=$(echo "$entry" | cut -d'|' -f5)

  write_config "$base64_data"
  save_host "$hostname" "$country_long"

  sudo openvpn --config "$OVPN_CONFIG" --cd "$DIR" --verb 0 &>/dev/null &
  local ovpn_pid=$!

  local spin=('-' '\\' '|' '/')
  local i=0 connected=false
  for _ in $(seq 1 20); do
    if _tunnel_is_up "$ovpn_pid"; then
      connected=true
      break
    fi
    if ! kill -0 "$ovpn_pid" 2>/dev/null; then
      break
    fi
    printf "\r  ${spin[$i]}   "
    i=$(( (i + 1) % 4 ))
    sleep 1
  done

  if ! $connected; then
    printf "\r  ${RED}x${NC}\n"
    error "Connection timed out or failed."
    sudo kill "$ovpn_pid" 2>/dev/null || true
    wait "$ovpn_pid" 2>/dev/null || true
    return 1
  fi

  printf "\r     \n"

  check_internet

  local speed_mbps
  speed_mbps=$(measure_speed)

  header

  local ext_ip ping_ms rx1 rx2 tx1 tx2
  ext_ip=$(get_external_ip)
  ping_ms=$(get_ping)

  rx1=$(cat /sys/class/net/tun0/statistics/rx_bytes 2>/dev/null || echo 0)
  tx1=$(cat /sys/class/net/tun0/statistics/tx_bytes 2>/dev/null || echo 0)

  printf "  ${BOLD}%-14s${NC} ${BOLD}%s${NC}\n" "External IP" "$ext_ip"
  printf "  ${BOLD}%-14s${NC} %s ms\n" "Ping" "$ping_ms"
  printf "  ${BOLD}%-14s${NC} %s\n" "Location" "$country_long"
  printf "  ${DIM}↓ 0 KB/s  |  ↑ 0 KB/s${NC}\n"
  printf "  ${BOLD}%-14s${NC} ${BOLD}%s${NC}\n" "Download" "${speed_mbps} Mbps"
  printf "  ${GREEN}✓${NC} VPN active. ${BOLD}Q${NC} disconnect  ${BOLD}S${NC} switch\n"

  while true; do
    rx2=$(cat /sys/class/net/tun0/statistics/rx_bytes 2>/dev/null || echo 0)
    tx2=$(cat /sys/class/net/tun0/statistics/tx_bytes 2>/dev/null || echo 0)
    local rx_speed=$(( (rx2 - rx1) / 2048 ))
    local tx_speed=$(( (tx2 - tx1) / 2048 ))
    rx1=$rx2
    tx1=$tx2

    printf "\033[3A\r  ${DIM}↓ ${rx_speed} KB/s  |  ↑ ${tx_speed} KB/s${NC}    \033[3B\r"

    read -r -s -t 2 -n1 key || true
    if [[ -n "${key:-}" && "${key,,}" == "q" ]]; then
      printf "\n\n"
      log "Disconnecting..."
      sudo kill "$ovpn_pid" 2>/dev/null || true
      wait "$ovpn_pid" 2>/dev/null || true
      log "Disconnected"
      break
    fi

    if [[ -n "${key:-}" && "${key,,}" == "s" ]]; then
      printf "\n\n"
      log "Switching server..."
      sudo kill "$ovpn_pid" 2>/dev/null || true
      wait "$ovpn_pid" 2>/dev/null || true
      log "Disconnected"
      return 1
    fi

    if ! kill -0 "$ovpn_pid" 2>/dev/null; then
      printf "\n\n"
      warn "VPN connection was lost."
      return 1
    fi
  done
}

connect_daemon() {
  local entry="$1"
  local hostname country_long base64_data
  hostname=$(echo "$entry" | cut -d'|' -f1)
  country_long=$(echo "$entry" | cut -d'|' -f2)
  base64_data=$(echo "$entry" | cut -d'|' -f5)

  write_config "$base64_data"
  save_host "$hostname" "$country_long"

  log "Starting OpenVPN in daemon mode..."
  sudo openvpn --config "$OVPN_CONFIG" --cd "$DIR" \
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
    log "Connected to ${hostname} (${country_long})"
    check_internet
    printf "\n"
    dim "  Run ${BOLD}privacity status${NC}${DIM} to check the connection${NC}"
    dim "  Run ${BOLD}privacity disconnect${NC}${DIM} to tear it down${NC}"
  else
    warn "Daemon started but no tunnel detected – check $DIR/openvpn.log"
  fi
}

cmd_disconnect() {
  local pid
  pid=$(read_pid)

  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    log "Disconnecting (PID $pid)..."
    sudo kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  else
    log "No saved PID found – looking for active OpenVPN processes..."
    local pids
    pids=$(pgrep -f "openvpn.*$OVPN_CONFIG" 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
      # shellcheck disable=SC2086
      sudo kill $pids 2>/dev/null || true
      # shellcheck disable=SC2086
      wait $pids 2>/dev/null || true
    else
      warn "No active VPN connection found."
      return 1
    fi
  fi

  rm -f "$PID_FILE" "$LAST_HOST"
  log "Disconnected"
}

cmd_status() {
  local hostname country_long
  if [[ -f "$LAST_HOST" ]]; then
    IFS='|' read -r hostname country_long < "$LAST_HOST"
  fi

  printf "\n  ${BOLD}${WHITE}Privacity${NC} ${DIM}status${NC}\n"

  if ip link show tun0 &>/dev/null 2>&1; then
    printf "  ${BOLD}%-14s${NC} ${GREEN}Connected${NC}\n" "Status"
    printf "  ${BOLD}%-14s${NC} %s\n" "Server" "${hostname:---}"
    printf "  ${BOLD}%-14s${NC} %s\n" "Country" "${country_long:---}"

    local ext_ip ping_ms
    ext_ip=$(get_external_ip)
    ping_ms=$(get_ping)
    printf "  ${BOLD}%-14s${NC} %s\n" "External IP" "$ext_ip"
    printf "  ${BOLD}%-14s${NC} %s ms\n" "Ping" "$ping_ms"

    local rx1 rx2 tx1 tx2
    rx1=$(cat /sys/class/net/tun0/statistics/rx_bytes 2>/dev/null || echo 0)
    tx1=$(cat /sys/class/net/tun0/statistics/tx_bytes 2>/dev/null || echo 0)
    sleep 2
    rx2=$(cat /sys/class/net/tun0/statistics/rx_bytes 2>/dev/null || echo 0)
    tx2=$(cat /sys/class/net/tun0/statistics/tx_bytes 2>/dev/null || echo 0)
    local rx_speed=$(( (rx2 - rx1) / 2048 ))
    local tx_speed=$(( (tx2 - tx1) / 2048 ))

    printf "  ${BOLD}%-14s${NC} ↓ %d KB/s  ↑ %d KB/s\n" "Speed" "$rx_speed" "$tx_speed"
  else
    printf "  ${BOLD}%-14s${NC} ${RED}Disconnected${NC}\n" "Status"
  fi

  printf "\n"
}

cmd_reconnect() {
  local mode="${1:-daemon}"
  cmd_disconnect 2>/dev/null || true
  sleep 1
  fetch_servers
  mapfile -t servers < <(parse_servers "$CSV")
  log "Analysing servers by score..."
  ((${#servers[@]})) || die "No servers available."

  local best="${servers[0]}"
  local h c
  h=$(echo "$best" | cut -d'|' -f1)
  c=$(echo "$best" | cut -d'|' -f2)
  local s
  s=$(echo "$best" | cut -d'|' -f4)

  log "Best option found: ${h} (${c}) — score: $(printf "%'d" "$s")"

  if [[ "$mode" == "daemon" ]]; then
    connect_daemon "$best"
  else
    connect_interactive "$best"
  fi
}
