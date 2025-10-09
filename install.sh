#!/usr/bin/env bash
# WaxOn per-repo installer: clone to ~/WaxOn and symlink 'waxon'
set -euo pipefail
IFS=$'\n\t'

REPO_URL="https://github.com/sevmorris/WaxOn.git"
REPO_NAME="WaxOn"
EXE_NAME="waxon"

choose_bin_dir() {
  if [[ -d "${HOME}/bin" ]]; then echo "${HOME}/bin"
  elif [[ -d "${HOME}/.local/bin" ]]; then echo "${HOME}/.local/bin"
  else mkdir -p "${HOME}/bin"; echo "${HOME}/bin"; fi
}
BIN_DIR="$(choose_bin_dir)"

case ":${PATH}:" in *:"${BIN_DIR}":*) ;; *)
  echo "⚠️  ${BIN_DIR} not in PATH. Add: export PATH=\"${BIN_DIR}:\$PATH\"";;
esac

DEST="${HOME}/${REPO_NAME}"
if [[ -d "${DEST}/.git" ]]; then
  echo "→ Updating ${REPO_NAME} in ${DEST}"
  git -C "${DEST}" fetch --quiet --all
  git -C "${DEST}" pull --quiet --rebase || git -C "${DEST}" pull --quiet
else
  echo "→ Cloning ${REPO_NAME} to ${DEST}"
  git clone --depth=1 "${REPO_URL}" "${DEST}"
fi

find_exec() {
  local d="$1" n="$2"
  for p in "${d}/${n}" "${d}/${n}.sh" "${d}/scripts/${n}" "${d}/scripts/${n}.sh" "${d}/bin/${n}" "${d}/bin/${n}.sh"; do
    [[ -f "$p" ]] && { echo "$p"; return 0; }
  done
  return 1
}

SRC="$(find_exec "${DEST}" "${EXE_NAME}")" || {
  echo "❌ Could not find ${EXE_NAME}{,.sh} in repo root/scripts/bin."
  exit 1
}

chmod +x "${SRC}"
ln -sfn "${SRC}" "${BIN_DIR}/${EXE_NAME}"
echo "✅ Installed: ${EXE_NAME} -> ${SRC}"
