#!/usr/bin/env bash
set -euo pipefail
removed=0
for d in "$HOME/bin" "$HOME/.local/bin"; do
  f="$d/waxon"
  if [ -e "$f" ]; then
    rm -f "$f"
    echo "Removed $f"
    removed=1
  fi
done
if [ "$removed" -eq 0 ]; then
  echo "No waxon binary found in ~/bin or ~/.local/bin"
fi
