# Ported from Oh My Zsh's copypath plugin (commit d2b7f55), with its own
# clipboard detection taken from lib/clipboard.zsh.

# Copies stdin to the clipboard: uses clipcopy when the user has one,
# otherwise the first clipboard tool available.
function _copypath_plugin_clipcopy() {
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
    print -u2 "copypath: no clipboard tool found"
    return 1
  fi
}

# Copies the path of given directory or file to the system or X Windows clipboard.
# Copy current directory if no parameter.
function copypath {
  # If no argument passed, use current directory
  local file="${1:-.}"

  # If argument is not an absolute path, prepend $PWD
  [[ $file = /* ]] || file="$PWD/$file"

  # Copy the absolute path without resolving symlinks
  # If clipcopy fails, exit the function with an error
  print -n "${file:a}" | _copypath_plugin_clipcopy || return 1

  echo ${(%):-"%B${file:a}%b copied to clipboard."}
}
