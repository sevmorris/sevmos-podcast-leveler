#!/bin/sh
# Sevmo's Mono Limiter — uses VERSION variable
# 44.1/48 kHz / 24-bit WAV mono (channel 0) + brickwall peak limiter (no makeup gain)
# Normalizes loudness to -25 LUFS before limiting (two-pass when possible).
# Hidden dotfile temp is used until completion, then atomically revealed.
# Robust: no 'set -e'; per-file error handling; newline-safe dialogs

set -u
PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"; export PATH

VERSION="${VERSION:-v2.3.6}"
APP_TITLE="Sevmo's Mono Limiter ${VERSION}"; export APP_TITLE

# Loudness target (default -25 LUFS)
LUFS_TARGET="${LUFS_TARGET:--25}"

# Log file reflects VERSION dynamically
LOG="${HOME}/Library/Logs/sevmo_mono_limiter_${VERSION}.log"
mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1
echo ""
echo "======== $(date '+%Y-%m-%d %H:%M:%S') — Start run ========"
echo "App: ${APP_TITLE}"
echo "Args: $*"
echo "PATH=$PATH"
command -v ffmpeg  && ffmpeg -version  | head -n1
command -v ffprobe && ffprobe -version | head -n1

PROMPT_LIMIT="${PROMPT_LIMIT:-1}"   # 1 = ask each run; 0 = use LIMIT_DB below
LIMIT_DB="${LIMIT_DB:- -1.0}"
ATTACK_MS="${ATTACK_MS:-5}"
RELEASE_MS="${RELEASE_MS:-50}"
TRUEPEAK="${TRUEPEAK:-1}"
SUFFIX_BASE="${SUFFIX_BASE:-k24_mono0_lim}"
SOUND="${SOUND:-/System/Library/Sounds/Glass.aiff}"

FFMPEG_BIN="$(command -v ffmpeg || true)"
FFPROBE_BIN="$(command -v ffprobe || true)"

escape_osastr() { sed 's/\\/\\\\/g; s/"/\\"/g'; }
say_dialog() {
  title="$1"; msg="$2"
  msg=$(printf '%b' "$msg")
  /usr/bin/osascript -e "display dialog \"$(printf '%s' "$msg" | escape_osastr)\" buttons {\"OK\"} default button \"OK\" with title \"$(printf '%s' "$title" | escape_osastr)\"" >/dev/null 2>&1 || true
}
notify() {
  title="$1"; msg="$2"
  msg=$(printf '%b' "$msg")
  /usr/bin/osascript -e "display notification \"$(printf '%s' "$msg" | escape_osastr)\" with title \"$(printf '%s' "$title" | escape_osastr)\"" >/dev/null 2>&1 || true
}
fatal() {
  say_dialog "${APP_TITLE} — Error" "$1\n\nSee log:\n$LOG"
  echo "FATAL: $1"
  exit 1
}

[ "$#" -eq 0 ] && {
  say_dialog "${APP_TITLE}" "Drag files onto this app.

What it does:
• Choose 44.1 kHz or 48 kHz
• Convert to 24-bit WAV mono (channel 0)
• Normalize loudness to ${LUFS_TARGET} LUFS (two-pass)
• Brickwall limit peaks (no normalization)
• Hidden temp write; atomic reveal"
  exit 0
}

[ -z "$FFMPEG_BIN" ]  && fatal "FFmpeg not found. Install with: brew install ffmpeg"
[ -z "$FFPROBE_BIN" ] && fatal "ffprobe not found. Reinstall FFmpeg: brew install ffmpeg"

# --- Interactive rate picker (44.1 or 48) ---
rate_choice="$(/usr/bin/osascript <<'APPLESCRIPT'
set appTitle to (system attribute "APP_TITLE")
set theChoices to {"44.1 kHz", "48 kHz"}
set theChoice to choose from list theChoices with title appTitle with prompt "Select output sample rate:" default items {"44.1 kHz"} OK button name "Choose" cancel button name "Cancel"
if theChoice is false then
  return "CANCEL"
else
  return item 1 of theChoice
