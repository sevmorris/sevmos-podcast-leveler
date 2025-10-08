#!/usr/bin/env bash
# uninstall.sh — Remove WaxOn CLI (detects minimal vs developer install)
# Modes:
#  - Minimal: single binary at /usr/local/bin or /opt/homebrew/bin
#  - Developer: symlink to ~/.local/share/waxon/waxon.sh + local clone
#
# Options:
#   --yes       Non-interactive (assume Yes to prompts)
#   --purge     Also delete logs in ~/Library/Logs/waxon_*.log
#   --dry-run   Show what would be removed without deleting
#   --verbose   Print extra diagnostics
#   -h|--help   Help text

set -euo pipefail

YES=0
PURGE=0
DRYRUN=0
VERBOSE=0

say()  { printf "%s\n" "$*"; }
dbg()  { [ "$VERBOSE" -eq 1 ] && printf "[debug] %s\n" "$*"; }
ask()  {
  [ "$YES" -eq 1 ] && return 0
  read -r -p "$1 [y/N] " ans || ans=""
  case "$ans" in [yY][eE][sS]|[yY]) return 0 ;; *) return 1 ;; esac
}

usage() {
  cat <<EOF
WaxOn uninstaller
Removes the global 'waxon' command. Detects minimal vs developer installs.

Usage: ./uninstall.sh [--yes] [--purge] [--dry-run] [--verbose]

  --yes        Non-interactive; assume Yes for prompts
  --purge      Also delete logs at ~/Library/Logs/waxon_*.log
  --dry-run    Print actions only; no deletions
  --verbose    Extra diagnostics
  -h, --help   Show this help and exit
EOF
}

while [ "${1:-}" ]; do
  case "$1" in
    --yes) YES=1; shift ;;
    --purge) PURGE=1; shift ;;
    --dry-run) DRYRUN=1; shift ;;
    --verbose) VERBOSE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) say "Unknown option: $1"; usage; exit 2 ;;
  esac
done

REPO_DIR="${HOME}/.local/share/waxon"
LOG_GLOB="${HOME}/Library/Logs/waxon_*.log"

# Find the installed binary if present
BIN_PATH="$(command -v waxon 2>/dev/null || true)"
if [ -z "$BIN_PATH" ]; then
  # Try common locations
  for p in "/usr/local/bin/waxon" "/opt/homebrew/bin/waxon" "${HOME}/.local/bin/waxon"; do
    [ -x "$p" ] && BIN_PATH="$p" && break
  done
fi

if [ -z "$BIN_PATH" ]; then
  say "WaxOn does not appear to be installed. Nothing to do."
  exit 0
fi

dbg "Detected binary: $BIN_PATH"

# Portable realpath (resolve symlinks without relying on readlink -f)
resolve_path() {
  target="$1"
  while [ -L "$target" ]; do
    link="$(readlink "$target")"
    case "$link" in
      /*) target="$link" ;;                       # absolute
      *)  target="$(cd "$(dirname "$target")" && pwd)/$link" ;;  # relative
    esac
  done
  printf "%s" "$target"
}

RESOLVED="$(resolve_path "$BIN_PATH")"
dbg "Resolved target: $RESOLVED"

MODE="minimal"
case "$RESOLVED" in
  "$REPO_DIR"/*) MODE="developer" ;;
esac

say "Uninstall mode: $MODE"

# Remove global command
remove_bin() {
  local path="$1"
  if [ -e "$path" ] || [ -L "$path" ]; then
    if [ "$DRYRUN" -eq 1 ]; then
      say "(dry-run) rm -f $path"
    else
      rm -f "$path" 2>/dev/null || sudo rm -f "$path"
      say "Removed: $path"
    fi
  fi
}

# Minimal: just remove the installed binary
if [ "$MODE" = "minimal" ]; then
  remove_bin "$BIN_PATH"
else
  # Developer: remove symlink, then remove local clone
  remove_bin "$BIN_PATH"
  if [ -d "$REPO_DIR" ]; then
    if ask "Also remove local repo at $REPO_DIR ?"; then
      if [ "$DRYRUN" -eq 1 ]; then
        say "(dry-run) rm -rf $REPO_DIR"
      else
        rm -rf "$REPO_DIR"
        say "Removed repo: $REPO_DIR"
      fi
    else
      say "Kept repo: $REPO_DIR"
    fi
  fi
fi

# Optional purge of logs
if [ "$PURGE" -eq 1 ]; then
  for f in $LOG_GLOB; do
    [ -e "$f" ] || continue
    if [ "$DRYRUN" -eq 1 ]; then
      say "(dry-run) rm -f $f"
    else
      rm -f "$f"
      say "Deleted log: $f"
    fi
  done
fi

say "Done."
