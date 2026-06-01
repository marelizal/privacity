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
    "disconnect:Tear down the current VPN"
    "reconnect:Pick a new server and reconnect"
    "status:Show connection info and live speed"
    "help:Show help"
  )

  _arguments \
    '1: :->command' \
    '*:: :->args'

  case "$state" in
    command)
      _describe -t commands 'privacity subcommands' subcommands
      ;;
    args)
      case "$line[1]" in
        help)
          _describe -t commands 'privacity subcommands' subcommands
          ;;
      esac
      ;;
  esac
}

_privacity "$@"