end if
APPLESCRIPT
)"
case "$rate_choice" in
  "44.1 kHz") SAMPLE_RATE=44100; RATE_TAG="44k" ;;
  "48 kHz")   SAMPLE_RATE=48000; RATE_TAG="48k" ;;
  "CANCEL") echo "User canceled."; say_dialog "${APP_TITLE}" "Canceled. No files processed."; exit 0 ;;
  *) SAMPLE_RATE=44100; RATE_TAG="44k" ;; # fallback
esac
SUFFIX="${RATE_TAG}${SUFFIX_BASE}"

# --- Ceiling picker ---
if [ "${PROMPT_LIMIT}" = "1" ]; then
  choice="$(/usr/bin/osascript <<'APPLESCRIPT'
set appTitle to (system attribute "APP_TITLE")
set theChoices to {"-1 dB", "-2 dB", "-3 dB", "-4 dB", "-5 dB", "-6 dB"}
set theChoice to choose from list theChoices with title appTitle with prompt "Select peak limit (dBFS):" default items {"-1 dB"} OK button name "Limit" cancel button name "Cancel"
if theChoice is false then
  return "CANCEL"
else
  return item 1 of theChoice
end if
APPLESCRIPT
)"
  case "$choice" in
    "-1 dB") LIMIT_DB="-1.0" ;;
    "-2 dB") LIMIT_DB="-2.0" ;;
    "-3 dB") LIMIT_DB="-3.0" ;;
    "-4 dB") LIMIT_DB="-4.0" ;;
    "-5 dB") LIMIT_DB="-5.0" ;;
    "-6 dB") LIMIT_DB="-6.0" ;;
    "CANCEL") echo "User canceled."; say_dialog "${APP_TITLE}" "Canceled. No files processed."; exit 0 ;;
    *) : ;;
  esac
fi

# --- Helpers for formatting and math ---
to_amp() { awk -v db="$1" 'BEGIN{print exp((db/20.0)*log(10))}'; }
strip_trailing_zero() { printf "%s" "$1" | sed 's/\(\.[0-9]*[1-9]\)0\+$//; s/\.0$//'; } 2>/dev/null

limit_amp="$(to_amp "$LIMIT_DB")"
LIMIT_DB_CLEAN="$(strip_trailing_zero "$LIMIT_DB")"     # e.g. "-1.0" -> "-1"
LIMIT_TAG="${LIMIT_DB_CLEAN}dB"

echo "Selections: SampleRate=${SAMPLE_RATE}  Ceiling=${LIMIT_DB} dBFS (linear ${limit_amp})  Version=${VERSION}"
echo "Loudness target: I=${LUFS_TARGET} LUFS"

# --- Start notifications + short message BEFORE processing ---
notify "${APP_TITLE}" "Starting… ${SAMPLE_RATE} Hz, mono ch0, ${LUFS_TARGET} LUFS, limit ${LIMIT_DB_CLEAN} dBFS"
say_dialog "${APP_TITLE}" "Please be patient — this may take a few minutes.

You’ll get a completion notification when it’s done."

WORKDIR="$(mktemp -d -t leftmono_${RATE_TAG}_XXXXXX)" || fatal "mktemp failed"
cleanup() { rm -rf "$WORKDIR"; }
trap 'cleanup' HUP INT TERM

success_n=0
fail_n=0
SUMMARY=""

