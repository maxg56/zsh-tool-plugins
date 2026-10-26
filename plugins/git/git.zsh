# Functions of the git plugin, ported from Oh My Zsh (commit d2b7f55).
# Unlike the original, this file does not depend on Oh My Zsh's lib/: the
# helpers it needs (git_current_branch, clipboard copy) are defined here.

autoload -Uz is-at-least

#
# Helpers (from lib/git.zsh and lib/clipboard.zsh)
#

# Outputs the current branch name, or the short hash on a detached HEAD.
# Usage example: git pull origin $(git_current_branch)
function git_current_branch() {
  local ref
  ref=$(GIT_OPTIONAL_LOCKS=0 command git symbolic-ref --quiet HEAD 2> /dev/null)
  local ret=$?
  if [[ $ret != 0 ]]; then
    [[ $ret == 128 ]] && return  # no git repo.
    ref=$(GIT_OPTIONAL_LOCKS=0 command git rev-parse --short HEAD 2> /dev/null) || return
  fi
  echo ${ref#refs/heads/}
}

# Copies stdin to the clipboard: uses clipcopy when the user has one,
# otherwise the first clipboard tool available.
function _git_plugin_clipcopy() {
  if (( $+functions[clipcopy] )); then
    clipcopy
  elif [[ "${OSTYPE}" == darwin* ]] && (( $+commands[pbcopy] )); then
    pbcopy
  elif [[ "${OSTYPE}" == (cygwin|msys)* ]]; then
    cat > /dev/clipboard
  elif (( $+commands[clip.exe] )); then
    clip.exe
  elif [[ -n "${WAYLAND_DISPLAY:-}" ]] && (( $+commands[wl-copy] )); then
    wl-copy &>/dev/null
  elif [[ -n "${DISPLAY:-}" ]] && (( $+commands[xsel] )); then
    xsel --clipboard --input
  elif [[ -n "${DISPLAY:-}" ]] && (( $+commands[xclip] )); then
    xclip -selection clipboard -in &>/dev/null
  elif [[ $OSTYPE == linux-android* ]] && (( $+commands[termux-clipboard-set] )); then
    termux-clipboard-set
  elif [[ -n "${TMUX:-}" ]] && (( $+commands[tmux] )); then
    tmux load-buffer -
  else
    print -u2 "gbcopy: no clipboard tool found"
    return 1
  fi
}

#
# Functions Current
#

# Check for develop and similarly named branches
function git_develop_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in dev devel develop development; do
    if command git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return 0
    fi
  done

  echo develop
  return 1
}

