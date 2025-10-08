#!/bin/sh
# Install WaxOn CLI into your PATH, defaulting to a symlink so you can maintain it in-repo.
# Usage:
#   ./install.sh            # symlink (default)
#   ./install.sh --copy     # copy instead of symlink
#   ./install.sh --force    # overwrite existing
#   ./install.sh --prefix /custom/bin

set -eu

MODE="link"        # or "copy"
FORCE=0
CUSTOM_PREFIX=""

while [ "${1:-}" ]; do
  case "$1" in
    --copy) MODE="copy"; shift ;;
    --force) FORCE=1; shift ;;
    --prefix) CUSTOM_PREFIX="${2:?}"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--copy] [--force] [--prefix /path/to/bin]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd -- "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/waxon.sh"
[ -f "$SRC" ] || { echo "waxon.sh not found in repo root." >&2; exit 1; }
[ -x "$SRC" ] || chmod +x "$SRC"

resolve_bin_prefix() {
  if [ -n "$CUSTOM_PREFIX" ]; then
    printf "%s" "$CUSTOM_PREFIX"
    return
  fi
  if command -v brew >/dev/null 2>&1; then
    # Respect Homebrew’s prefix if available (works for both /opt/homebrew and /usr/local)
    brew --prefix | awk '{print $0"/bin"}'
    return
  fi
  # Fallbacks
  if [ -d "/usr/local/bin" ]; then
    printf "%s" "/usr/local/bin"
  elif [ -d "/opt/homebrew/bin" ]; then
    printf "%s" "/opt/homebrew/bin"
  else
    # As a last resort, create a local bin
    mkdir -p "$HOME/.local/bin"
    printf "%s" "$HOME/.local/bin"
  fi
}

BIN_PREFIX="$(resolve_bin_prefix)"
DEST="$BIN_PREFIX/waxon"

echo "Installing to: $DEST"
mkdir -p "$BIN_PREFIX"

install_link() {
  # If destination exists and isn't a symlink to SRC, optionally force
  if [ -e "$DEST" ] && [ "$FORCE" -ne 1 ]; then
    echo "Refusing to overwrite existing $DEST (use --force)"
    exit 1
  fi
  rm -f "$DEST"
  ln -s "$SRC" "$DEST" || {
    echo "Symlink failed; trying with sudo…"
    sudo ln -sf "$SRC" "$DEST"
  }
}

install_copy() {
  if [ -e "$DEST" ] && [ "$FORCE" -ne 1 ]; then
    echo "Refusing to overwrite existing $DEST (use --force)"
    exit 1
  fi
  cp "$SRC" "$DEST" 2>/dev/null || {
    echo "Copy failed; trying with sudo…"
    sudo cp "$SRC" "$DEST"
  }
  chmod +x "$DEST" 2>/dev/null || sudo chmod +x "$DEST"
}

if [ "$MODE" = "copy" ]; then
  install_copy
  echo "Installed (copy): $DEST"
else
  install_link
  echo "Installed (symlink): $DEST -> $SRC"
fi

# Create log dir so first run never errors on logging
mkdir -p "$HOME/Library/Logs" || true

echo
echo "Done. Try: waxon -h"