for in_path in "$@"; do
  echo "--- Processing: $in_path"
  [ ! -f "$in_path" ] && { echo "Skip (not a regular file): $in_path"; continue; }

  dir="$(dirname "$in_path")"
  base="$(basename "$in_path")"
  stem="${base%.*}"

  mid_path="${WORKDIR}/${stem}_${RATE_TAG}24_mono0.wav"
  echo "Step 1: ffmpeg -> ${mid_path}"
  "$FFMPEG_BIN" -hide_banner -loglevel error -y \
    -i "$in_path" \
    -af "highpass=f=20,pan=1c|c0=c0,aresample=${SAMPLE_RATE}:resampler=soxr:dither_method=triangular_hp" \
    -c:a pcm_s24le -ar ${SAMPLE_RATE} -ac 1 \
    "$mid_path" || { echo "Step 1 failed for: $in_path"; fail_n=$((fail_n+1)); continue; }

  # Final visible path and hidden temp
  out_path="${dir}/${stem}-${SUFFIX}-${LIMIT_TAG}.wav"
  hidden_tmp="${dir}/.${stem}-${SUFFIX}-${LIMIT_TAG}.wav.tmp"

  # --- PASS 1: Measure loudness with JSON output (robust) ---
  echo "Step 2a: loudnorm measure (JSON)"
  PASS1="$("$FFMPEG_BIN" -nostdin -hide_banner -i "$mid_path" \
            -af "loudnorm=I=${LUFS_TARGET}:TP=${LIMIT_DB}:LRA=11:print_format=json" \
            -f null - 2>&1)"

  # Extract numeric fields from JSON without jq
  I="$(printf '%s\n' "$PASS1" | sed -nE 's/.*"input_i"[[:space:]]*:[[:space:]]*"([-+]?[0-9]+(\.[0-9]+)?)".*/\1/p'     | head -n1)"
  TP="$(printf '%s\n' "$PASS1" | sed -nE 's/.*"input_tp"[[:space:]]*:[[:space:]]*"([-+]?[0-9]+(\.[0-9]+)?)".*/\1/p'    | head -n1)"
  LRA="$(printf '%s\n' "$PASS1" | sed -nE 's/.*"input_lra"[[:space:]]*:[[:space:]]*"([-+]?[0-9]+(\.[0-9]+)?)".*/\1/p'  | head -n1)"
  THRESH="$(printf '%s\n' "$PASS1" | sed -nE 's/.*"input_thresh"[[:space:]]*:[[:space:]]*"([-+]?[0-9]+(\.[0-9]+)?)".*/\1/p' | head -n1)"
  OFFSET="$(printf '%s\n' "$PASS1" | sed -nE 's/.*"target_offset"[[:space:]]*:[[:space:]]*"([-+]?[0-9]+(\.[0-9]+)?)".*/\1/p' | head -n1)"

  # Limiter (same as v2.2)
  lim="alimiter=level_in=1:level_out=1:limit=${limit_amp}:attack=${ATTACK_MS}:release=${RELEASE_MS}:level=disabled"

  # Compose loudnorm pass 2 (prefer measured values)
  if [ -n "${I:-}" ] && [ -n "${TP:-}" ] && [ -n "${LRA:-}" ] && [ -n "${THRESH:-}" ]; then
    loudnorm_p2="loudnorm=I=${LUFS_TARGET}:TP=${LIMIT_DB}:LRA=11:measured_I=${I}:measured_TP=${TP}:measured_LRA=${LRA}:measured_thresh=${THRESH}:linear=true:print_format=summary"
    [ -n "${OFFSET:-}" ] && loudnorm_p2="${loudnorm_p2}:offset=${OFFSET}"
    echo "Step 2b: applying loudnorm (two-pass) to ${LUFS_TARGET} LUFS"
  else
    loudnorm_p2="loudnorm=I=${LUFS_TARGET}:TP=${LIMIT_DB}:LRA=11:linear=true:print_format=summary"
    echo "Step 2b: WARN: pass-1 parse failed — using single-pass loudnorm"
  fi

  if [ "$TRUEPEAK" = "1" ]; then
    oversample=$(( SAMPLE_RATE * 4 ))
    af="${loudnorm_p2},aresample=${oversample}:resampler=soxr,${lim},aresample=${SAMPLE_RATE}:resampler=soxr:dither_method=triangular_hp"
    echo "Step 2c: true-peak mode (${oversample} oversample)"
  else
    af="${loudnorm_p2},${lim},aresample=${SAMPLE_RATE}:resampler=soxr:dither_method=triangular_hp"
  fi

  # Ensure no stale temp, then render to hidden temp (force container with -f wav)
  [ -f "$hidden_tmp" ] && rm -f "$hidden_tmp"
  pass2_log="/tmp/.sevmo_pass2.$$"   # capture loudnorm summary from render
  echo "Step 3: ffmpeg -> (hidden temp) ${hidden_tmp}"
  if "$FFMPEG_BIN" -hide_banner -loglevel error -y \
       -i "$mid_path" -af "$af" \
       -c:a pcm_s24le -ar ${SAMPLE_RATE} -ac 1 \
       -f wav "$hidden_tmp" 2>"$pass2_log"
  then
    # Parse output stats from pass2 log (if present)
    OUT_I="$(sed -nE 's/.*Output Integrated:[[:space:]]*([-+]?[0-9]+(\.[0-9]+)?) .*/\1/p' "$pass2_log" | head -n1)"
    OUT_TP="$(sed -nE 's/.*Output True Peak:[[:space:]]*([-+]?[0-9]+(\.[0-9]+)?) .*/\1/p' "$pass2_log" | head -n1)"
    # Atomic reveal on success
    if mv -f "$hidden_tmp" "$out_path"; then
      echo "✅ Done -> $out_path"
      success_n=$((success_n+1))
      filebase="$(basename "$out_path")"
      SUMMARY="${SUMMARY}\n• ${filebase}: in ≈ ${I:-?} LUFS, TP ${TP:-?} dBTP → out ≈ ${OUT_I:-?} LUFS, TP ${OUT_TP:-?} dBTP"
    else
      echo "❌ Reveal (rename) failed for: $out_path"
      rm -f "$hidden_tmp" 2>/dev/null || true
      fail_n=$((fail_n+1))
    fi
  else
    echo "❌ Render failed for: $in_path"
    rm -f "$hidden_tmp" 2>/dev/null || true
    fail_n=$((fail_n+1))
  fi
  rm -f "$pass2_log" 2>/dev/null || true