# Get the default branch name from common branch names or fallback to remote HEAD
function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return

  local remote ref

  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return 0
    fi
  done

  # Fallback: try to get the default branch from remote HEAD symbolic refs
  for remote in origin upstream; do
    ref=$(command git rev-parse --abbrev-ref $remote/HEAD 2>/dev/null)
    if [[ $ref == $remote/* ]]; then
      echo ${ref#"$remote/"}; return 0
    fi
  done

  # If no main branch was found, fall back to master but return error
  echo master
  return 1
}

function gbcopy() {
  command git rev-parse --git-dir &>/dev/null || return

  local branch
  branch="$(git_current_branch)" || return
  [[ -n "$branch" ]] || return 1

  print -rn -- "$branch" | _git_plugin_clipcopy
}

function grename() {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: $0 old_branch new_branch"
    return 1
  fi

  # Rename branch locally
  git branch -m "$1" "$2"
  # Rename branch in origin remote
  if git push origin :"$1"; then
    git push --set-upstream origin "$2"
  fi
}

#
# Functions Work in Progress (WIP)
#

# Similar to `gunwip` but recursive "Unwips" all recent `--wip--` commits not just the last one
function gunwipall() {
  local _commit=$(git log --grep='--wip--' --invert-grep --max-count=1 --format=format:%H)

  # Check if a commit without "--wip--" was found and it's not the same as HEAD
  if [[ "$_commit" != "$(git rev-parse HEAD)" ]]; then
    git reset $_commit || return 1
  fi
}

# Warn if the current branch is a WIP
function work_in_progress() {
  command git -c log.showSignature=false log -n 1 2>/dev/null | grep -q -- "--wip--" && echo "WIP!!"
}

#
# Functions used by aliases
#

function ggpnp() {
  if [[ $# == 0 ]]; then
    ggl && ggp
  else
    ggl "${*}" && ggp "${*}"
  fi
}
compdef _git ggpnp=git-checkout

function gbda() {
  git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch --delete 2>/dev/null
}

# Copied and modified from James Roeder (jmaroeder) under MIT License
# https://github.com/jmaroeder/plugin-git/blob/216723ef4f9e8dde399661c39c80bdf73f4076c4/functions/gbda.fish
function gbds() {
  local default_branch
  default_branch=$(git_main_branch) \
    || default_branch=$(git_develop_branch)

  git for-each-ref refs/heads/ "--format=%(refname:short)" | \
    while read branch; do
      local merge_base=$(git merge-base $default_branch $branch)
      if [[ $(git cherry $default_branch $(git commit-tree $(git rev-parse $branch\^{tree}) -p $merge_base -m _)) = -* ]]; then
        git branch -D $branch
      fi
    done
}

function gccd() {
  setopt localoptions extendedglob

  # get repo URI from args based on valid formats: https://git-scm.com/docs/git-clone#URLS
  local repo="${${@[(r)(ssh://*|git://*|ftp(s)#://*|http(s)#://*|*@*)(.git/#)#]}:-$_}"

  # clone repository and exit if it fails
  command git clone --recurse-submodules "$@" || return

  # if last arg passed was a directory, that's where the repo was cloned
  # otherwise parse the repo URI and use the last part as the directory
  [[ -d "$_" ]] && cd "$_" || cd "${${repo:t}%.git/#}"
}
compdef _git gccd=git-clone

function gdv() { git diff -w "$@" | view - }
compdef _git gdv=git-diff

function gdnolock() {
  git diff "$@" ":(exclude)package-lock.json" ":(exclude)*.lock"
}
compdef _git gdnolock=git-diff

# Pretty log messages
function _git_log_prettily(){
  if ! [ -z $1 ]; then
    git log --pretty=$1
  fi
}
compdef _git _git_log_prettily=git-log

function ggu() {
  local b
  [[ $# != 1 ]] && b="$(git_current_branch)"
  git pull --rebase origin "${b:-$1}"
}
compdef _git ggu=git-pull

function ggl() {
  if [[ $# != 0 ]] && [[ $# != 1 ]]; then
    git pull origin "${*}"
  else
    local b
    [[ $# == 0 ]] && b="$(git_current_branch)"
    git pull origin "${b:-$1}"
  fi
}
compdef _git ggl=git-pull

function ggf() {
  local b
  [[ $# != 1 ]] && b="$(git_current_branch)"
  git push --force origin "${b:-$1}"
}
compdef _git ggf=git-push

function ggfl() {
  local b
  [[ $# != 1 ]] && b="$(git_current_branch)"
  git push --force-with-lease origin "${b:-$1}"
}
compdef _git ggfl=git-push

function ggp() {
  if [[ $# != 0 ]] && [[ $# != 1 ]]; then
    git push origin "${*}"
  else
    local b
    [[ $# == 0 ]] && b="$(git_current_branch)"
    git push origin "${b:-$1}"
  fi
}
compdef _git ggp=git-push

#
# Aliases that depend on the git version
#

() {
  local git_version="${${(As: :)$(git version 2>/dev/null)}[3]}"

  # --jobs=<n> was added in git 2.8
  is-at-least 2.8 "$git_version" \
    && alias gfa='git fetch --all --tags --prune --jobs=10' \
    || alias gfa='git fetch --all --tags --prune'
  is-at-least 2.30 "$git_version" \
    && alias gpf='git push --force-with-lease --force-if-includes' \
    || alias gpf='git push --force-with-lease'
  is-at-least 2.30 "$git_version" \
    && alias gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease --force-if-includes' \
    || alias gpsupf='git push --set-upstream origin $(git_current_branch) --force-with-lease'
  # use the default stash push on git 2.13 and newer
  is-at-least 2.13 "$git_version" \
    && alias gsta='git stash push' \
    || alias gsta='git stash save'
}
