# Ported from Oh My Zsh's node plugin (commit d2b7f55), with its own copy of
# open_command from lib/functions.zsh.

# Opens a file or URL with the system handler: uses open_command when the
# user has one (Oh My Zsh's lib/functions.zsh), otherwise the same logic.
function _node_plugin_open() {
  if (( $+functions[open_command] )); then
    open_command "$@"
    return
  fi

  local open_cmd
  case "$OSTYPE" in
    darwin*)  open_cmd='open' ;;
    cygwin*)  open_cmd='cygstart' ;;
    linux*)   [[ "$(uname -r)" != *icrosoft* ]] && open_cmd='nohup xdg-open' || {
                open_cmd='cmd.exe /c start ""'
                [[ -e "$1" ]] && { 1="$(wslpath -w "${1:a}")" || return 1 }
                [[ "$1" = (http|https)://* ]] && {
                  1="$(echo "$1" | sed -E 's/([&|()<>^])/^\1/g')" || return 1
                }
              } ;;
    msys*)    open_cmd='start ""' ;;
    *)        echo "Platform $OSTYPE not supported"
              return 1
              ;;
  esac

  # If a URL is passed, $BROWSER might be set to a local browser within SSH.
  if [[ -n "$BROWSER" && "$1" = (http|https)://* ]]; then
    "$BROWSER" "$@"
    return
  fi

  ${=open_cmd} "$@" &>/dev/null
}

# Open the node api for your current version to the optional section.
function node-docs {
  local section=${1:-all}
  _node_plugin_open "https://nodejs.org/docs/$(node --version)/api/$section.html"
}
