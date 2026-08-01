#compdef privacity

# Zsh completion for privacity
# Source this file or put it in a directory listed in $fpath:
#
#   mkdir -p ~/.zsh/completions
#   cp privacity.zsh ~/.zsh/completions/_privacity
#   fpath=(~/.zsh/completions $fpath)
#   compinit

_privacity() {
  local context state state_descr line
  typeset -A opt_args

  local subcommands=(
    "daemon:Connect in background (no terminal)"
    "list:Show top servers and available countries"
    "disconnect:Tear down the current VPN"
    "reconnect:Pick a new server and reconnect"
    "status:Show connection info and live speed"
    "speedtest:Measure download and upload speed"
    "update:Pull latest version and reinstall"
    "help:Show help"
  )

  local opts=(
    {-c,--country}'[Filter servers by country]:country:''
    '--server=[Connect to a specific server from the list]:host:'
    '--fast[Sort servers by lowest ping]'
    '--protocol=[Force protocol: ovpn, wg, auto]:protocol:(ovpn wg auto)'
    '--log-file=[Write output to log file]:file:_files'
    '--verbose[Show timestamps and detailed output]'
  )

  _arguments \
    "${opts[@]}" \
    '1: :->command' \
    '*:: :->args'

  case "$state" in
    command)
      _describe -t commands 'privacity subcommands' subcommands
      ;;
    args)
      case "$line[1]" in
        daemon)
          _arguments '--persist[Install systemd user service]' '--unpersist[Remove systemd user service]'
          ;;
        help|list)
          _describe -t commands 'privacity subcommands' subcommands
          ;;
      esac
      ;;
  esac
}

_privacity "$@"
