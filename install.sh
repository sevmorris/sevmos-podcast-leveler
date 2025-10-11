#!/usr/bin/env bash
# WaxOn installer (stdin-safe)
set -Eeuo pipefail

REPO_URL="https://github.com/sevmorris/WaxOn.git"
DEST="${HOME}/WaxOn"
BIN_DIR="${HOME}/bin"
ALT_BIN="${HOME}/.local/bin"
LINK_NAME="waxon"

echo "==> Installing WaxOn to ${DEST} and symlinking ${LINK_NAME}..."

# Ensure git and ffmpeg are present (soft check)
command -v git >/dev/null 2>&1 || { echo "Error: git is required."; exit 1; }

# Clone or update
if [[ -d "${DEST}/.git" ]]; then
  echo "==> Updating existing repo..."
  git -C "${DEST}" pull --ff-only
else
  echo "==> Cloning repo..."
  git clone --depth=1 "${REPO_URL}" "${DEST}"
fi

# Verify the script exists
if [[ ! -f "${DEST}/${LINK_NAME}" ]]; then
  echo "Error: ${LINK_NAME} not found at ${DEST}/${LINK_NAME}"
  exit 1
fi

# Make executable
chmod +x "${DEST}/${LINK_NAME}"

# Choose a bin dir
if [[ -d "${BIN_DIR}" || ! -d "${ALT_BIN}" ]]; then
  INSTALL_BIN="${BIN_DIR}"
else
  INSTALL_BIN="${ALT_BIN}"
fi
mkdir -p "${INSTALL_BIN}"

# Symlink
ln -sf "${DEST}/${LINK_NAME}" "${INSTALL_BIN}/${LINK_NAME}"

echo "==> Symlinked ${INSTALL_BIN}/${LINK_NAME}"
echo "==> Ensure ${INSTALL_BIN} is on your PATH (e.g., echo 'export PATH=\"${INSTALL_BIN}:\$PATH\"' >> ~/.zshrc)"
echo "==> Done."
