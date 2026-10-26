# Ported from Oh My Zsh's colored-man-pages plugin (commit d2b7f55).
# The original reads the colours from the `colors` function loaded by Oh My
# Zsh's lib/; the same escape sequences are written here directly.
# See termcap(5).

# Set up once, and then reuse. This way it supports user overrides after the
# plugin is loaded.
typeset -AHg less_termcap

# bold & blinking mode
less_termcap[mb]=$'\e[01;31m'
less_termcap[md]=$'\e[01;31m'
less_termcap[me]=$'\e[00m'
# standout mode
less_termcap[so]=$'\e[01;33m\e[44m'
less_termcap[se]=$'\e[00m'
# underlining
less_termcap[us]=$'\e[01;32m'
less_termcap[ue]=$'\e[00m'

# Absolute path to this file's directory.
typeset -g __colored_man_pages_dir="${${(%):-%x}:A:h}"

function colored() {
  local -a environment

  # Convert associative array to plain array of NAME=VALUE items.
  local k v
  for k v in "${(@kv)less_termcap}"; do
    environment+=( "LESS_TERMCAP_${k}=${v}" )
  done

  # Prefer `less` whenever available, since we specifically configured
  # environment for it.
  environment+=( PAGER="${commands[less]:-$PAGER}" )
  environment+=( GROFF_NO_SGR=1 )

  # See ./nroff script.
  if [[ "$OSTYPE" = solaris* ]]; then
    environment+=( PATH="${__colored_man_pages_dir}:$PATH" )
  fi

  command env "${environment[@]}" "$@"
}

# Colorize man and dman/debman (from debian-goodies)
function man \
  dman \
  debman {
  colored $0 "$@"
}
