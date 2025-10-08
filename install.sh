#!/usr/bin/env bash
# WaxOn Installer — smart hybrid for both devs and end-users

set -euo pipefail

REPO_URL="https://github.com/sevmorris/WaxOn.git"
RAW_SCRIPT_URL="https://raw.githubusercontent.com/sevmorris/WaxOn/main/waxon.sh"
INSTALL_DIR="/usr/local/bin"
CLONE_DIR="${HOME}/.local/share/waxon"
SCRIPT_NAME="waxon"
SCRIPT_FILE="waxon.sh"

# Detect Apple Silicon Homebrew path
if [[ -d "/opt/homebrew/bin" && ! -w "$INSTALL_DIR" ]]; then
  INSTALL_DIR="/opt/homebrew/bin"
fi

echo "→ Installing WaxOn CLI into ${INSTALL_DIR}"

# Ensure Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "→ Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure FFmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "→ Installing FFmpeg..."
  brew install ffmpeg
fi

MODE="user"
[[ "${1:-}" == "--dev" ]] && MODE="dev"

if [[ "$MODE" == "dev" ]]; then
  echo "→ Developer mode: cloning repo to ${CLONE_DIR}"
  if [[ -d "${CLONE_DIR}/.git" ]]; then
    git -C "${CLONE_DIR}" pull --quiet
  else
    git clone --depth=1 "${REPO_URL}" "${CLONE_DIR}"
  fi
  chmod +x "${CLONE_DIR}/${SCRIPT_FILE}"
  sudo ln -sf "${CLONE_DIR}/${SCRIPT_FILE}" "${INSTALL_DIR}/${SCRIPT_NAME}"
else
  echo "→ User mode: downloading latest script"
  TMP="$(mktemp)"
  curl -fsSL -o "$TMP" "$RAW_SCRIPT_URL"
  chmod +x "$TMP"
  sudo mv "$TMP" "${INSTALL_DIR}/${SCRIPT_NAME}"
fi

echo "✅ Installed successfully to ${INSTALL_DIR}/${SCRIPT_NAME}"

if command -v waxon >/dev/null 2>&1; then
  echo
  waxon --version || echo "WaxOn installed successfully."
fi

echo
echo "🎧 Run WaxOn with:"
echo "  waxon input.wav"
[[ "$MODE" == "dev" ]] && echo "💡 To update: cd ${CLONE_DIR} && git pull"
