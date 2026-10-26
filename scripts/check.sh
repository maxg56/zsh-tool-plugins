#!/bin/sh
# Loads every plugin of this repository in a clean `zsh -f` through
# `zsh-tool init zsh` and checks its key aliases and functions.
#
# Usage: scripts/check.sh <path to the zsh-tool binary>
#
# A plugin passes when the checks succeed and nothing is written on stderr
# (neither by zsh-tool, e.g. an invalid manifest, nor by the plugin).

set -u

if [ $# -ne 1 ]; then
  echo "usage: $0 <zsh-tool binary>" >&2
  exit 2
fi
case $1 in
  /*) bin=$1 ;;
  *) bin=$PWD/$1 ;;
esac
if [ ! -x "$bin" ]; then
  echo "$0: $bin is not executable" >&2
  exit 2
fi

repo=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Checks run after `eval "$(zsh-tool init zsh)"`; each one prints a message
# on stdout and exits non-zero on failure. $WORK is a scratch directory.
checks_git='
fail() { print -r -- "$@"; exit 1 }
[[ $aliases[gst] == "git status" ]] || fail "alias gst: $aliases[gst]"
[[ $aliases[gca!] == "git commit --verbose --all --amend" ]] || fail "alias gca!"
[[ $aliases[gbgd] == *"awk '"'"'{print \$1}'"'"'"* ]] || fail "alias gbgd: $aliases[gbgd]"
[[ -n $aliases[gfa] && -n $aliases[gpf] && -n $aliases[gpsupf] && -n $aliases[gsta] ]] || fail "version-dependent aliases"
for f in git_current_branch git_main_branch git_develop_branch ggp ggl gccd grename gbda; do
  (( $+functions[$f] )) || fail "function $f"
done
[[ $_comps[ggp] == _git ]] || fail "compdef ggp: $_comps[ggp]"
cd $WORK && git init -q -b trunk repo && cd repo || fail "git init"
git -c user.name=t -c user.email=t@t commit -q --allow-empty -m init || fail "git commit"
[[ $(git_current_branch) == trunk ]] || fail "git_current_branch: $(git_current_branch)"
[[ $(git_main_branch) == trunk ]] || fail "git_main_branch: $(git_main_branch)"
'

checks_sudo='
fail() { print -r -- "$@"; exit 1 }
(( $+functions[sudo-command-line] )) || fail "function sudo-command-line"
[[ -n ${(M)${(f)"$(zle -l)"}:#sudo-command-line} ]] || fail "widget sudo-command-line"
for keymap in emacs viins vicmd; do
  [[ $(bindkey -M $keymap "\e\e") == *sudo-command-line ]] || fail "bindkey $keymap"
done
'

checks_z='
fail() { print -r -- "$@"; exit 1 }
(( $+functions[zshz] )) || fail "function zshz"
[[ $aliases[z] == "zshz 2>&1" ]] || fail "alias z: $aliases[z]"
[[ $_comps[zshz] == _z ]] || fail "completion zshz: $_comps[zshz]"
mkdir -p $WORK/projects/zsh-tool-check
ZSHZ_DATA=$WORK/z-data
zshz --add $WORK/projects/zsh-tool-check
[[ $(zshz -e tool-check) == $WORK/projects/zsh-tool-check ]] || fail "z -e: $(zshz -e tool-check)"
'

checks_extract='
fail() { print -r -- "$@"; exit 1 }
(( $+functions[extract] )) || fail "function extract"
[[ $aliases[x] == extract ]] || fail "alias x: $aliases[x]"
[[ $_comps[extract] == _extract ]] || fail "completion extract: $_comps[extract]"
cd $WORK && mkdir src && print hello > src/a.txt && print world > src/b.txt && tar czf archive.tar.gz -C src a.txt b.txt || fail "tar"
extract archive.tar.gz > /dev/null 2>&1 || fail "extract failed"
[[ $(<archive/a.txt) == hello && $(<archive/b.txt) == world ]] || fail "extracted content"
'

checks_colored_man_pages='
fail() { print -r -- "$@"; exit 1 }
for f in colored man dman debman; do
  (( $+functions[$f] )) || fail "function $f"
done
[[ $(colored printenv LESS_TERMCAP_md) == $'"'"'\e[01;31m'"'"' ]] || fail "LESS_TERMCAP_md"
[[ $(colored printenv GROFF_NO_SGR) == 1 ]] || fail "GROFF_NO_SGR"
'

status=0
for dir in "$repo"/plugins/*/; do
  name=$(basename "$dir")
  var=checks_$(printf %s "$name" | tr -- - _)
  eval "checks=\${$var-}"
  if [ -z "$checks" ]; then
    echo "FAIL $name: no checks defined in $0"
    status=1
    continue
  fi

  home=$work/$name
  mkdir -p "$home/.config/zsh-tool" "$home/work"
  printf 'plugins = ["%s"]\n' "$name" > "$home/.config/zsh-tool/config.toml"
  script="eval \"\$('$bin' init zsh)\" || { print init failed; exit 90 }
WORK='$home/work'
$checks"
  out=$(env -i HOME="$home" PATH="$PATH" TERM=dumb ZSH_TOOL_HOME="$repo" \
    zsh -f -c "$script" 2> "$home/stderr")
  code=$?
  if [ $code -ne 0 ]; then
    echo "FAIL $name: $out"
    status=1
  elif [ -s "$home/stderr" ]; then
    echo "FAIL $name: unexpected stderr:"
    sed 's/^/  /' "$home/stderr"
    status=1
  else
    echo "ok   $name"
  fi
done
exit $status
