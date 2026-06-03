#!/usr/bin/env bash
# shellcheck disable=SC2034
[[ -z "${_PRIVACITY_COMMON_LOADED:-}" ]] || return 0
_PRIVACITY_COMMON_LOADED=1

set -euo pipefail

VERSION="$(git describe --always --tags --dirty 2>/dev/null || echo "1.0.0")"
readonly VERSION

PROFILE=""
DIR_BASE="${XDG_DATA_HOME:-$HOME/.local/share}/privacity"
DIR="$DIR_BASE"
CSV="$DIR/servers.csv"
OVPN_CONFIG="$DIR/active.ovpn"
PID_FILE="$DIR/privacity.pid"
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

_ts()    { [[ "$VERBOSE" == "true" ]] && printf "[%s] " "$(date '+%H:%M:%S')" || true; }
log()    { _ts; printf "  ${BOLD}${GREEN}✓${NC} %s\n" "$*"; }
warn()   { _ts; printf "  ${BOLD}${YELLOW}[!]${NC} %s\n" "$*"; }
error()  { _ts; printf "  ${BOLD}${RED}[x]${NC} %s\n" "$*" >&2; }
info()   { _ts; printf "  ${CYAN}%s${NC}\n" "$*"; }
dim()    { printf "${DIM}%s${NC}\n" "$*"; }
die()    { error "$1"; exit 1; }

header() {
  clear
  printf "\n  ${BOLD}${WHITE}Privacity${NC} ${DIM}v${VERSION}${NC} ${WHITE}—${NC} ${DIM}VPN Gate Client${NC}\n\n"
}

run_with_spinner() {
  local msg="$1"
  local func="$2"

  "$func" &
  local pid=$!

  local spin=('-' '\\' '|' '/')
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r  ${spin[$i]} %s" "$msg"
    i=$(( (i + 1) % 4 ))
    sleep 0.1
  done

  wait "$pid"
  local rc=$?

  if [[ $rc -eq 0 ]]; then
    printf "\r  ${GREEN}✓${NC} %s\n" "$msg"
  else
    printf "\r  ${RED}x${NC} %s\n" "$msg"
  fi

  return $rc
}

check_deps() {
  for dep in openvpn wget curl base64; do
    if ! command -v "$dep" &>/dev/null; then
      local pkg
      case "$dep" in
        openvpn) pkg="openvpn" ;;
        wget)    pkg="wget" ;;
        curl)    pkg="curl" ;;
        base64)  pkg="coreutils" ;;
      esac
      warn "$dep is not installed."
      printf "  ${YELLOW}${BOLD}[?]${NC} Install ${pkg}? ${DIM}[Y/n]${NC} "
      read -r yn
      if [[ "${yn,,}" != "n" ]]; then
        log "Installing ${pkg}..."
        sudo apt install -y "$pkg" || die "Failed to install ${pkg}."
      else
        die "$dep is required to run privacity."
      fi
    fi
  done
  if ! command -v sudo &>/dev/null; then
    die "sudo not found. Install it manually."
  fi
}

notify() {
  command -v notify-send &>/dev/null || return 0
  local urgency="${2:-normal}"
  notify-send -a privacity -u "$urgency" "Privacity" "$1" 2>/dev/null || true
}

use_profile() {
  PROFILE="$1"
  DIR="${DIR_BASE}/${PROFILE}"
  CSV="$DIR/servers.csv"
  OVPN_CONFIG="$DIR/active.ovpn"
  PID_FILE="$DIR/privacity.pid"
  LAST_HOST="$DIR/last_host"
  CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/privacity/${PROFILE}.config"
  mkdir -p "$DIR"
}

load_config() {
  [[ -f "$CONFIG_FILE" ]] || return 0
  local key val
  while IFS='=' read -r key val; do
    key="${key// /}"
    [[ -z "$key" || "$key" == \#* ]] && continue
    case "$key" in
      country) CONFIG_COUNTRY="$val" ;;
      mode)    CONFIG_MODE="$val" ;;
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

show_top() {
  local servers=("$@")
  printf "\n"
  for ((i=0; i<3 && i<${#servers[@]}; i++)); do
    local hostname country_long score
    hostname=$(echo "${servers[$i]}" | cut -d'|' -f1)
    country_long=$(echo "${servers[$i]}" | cut -d'|' -f2)
    score=$(echo "${servers[$i]}" | cut -d'|' -f4)

    local marker
    ((i==0)) && marker="${GREEN}${BOLD}✓${NC} " || marker="  "

    printf "  ${marker}%-20s  %-30s  ${YELLOW}%'10d${NC}\n" \
      "$country_long" "$hostname" "$score"
  done
  printf "\n"
}
