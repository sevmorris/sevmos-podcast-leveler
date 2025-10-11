#!/usr/bin/env bash
set -Eeuo pipefail

DEST="${HOME}/WaxOn"
BIN_DIR="${HOME}/bin/waxon"
ALT_BIN="${HOME}/.local/bin/waxon"

echo "==> Uninstalling WaxOn..."

removed_any=0
for link in "${BIN_DIR}" "${ALT_BIN}"; do
  if [[ -L "${link}" || -f "${link}" ]]; then
    rm -f "${link}" && echo "Removed ${link}" && removed_any=1
  fi
done
if [[ "${removed_any}" -eq 0 ]]; then
  echo "No symlinks found in ~/bin or ~/.local/bin."
fi

if [[ -d "${DEST}" ]]; then
  rm -rf "${DEST}"
  echo "Removed ${DEST}"
fi

echo "==> Uninstalled."
