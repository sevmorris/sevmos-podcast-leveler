#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/bin"
[ -d "$HOME/.local/bin" ] && TARGET_DIR="$HOME/.local/bin"

mkdir -p "$TARGET_DIR"
if [ -f "$REPO_DIR/waxon" ]; then
  install -m 0755 "$REPO_DIR/waxon" "$TARGET_DIR/waxon"
else
  echo "waxon not found at repo root." >&2
  exit 1
fi

if ! command -v waxon >/dev/null 2>&1; then
  echo "NOTE: Ensure $TARGET_DIR is on your PATH."
  SHELL_RC="$HOME/.zshrc"
  [ -n "${BASH_VERSION:-}" ] && SHELL_RC="$HOME/.bashrc"
  echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_RC"
  echo "Added PATH hint to $SHELL_RC"
fi

echo "Installed to: $TARGET_DIR/waxon"
waxon -h || true
