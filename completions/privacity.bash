# Bash completion for privacity
# Source this file in ~/.bashrc or put it in /etc/bash_completion.d/
#
#   source /usr/share/bash-completion/completions/privacity.bash

_privacity() {
  local cur prev words cword
  _init_completion || return

  local subcommands="daemon list disconnect reconnect status speedtest update help"
  local opts="-c --country"
 
  if [[ $cword -eq 1 ]]; then
    COMPREPLY=($(compgen -W "$subcommands $opts" -- "$cur"))
    return
  fi
 
  case "${words[1]}" in
    daemon)
      COMPREPLY=($(compgen -W "--persist --unpersist" -- "$cur"))
      ;;
    help|--help|-h)
      COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
      ;;
  esac
}

complete -F _privacity privacity
