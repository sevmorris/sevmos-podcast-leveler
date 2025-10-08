#!/bin/sh
# WaxOn installer — symlink-first, ffmpeg-ready, Homebrew-aware
# Usage:
#   ./install.sh                # symlink (default)
#   ./install.sh --copy         # copy instead of symlink
#   ./install.sh --force        # overwrite existing binary
#   ./install.sh --prefix /bin  # install destination dir
#   ./install.sh --yes          # non-interactive; auto-install Homebrew + ffmpeg if needed
#   ./install.sh --no-brew      # skip Homebrew checks/installs (advanced)

set -eu

MODE="link"        # link|copy
FORCE=0
YES=0
NO_BREW=0
CUSTOM_PREFIX=""

while [ "${1:-}" ]; do
  case "$1" in
    --copy) MODE="copy"; shift ;;
    --force) FORCE=1; shift ;;
    --prefix) CUSTOM_PREFIX="${2:?}"; shift 2 ;;
    --yes) YES=1; shift ;;
    --no-brew) NO_BREW=1; shift ;;
    -h|--help)
      cat <<EOF
WaxOn installer

Options:
  --copy              Copy instead of symlink
  --force             Overwrite existing destination
  --prefix DIR        Install into DIR (default: Homebrew bin or /usr/local/bin or /opt/homebrew/bin or ~/.local/bin)
  --yes               Non-interactive; auto-install Homebrew (if missing) and ffmpeg
  --no-brew           Skip Homebrew detection/installation (advanced)
EOF
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd -- "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/waxon.sh"
[ -f "$SRC" ] || { echo "waxon.sh not found at repo root." >&2; exit 1; }
[ -x "$SRC" ] || chmod +x "$SRC"

is_macos() { [ "$(uname -s)" = "Darwin" ]; }
has_cmd() { command -v "$1" >/dev/null 2>&1; }

resolve_bin_prefix() {
  if [ -n "$CUSTOM_PREFIX" ]; then
    printf "%s" "$CUSTOM_PREFIX"; return
  fi
  if has_cmd brew; then
    brew --prefix | awk '{print $0"/bin"}'; return
  fi
  # Prefer /usr/local/bin on Intel macs; /opt/homebrew/bin on Apple Silicon
  if [ -d "/usr/local/bin" ]; then printf "%s" "/usr/local/bin"; return; fi
  if [ -d "/opt/homebrew/bin" ]; then printf "%s" "/opt/homebrew/bin"; return; fi
  mkdir -p "$HOME/.local/bin"
  printf "%s" "$HOME/.local/bin"
}

maybe_install_homebrew() {
  [ "$NO_BREW" -eq 1 ] && return 0
  is_macos || { echo "Homebrew bootstrap is macOS-only. Install ffmpeg manually."; return 0; }
  if has_cmd brew; then
    return 0
  fi
  if [ "$YES" -eq 1 ]; then
    echo "Homebrew not found — installing non-interactively…"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for current shell
    if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
    if [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
    return 0
  fi
  echo "Homebrew not found."
  printf "Install Homebrew now? [Y/n] "
  read -r ans || ans=""
  case "$ans" in n|N) echo "Skipping Homebrew install."; return 0;; esac
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
  if [ -x /usr/local/bin/brew ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
}

ensure_ffmpeg() {
  [ "$NO_BREW" -eq 1 ] && return 0
  if has_cmd ffmpeg && has_cmd ffprobe; then
    return 0
  fi
  if has_cmd brew; then
    echo "Installing ffmpeg via Homebrew…"
    brew update >/dev/null 2>&1 || true
    brew install ffmpeg || brew upgrade ffmpeg || true
    return 0
  fi
  echo "ffmpeg/ffprobe not found and Homebrew unavailable."
  echo "Please install ffmpeg manually and re-run install.sh"
  return 0
}

install_link() {
  DEST="$1"; SRC="$2"; FORCE="$3"
  if [ -e "$DEST" ] && [ "$FORCE" -ne 1 ]; then
    echo "Refusing to overwrite existing $DEST (use --force)"; exit 1
  fi
  rm -f "$DEST" 2>/dev/null || true
  ln -s "$SRC" "$DEST" 2>/dev/null || { echo "Symlink requires elevated privileges…"; sudo ln -sf "$SRC" "$DEST"; }
}

install_copy() {
  DEST="$1"; SRC="$2"; FORCE="$3"
  if [ -e "$DEST" ] && [ "$FORCE" -ne 1 ]; then
    echo "Refusing to overwrite existing $DEST (use --force)"; exit 1
  fi
  cp "$SRC" "$DEST" 2>/dev/null || { echo "Copy requires elevated privileges…"; sudo cp "$SRC" "$DEST"; }
  chmod +x "$DEST" 2>/dev/null || sudo chmod +x "$DEST"
}

# Bootstrap tools if desired
maybe_install_homebrew
ensure_ffmpeg

BIN_PREFIX="$(resolve_bin_prefix)"
DEST="$BIN_PREFIX/waxon"
echo "Installing to: $DEST"
mkdir -p "$BIN_PREFIX" 2>/dev/null || { echo "Creating $BIN_PREFIX requires sudo…"; sudo mkdir -p "$BIN_PREFIX"; }

if [ "$MODE" = "copy" ]; then
  install_copy "$DEST" "$SRC" "$FORCE"
  echo "Installed (copy): $DEST"
else
  install_link "$DEST" "$SRC" "$FORCE"
  echo "Installed (symlink): $DEST -> $SRC"
fi

# Ensure log dir exists for first run
mkdir -p "$HOME/Library/Logs" 2>/dev/null || true

echo
echo "Done. Try: waxon -h"
