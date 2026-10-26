# Ported from Oh My Zsh's docker plugin (commit d2b7f55). The aliases are in
# plugin.toml; this fragment installs the completion function.
#
# Oh My Zsh runs compinit before its plugins, zsh-tool after them: the
# completion is therefore always registered with autoload + compdef (the
# compdef call is replayed after compinit) instead of only when the cached
# completion file does not exist yet.

(( $+commands[docker] )) || return

[[ -d "$ZSH_CACHE_DIR/completions" ]] || mkdir -p "$ZSH_CACHE_DIR/completions"

autoload -Uz _docker is-at-least
compdef _docker docker

zmodload -F zsh/files b:zf_mv
() {
  local plugin_dir="$1"

  # `docker completion` is only available from 23.0.0 on
  # docker version returns `Docker version 24.0.2, build cb74dfcd85`
  # with `s:,:` remove the comma after the version, and select third word of it
  if zstyle -t ':omz:plugins:docker' legacy-completion || \
    ! is-at-least 23.0.0 ${${(s:,:z)"$(command docker --version)"}[3]}; then
    command cp "${plugin_dir}/legacy/_docker" "$ZSH_CACHE_DIR/completions/_docker"
  else
    local TMPPREFIX="$ZSH_CACHE_DIR/completions/._docker"
    zf_mv -f -- =( command docker completion zsh ) "$ZSH_CACHE_DIR/completions/_docker"
  fi
} "${${(%):-%N}:A:h}" &|
