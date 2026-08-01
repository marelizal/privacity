#!/usr/bin/env bash
# shellcheck disable=SC2034
[[ -z "${_PRIVACITY_COMMON_LOADED:-}" ]] || return 0
_PRIVACITY_COMMON_LOADED=1

set -euo pipefail

VERSION="$(git describe --always --tags --dirty 2>/dev/null || echo "1.2.0")"
VERSION="${VERSION#v}"
readonly VERSION

PROFILE=""
DIR_BASE="${XDG_DATA_HOME:-$HOME/.local/share}/privacity"
DIR="$DIR_BASE"
CSV="$DIR/servers.csv"
OVPN_CONFIG="$DIR/active.ovpn"
PID_FILE="$DIR/privacity.pid"
WG_INTERFACE="wg-privacity"
WG_CONF="$DIR/wireguard.conf"
LAST_HOST="$DIR/last_host"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/privacity/config"
LOG_FILE=""
VERBOSE=false

if stat -c %Y /dev/null &>/dev/null; then
  _stat_mtime() { stat -c %Y "$1" 2>/dev/null || echo 0; }
else
  _stat_mtime() { stat -f %m "$1" 2>/dev/null || echo 0; }
fi

if [[ -t 1 ]]; then
  BOLD=$(tput bold)
  DIM=$(tput dim)
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  CYAN=$(tput setaf 6)
  WHITE=$(tput setaf 7)
  NC=$(tput sgr0)
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""
  CYAN=""; WHITE=""; NC=""
fi

_ts()    { [[ "$VERBOSE" == "true" ]] && printf "[%s] " "$(date '+%H:%M:%S')" >&2 || true; }
log()    { _ts; printf "  %s%s✓%s %s\n" "${BOLD}" "${GREEN}" "${NC}" "$*" >&2; }
warn()   { _ts; printf "  %s%s[!]%s %s\n" "${BOLD}" "${YELLOW}" "${NC}" "$*" >&2; }
error()  { _ts; printf "  %s%s[x]%s %s\n" "${BOLD}" "${RED}" "${NC}" "$*" >&2; }
info()   { _ts; printf "  %s%s%s\n" "${CYAN}" "$*" "${NC}" >&2; }
dim()    { printf "%s%s%s\n" "${DIM}" "$*" "${NC}" >&2; }
die()    { error "$1"; exit 1; }

run_with_spinner() {
  local msg="$1"
  local func="$2"
  local hard_timeout="${3:-30}"

  "$func" &
  local pid=$!
  local start=$SECONDS

  local spin=('-' "\\" '|' '/')
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    if (( SECONDS - start > hard_timeout )); then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      printf "\r  %sx%s %s\n" "${RED}" "${NC}" "$msg" >&2
      return 1
    fi
    printf "\r  %s%s%s %s" "${YELLOW}" "${spin[$i]}" "${NC}" "$msg" >&2
    i=$(( (i + 1) % 4 ))
    sleep 0.25
  done

  wait "$pid"
  local rc=$?

  if [[ $rc -eq 0 ]]; then
    printf "\r  %s✓%s %s\n" "${GREEN}" "${NC}" "$msg" >&2
  else
    printf "\r  %sx%s %s\n" "${RED}" "${NC}" "$msg" >&2
  fi

  return $rc
}

_sudo() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  elif sudo -n true 2>/dev/null; then
    sudo -n "$@"
  else
    sudo "$@"
  fi
}

check_deps() {
  local -a missing=() pkgs=()
  local dep pkg
  for dep in openvpn wget curl wg-quick; do
    if ! command -v "$dep" &>/dev/null; then
      missing+=("$dep")
      case "$dep" in
        openvpn)   pkgs+=(openvpn) ;;
        wget)      pkgs+=(wget) ;;
        curl)      pkgs+=(curl) ;;
        wg-quick)  pkgs+=(wireguard-tools) ;;
      esac
    fi
  done
  ((${#missing[@]})) || return 0

  log "Installing missing deps: ${pkgs[*]}"
  if _sudo apt-get install -y "${pkgs[@]}" >/dev/null 2>&1; then
    log "Installed: ${pkgs[*]}"
  else
    die "Missing deps: ${missing[*]}. Run: sudo apt-get install -y ${pkgs[*]}"
  fi
}

notify() {
  command -v notify-send &>/dev/null || return 0
  local urgency="${2:-normal}"
  notify-send -a privacity -u "$urgency" "Privacity" "$1" 2>/dev/null || true
}

load_config() {
  [[ -f "$CONFIG_FILE" ]] || return 0
  local key val
  while IFS='=' read -r key val; do
    key="${key// /}"
    [[ -z "$key" || "$key" == \#* ]] && continue
    case "$key" in
      country)  CONFIG_COUNTRY="$val" ;;
      mode)     CONFIG_MODE="$val" ;;
      fast)     CONFIG_FAST="$val" ;;
      protocol) CONFIG_PROTOCOL="$val" ;;
    esac
  done < "$CONFIG_FILE"
}

# ──────── Systemd user service ──────────────────────────────────────────────

SERVICE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
SERVICE_NAME="privacity.service"

_create_user_service() {
  local exec_path
  exec_path="$(command -v privacity 2>/dev/null || echo "/usr/local/bin/privacity")"
  install -d "$SERVICE_DIR"
  cat > "$SERVICE_DIR/$SERVICE_NAME" <<-EOF
[Unit]
Description=Privacity VPN Gate auto-connector
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=$exec_path daemon
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF
  systemctl --user daemon-reload
}

_remove_user_service() {
  rm -f "$SERVICE_DIR/$SERVICE_NAME"
  systemctl --user daemon-reload
}

cmd_persist() {
  _create_user_service
  systemctl --user enable --now "$SERVICE_NAME"
  log "Systemd user service installed and started."
  info "  ~/.config/systemd/user/$SERVICE_NAME"
  info "  Run 'privacity daemon --unpersist' to remove."
}

cmd_unpersist() {
  systemctl --user disable --now "$SERVICE_NAME" 2>/dev/null || true
  _remove_user_service
  log "Systemd user service stopped and removed."
}


