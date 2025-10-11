#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/sevmorris/WaxOn.git"
DEST="${HOME}/WaxOn"
BIN_DIR="${HOME}/bin"
ALT_BIN="${HOME}/.local/bin"
LINK_NAME="waxon"

command -v git >/dev/null 2>&1 || { echo "Error: git is required."; exit 1; }

if [[ -d "${DEST}/.git" ]]; then
  git -C "${DEST}" pull --ff-only
else
  git clone --depth=1 "${REPO_URL}" "${DEST}"
fi

if [[ ! -f "${DEST}/${LINK_NAME}" ]]; then
  echo "Error: ${LINK_NAME} not found at ${DEST}/${LINK_NAME}"
  exit 1
fi

chmod +x "${DEST}/${LINK_NAME}"

INSTALL_BIN="${BIN_DIR}"
[[ -d "${BIN_DIR}" || ! -d "${ALT_BIN}" ]] || INSTALL_BIN="${ALT_BIN}"
mkdir -p "${INSTALL_BIN}"
ln -sf "${DEST}/${LINK_NAME}" "${INSTALL_BIN}/${LINK_NAME}"

echo "Installed: ${INSTALL_BIN}/${LINK_NAME}"
