#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${HOME}/WaxOn"
BIN_DIR="${HOME}/bin"
TARGET="${BIN_DIR}/waxon"

if [ ! -d "$REPO_DIR" ]; then
  echo "Cloning into $REPO_DIR ..."
  git clone https://github.com/sevmorris/WaxOn "$REPO_DIR" || {
    echo "⚠️ Clone failed. If you're installing from a local folder, run ./install.sh from that folder."
    REPO_DIR="$(pwd)"
  }
fi

mkdir -p "$BIN_DIR"
ln -sf "${REPO_DIR}/waxon" "$TARGET"
chmod +x "${REPO_DIR}/waxon"

if ! command -v waxon >/dev/null 2>&1; then
  echo
  echo "Add ~/bin to your PATH, e.g.:"
  echo '  echo '\''export PATH="$HOME/bin:$PATH"'\'' >> ~/.zshrc && source ~/.zshrc'
fi

echo "Installed: $TARGET"
waxon -h || true
