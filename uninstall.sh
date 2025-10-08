#!/bin/sh
# Remove the global waxon command.

set -eu

resolve_bin_prefix() {
  if command -v brew >/dev/null 2>&1; then
    brew --prefix | awk '{print $0"/bin"}'
    return
  fi
  if [ -d "/usr/local/bin" ]; then
    printf "%s" "/usr/local/bin"
  elif [ -d "/opt/homebrew/bin" ]; then
    printf "%s" "/opt/homebrew/bin"
  else
    printf "%s" "$HOME/.local/bin"
  fi
}

BIN_PREFIX="$(resolve_bin_prefix)"
DEST="$BIN_PREFIX/waxon"

if [ -e "$DEST" ] || [ -L "$DEST" ]; then
  rm -f "$DEST" 2>/dev/null || sudo rm -f "$DEST"
  echo "Removed: $DEST"
else
  echo "No waxon found at: $DEST"
fi