done

[ -n "${SOUND:-}" ] && [ -f "$SOUND" ] && /usr/bin/afplay "$SOUND" >/dev/null 2>&1 || true

# --- Human-friendly completion message ---
if [ "$TRUEPEAK" = "1" ]; then
  tp_line1="True-peak limiting: ENABLED"
  tp_line2="Oversampling: 4×"
else
  tp_line1="True-peak limiting: DISABLED"
  tp_line2=""
fi
tp_bullets="• ${tp_line1}"
[ -n "$tp_line2" ] && tp_bullets="${tp_bullets}
• ${tp_line2}"

msg="✅ All set!

Here’s what I did:
• Converted everything to 24-bit mono (channel 0) at ${SAMPLE_RATE} Hz
• Measured overall loudness and leveled to ${LUFS_TARGET} LUFS (two-pass when possible)
• Applied a brickwall limiter with a ceiling of ${LIMIT_DB_CLEAN} dBFS
${tp_bullets}
• Wrote to a hidden temporary file and revealed the final WAV on success

Results:
• ${success_n} file(s) finished$( [ "$fail_n" -gt 0 ] && printf '\n• %s file(s) failed — see the session log below' "$fail_n" )

Per-file details:
$( [ -n "$SUMMARY" ] && printf '%s' "$SUMMARY" || printf '• (no per-file stats available)')

Session log:
$LOG"

# --- Concise action summary for macOS notification (spelled out; oversampling only when enabled) ---
if [ "$TRUEPEAK" = "1" ]; then
  tp_notif="True-peak limiting: ENABLED • Oversampling: 4×"
else
  tp_notif="True-peak limiting: DISABLED"
fi
actions_short="24-bit mono • ${SAMPLE_RATE} Hz • ${LUFS_TARGET} LUFS (2-pass) • limit ${LIMIT_DB_CLEAN} dBFS • ${tp_notif}"
files_short="$(printf '%s\n' "$SUMMARY" | sed -n 's/^• \([^:]*\):.*/\1/p' | head -n2 | tr '\n' ', ' | sed 's/, $//')"
notif_text="Files: ${success_n} ok$( [ "$fail_n" -gt 0 ] && printf ' • %s failed' "$fail_n" ) • ${actions_short}$( [ -n "$files_short" ] && printf ' • %s' "$files_short" )"

# Completion: notification + blocking dialog
notify "${APP_TITLE} — Complete" "$notif_text"
say_dialog "${APP_TITLE} — Complete" "$msg"

echo "======== $(date '+%Y-%m-%d %H:%M:%S') — Done ========"
exit 0
