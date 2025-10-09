#!/usr/bin/env bash
# Uninstall symlink for this tool only (keeps repo)
set -euo pipefail
IFS=$'\n\t'

EXE_NAME="${EXE_NAME:-waxon}"  # override to 'waxoff' inside WaxOff repo

choose_bin_dir() {
  if [[ -d "${HOME}/bin" ]]; then echo "${HOME}/bin"
  elif [[ -d "${HOME}/.local/bin" ]]; then echo "${HOME}/.local/bin"
  else echo ""; fi
}
BIN_DIR="$(choose_bin_dir)"

if [[ -n "${BIN_DIR}" && -e "${BIN_DIR}/${EXE_NAME}" ]]; then
  rm -f "${BIN_DIR}/${EXE_NAME}"
  echo "✓ Removed ${BIN_DIR}/${EXE_NAME}"
else
  echo "Nothing to remove."
fi

echo "✅ Uninstall complete (symlink only)."
