#!/bin/sh
# Remove the global 'waxon' command.

set -eu

has_cmd() { command -v "$1" >/dev/null 2>&1; }

resolve_bin_prefix() {
  if has_cmd brew; then brew --prefix | awk '{print $0"/bin"}'; return; fi
  if [ -d "/usr/local/bin" ]; then printf "%s" "/usr/local/bin"; return; fi
  if [ -d "/opt/homebrew/bin" ]; then printf "%s" "/opt/homebrew/bin"; return; fi
  printf "%s" "$HOME/.local/bin"
}

BIN_PREFIX="$(resolve_bin_prefix)"
DEST="$BIN_PREFIX/waxon"

if [ -e "$DEST" ] || [ -L "$DEST" ]; then
  rm -f "$DEST" 2>/dev/null || sudo rm -f "$DEST"
  echo "Removed: $DEST"
else
  echo "No waxon found at: $DEST"
fi
