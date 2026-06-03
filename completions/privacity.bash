# Bash completion for privacity
# Source this file in ~/.bashrc or put it in /etc/bash_completion.d/
#
#   source /usr/share/bash-completion/completions/privacity.bash

_privacity() {
  local cur prev words cword
  _init_completion || return

  local subcommands="daemon disconnect reconnect status speedtest update help"

  if [[ $cword -eq 1 ]]; then
    COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
    return
  fi

  case "${words[1]}" in
    help|--help|-h)
      COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
      ;;
  esac
}

complete -F _privacity privacity
