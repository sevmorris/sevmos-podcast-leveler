#!/usr/bin/env bash
set -euo pipefail

APP="waxon"
SRC="./${APP}"

PREFIX="${PREFIX:-$HOME/bin}"   # default user-local
MODE="copy"                     # copy | dev
UNINSTALL=0

usage() {
  cat <<EOF
${APP} installer

Usage: ./install.sh [--prefix DIR] [--dev] [--uninstall]

Options:
  --prefix DIR   Install prefix (default: ~/bin; fallback ~/.local/bin)
  --dev          Symlink from repo (development mode)
  --uninstall    Remove installed binary (from prefix)
  -h, --help     Show this help

Environment:
  PREFIX         Same as --prefix (overrides default)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)   PREFIX="$2"; shift 2 ;;
    --dev)      MODE="dev"; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ "${PREFIX}" == "$HOME/bin" && ! -d "$HOME/bin" ]]; then
  PREFIX="$HOME/.local/bin"
fi

TARGET="${PREFIX}/${APP}"
mkdir -p "${PREFIX}"

if [[ $UNINSTALL -eq 1 ]]; then
  if [[ -e "$TARGET" ]]; then
    rm -f "$TARGET"
    echo "Removed $TARGET"
  else
    echo "No ${APP} found at $TARGET"
  fi
  exit 0
fi

if [[ ! -f "$SRC" ]]; then
  echo "Cannot find ${SRC}. Run this from the repo root." >&2
  exit 1
fi

if [[ "$MODE" == "dev" ]]; then
  ln -sfn "$(cd "$(dirname "$SRC")" && pwd)/$(basename "$SRC")" "$TARGET"
  echo "Symlinked (dev): $TARGET -> $SRC"
else
  install -m 0755 "$SRC" "$TARGET"
  echo "Installed: $TARGET"
fi

SHELLRC="${HOME}/.zshrc"
LINE='export PATH="$HOME/bin:$HOME/.local/bin:$PATH"'
if [[ -f "$SHELLRC" ]]; then
  if ! grep -qs "$LINE" "$SHELLRC"; then
    echo "$LINE" >> "$SHELLRC"
    echo "Appended PATH update to ${SHELLRC}. Run: source ${SHELLRC}"
  fi
else
  echo "$LINE" >> "$SHELLRC"
  echo "Created ${SHELLRC} with PATH update. Run: source ${SHELLRC}"
fi

echo "Done."
