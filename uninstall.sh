#!/usr/bin/env bash
set -euo pipefail
TARGET="${HOME}/bin/waxon"
if [ -L "$TARGET" ] || [ -f "$TARGET" ]; then
  rm -f "$TARGET"
  echo "Removed symlink: $TARGET"
else
  echo "No symlink at $TARGET"
fi
