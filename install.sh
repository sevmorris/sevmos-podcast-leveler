#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/sevmorris/WaxOn.git"
DEST="${HOME}/WaxOn"
BIN_DIR="${HOME}/bin"
ALT_BIN="${HOME}/.local/bin"
LINK_NAME="waxon"

echo "==> Installing WaxOn to ${DEST} and symlinking ${LINK_NAME}..."

command -v git >/dev/null 2>&1 || { echo "Error: git is required."; exit 1; }

if [[ -d "${DEST}/.git" ]]; then
  echo "==> Updating existing repo..."
  git -C "${DEST}" pull --ff-only
else
  echo "==> Cloning repo..."
  git clone --depth=1 "${REPO_URL}" "${DEST}"
fi

if [[ ! -f "${DEST}/${LINK_NAME}" ]]; then
  echo "Error: ${LINK_NAME} not found at ${DEST}/${LINK_NAME}"
  exit 1
fi

chmod +x "${DEST}/${LINK_NAME}"

# Prefer ~/.local/bin if it exists; otherwise use ~/bin
if [[ -d "${ALT_BIN}" ]]; then
  INSTALL_BIN="${ALT_BIN}"
else
  INSTALL_BIN="${BIN_DIR}"
fi
mkdir -p "${INSTALL_BIN}"

ln -sf "${DEST}/${LINK_NAME}" "${INSTALL_BIN}/${LINK_NAME}"
echo "==> Symlinked ${INSTALL_BIN}/${LINK_NAME}"

# Helpful hints
if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Note: ffmpeg not found. Install it (e.g., 'brew install ffmpeg' on macOS)."
fi

if ! command -v "${LINK_NAME}" >/dev/null 2>&1; then
  echo "Add to PATH: export PATH=\"${INSTALL_BIN}:$PATH\""
fi

# Friendly probe (non-fatal)
"${INSTALL_BIN}/${LINK_NAME}" --version >/dev/null 2>&1 || true
echo "==> Done."
