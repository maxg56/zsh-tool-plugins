# Ported from Oh My Zsh's pyenv plugin (commit d2b7f55), with lazy loading
# by default: running `pyenv init -` (and `pyenv virtualenv-init -`) costs
# several processes, so it is deferred until the first call to pyenv,
# python, python3, pip, pip3, a command listed in the `lazy-cmd` zstyle, or
# _pyenv_plugin_load. The shims directory is added to $PATH at start-up
# without running pyenv, so python and the installed tools resolve to the
# selected version right away, scripts included. To run `pyenv init` at
# start-up as Oh My Zsh does, set before the init script:
#
#   zstyle ':omz:plugins:pyenv' lazy no
#
# Extra trigger commands: zstyle ':omz:plugins:pyenv' lazy-cmd ipython poetry
# ZSH_PYENV_QUIET, ZSH_PYENV_VIRTUALENV and the ZSH_THEME_PYENV_* settings
# work as in Oh My Zsh. pyenv_prompt_info never triggers the lazy loading.

# if there is a virtualenv already loaded pyenv should not be loaded
# see https://github.com/ohmyzsh/ohmyzsh/issues/12589
[[ -n ${VIRTUAL_ENV:-} ]] && return

pyenv_config_warning() {
  [[ "$ZSH_PYENV_QUIET" != true ]] || return 0

  local reason="$1"
  local pyenv_root="${PYENV_ROOT/#$HOME/\$HOME}"
  cat >&2 <<EOM
Found pyenv, but it is badly configured ($reason). pyenv might not
work correctly for non-interactive shells (for example, when run from a script).
${(%):-"%B%F{yellow}"}
To fix this message, add these lines to the '.profile' and '.zprofile' files
in your home directory:
${(%):-"%f"}
export PYENV_ROOT="$pyenv_root"
export PATH="\$PYENV_ROOT/bin:\$PATH"
eval "\$(pyenv init --path)"
${(%):-"%F{yellow}"}
You'll need to restart your user session for the changes to take effect.${(%):-%b%f}
For more information go to https://github.com/pyenv/pyenv/#installation.
EOM
}

# Puts the shims first in $PATH: what `pyenv init --path` does, without
# starting pyenv when loading lazily.
_pyenv_plugin_path() {
  if zstyle -T ':omz:plugins:pyenv' lazy; then
    path=("$PYENV_ROOT/shims" ${path:#"$PYENV_ROOT/shims"})
  else
    eval "$(pyenv init --path)"
  fi
}

# This plugin loads pyenv into the current shell and provides prompt info via
# the 'pyenv_prompt_info' function. Also loads pyenv-virtualenv if available.

# Look for pyenv in $PATH and verify that it's not a part of pyenv-win in WSL
if ! command -v pyenv &>/dev/null; then
  FOUND_PYENV=0
elif [[ "${commands[pyenv]}" = */pyenv-win/* && "$(uname -r)" = *icrosoft* ]]; then
  FOUND_PYENV=0
else
  FOUND_PYENV=1
fi

# Look for pyenv and try to load it (will only work on interactive shells)
if [[ $FOUND_PYENV -ne 1 ]]; then
  pyenvdirs=("$HOME/.pyenv" "/usr/local/pyenv" "/opt/pyenv" "/usr/local/opt/pyenv")
  for dir in $pyenvdirs; do
    if [[ -d "$dir/bin" ]]; then
      FOUND_PYENV=1
      break
    fi
  done

  if [[ $FOUND_PYENV -ne 1 ]]; then
    if (( $+commands[brew] )) && dir=$(brew --prefix pyenv 2>/dev/null); then
      if [[ -d "$dir/bin" ]]; then
        FOUND_PYENV=1
      fi
    fi
  fi

  # If we found pyenv, load it but show a caveat about non-interactive shells
  if [[ $FOUND_PYENV -eq 1 ]]; then
    # Configuring in .zshrc only makes pyenv available for interactive shells
    export PYENV_ROOT="$dir"
    export PATH="$PYENV_ROOT/bin:$PATH"
    _pyenv_plugin_path

    # Show warning due to bad pyenv configuration
    pyenv_config_warning 'pyenv command not found in $PATH'
  fi
fi

if [[ $FOUND_PYENV -eq 1 ]]; then
  if [[ -z "$PYENV_ROOT" ]]; then
    # This is only for backwards compatibility with users that previously relied
    # on this plugin exporting it. pyenv itself does not require it to be exported.
    # `pyenv root` prints $PYENV_ROOT, or ~/.pyenv when it is not set.
    export PYENV_ROOT="$HOME/.pyenv"
  fi

  # Add pyenv shims to $PATH if not already added
  if [[ -z "${path[(Re)$PYENV_ROOT/shims]}" ]]; then
    _pyenv_plugin_path
    pyenv_config_warning 'missing pyenv shims in $PATH'
  fi

  # Load pyenv, and pyenv-virtualenv if it exists
  function _pyenv_plugin_setup {
    eval "$(command pyenv init - --no-rehash zsh)"
    if [[ "$ZSH_PYENV_VIRTUALENV" != false && "$(command pyenv commands)" =~ "virtualenv-init" ]]; then
      eval "$(command pyenv virtualenv-init - zsh)"
    fi
    unfunction _pyenv_plugin_setup
  }

  if zstyle -T ':omz:plugins:pyenv' lazy; then
    zstyle -a ':omz:plugins:pyenv' lazy-cmd pyenv_lazy_cmd
    pyenv_lazy_cmd=(_pyenv_plugin_load pyenv python python3 pip pip3 $pyenv_lazy_cmd)
    eval "
      function $pyenv_lazy_cmd {
        local func
        for func in $pyenv_lazy_cmd; do
          if (( \$+functions[\$func] )); then
            unfunction \$func
          fi
        done
        _pyenv_plugin_setup
        if [[ \"\$0\" != _pyenv_plugin_load ]]; then
          \"\$0\" \"\$@\"
        fi
      }
    "
    unset pyenv_lazy_cmd
  else
    _pyenv_plugin_setup
  fi

  function pyenv_prompt_info() {
    local version="$(command pyenv version-name)"
    if [[ "$ZSH_THEME_PYENV_NO_SYSTEM" == "true" ]] && [[ "${version}" == "system" ]]; then
      return
    fi
    echo "${ZSH_THEME_PYENV_PREFIX=}${version:gs/%/%%}${ZSH_THEME_PYENV_SUFFIX=}"
  }
else
  # Fall back to system python
  function pyenv_prompt_info() {
    if [[ "$ZSH_THEME_PYENV_NO_SYSTEM" == "true" ]]; then
      return
    fi
    local version="$(python3 -V 2>&1 | cut -d' ' -f2)"
    echo "${ZSH_THEME_PYENV_PREFIX=}system: ${version:gs/%/%%}${ZSH_THEME_PYENV_SUFFIX=}"
  }
fi

unset FOUND_PYENV pyenvdirs dir
unfunction pyenv_config_warning _pyenv_plugin_path
