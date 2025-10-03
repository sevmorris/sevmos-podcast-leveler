#!/usr/bin/env bash
# Sevmo's Podcast Leveler — VERSION v1.2
# Flow: OPTIONS (target → output → bitrate if needed) → message dialog → processing → blocking completion.
# Processing: two-pass ffmpeg loudnorm with linear=true to target (-18 or -16 LUFS), TP -1 dBTP.
# Outputs: WAV (24-bit/44.1k), MP3 (CBR 128/160/192), or Both.
# Filenames: <stem>-lev-<targetLUFS>.wav/.mp3  (e.g., myfile-lev-18LUFS.wav)

set +e
IFS=$'\n\t'

# ---- Version & title ----
VERSION="v1.2"
APP_TITLE="Sevmo's Podcast Leveler ${VERSION}"
APP_TITLE_MP3="${APP_TITLE} — MP3 Bit-rate"

# ---- Defaults ----
TARGET_I="-18"
TARGET_TP="-1.0"
TARGET_LRA="11"     # informational; render uses linear=true
OUTMODE="both"      # wav | mp3 | both
MP3_BITRATE="160k"
MP3_CODEC="libmp3lame"

# ---- Tools ----
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
FFMPEG="${FFMPEG:-$(command -v /opt/homebrew/bin/ffmpeg || command -v ffmpeg || true)}"

# ---- Logging ----
LOG_FILE="${HOME}/Library/Logs/sevmo_podcast_leveler.log"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
{
  echo
  echo "======== $(date '+%Y-%m-%d %H:%M:%S') — Run start ========"
  echo "Script: Sevmo's Podcast Leveler ${VERSION}"
  echo "PATH=$PATH"
  echo "Args: $*"
  $FFMPEG -version 2>/dev/null | head -n1 || true
} >>"$LOG_FILE" 2>&1
exec >>"$LOG_FILE" 2>&1

# ---- Preconditions ----
[ $# -ge 1 ] || { echo "No files provided"; exit 0; }
[ -x "$FFMPEG" ] || {
  /usr/bin/osascript -e "display dialog \"FFmpeg not found.

Install with: brew install ffmpeg\" with title \"${APP_TITLE}\" buttons {\"OK\"} default button \"OK\" with icon stop" >/dev/null 2>&1
  echo "FFMPEG missing"; exit 0;
}

# ---- Hidden temp handling ----
# Create a hidden temp path inside OUT_DIR, unique per PID/RANDOM.
hidden_tmp() { # dir base ext
  local dir="$1" base="$2" ext="$3"
  echo "${dir}/.${base}.part.$$.$RANDOM.${ext}"
}

# Track and clean up any temps on exit or interruption.
TEMP_FILES=()
cleanup_temps() {
  for f in "${TEMP_FILES[@]}"; do
    [ -e "$f" ] && rm -f "$f"
  done
}
trap cleanup_temps EXIT INT TERM

# ------------- OPTION PICKERS -------------

# 1) Target loudness
CHOICE_TARGET="$(
/usr/bin/osascript <<OSA
set targetOpts to {"Stereo −18 LUFS (recommended)", "Stereo −16 LUFS"}
set ch to (choose from list targetOpts with title "${APP_TITLE}" with prompt "Choose loudness target (True Peak = −1.0 dBTP):" default items {"Stereo −18 LUFS (recommended)"} OK button name "Continue" cancel button name "Cancel")
if ch is false then
  return ""
end if
if item 1 of ch is "Stereo −16 LUFS" then
  return "-16"
else
  return "-18"
end if
OSA
)"
[ -z "$CHOICE_TARGET" ] && { echo "User cancelled target picker."; exit 0; }
TARGET_I="$CHOICE_TARGET"

# 2) Output format
CHOICE_OUTPUT="$(
/usr/bin/osascript <<OSA
set outOpts to {"WAV (24-bit)", "MP3 (CBR)", "Both WAV + MP3"}
set ch to (choose from list outOpts with title "${APP_TITLE}" with prompt "Choose your deliverable(s):" default items {"Both WAV + MP3"} OK button name "Continue" cancel button name "Cancel")
if ch is false then
  return ""
end if
if item 1 of ch is "WAV (24-bit)" then
  return "wav"
else if item 1 of ch is "MP3 (CBR)" then
  return "mp3"
else
  return "both"
end if
OSA
)"
[ -z "$CHOICE_OUTPUT" ] && { echo "User cancelled output picker."; exit 0; }
OUTMODE="$CHOICE_OUTPUT"

# 3) MP3 bitrate (only if MP3 is included)
if [ "$OUTMODE" = "mp3" ] || [ "$OUTMODE" = "both" ]; then
  CHOICE_BR="$(
  /usr/bin/osascript <<OSA
display dialog "Choose MP3 constant bit-rate." with title "${APP_TITLE_MP3}" buttons {"128 kbps","160 kbps (recommended)","192 kbps"} default button "160 kbps (recommended)" cancel button "160 kbps (recommended)"
set btn to the button returned of the result
if btn is "192 kbps" then
  return "192k"
else if btn is "128 kbps" then
  return "128k"
else
  return "160k"
end if
OSA
  )"
  MP3_BITRATE="${CHOICE_BR:-160k}"
fi

echo "Selections → Target: ${TARGET_I} LUFS | Output: ${OUTMODE} | MP3: ${MP3_BITRATE} | Version: ${VERSION}"

# ------------- MESSAGE (after options, before processing) -------------
/usr/bin/osascript <<OSA >/dev/null 2>&1
display dialog "${APP_TITLE}

Please be patient — this may take a few minutes.

You’ll get a completion notification when it’s done." buttons {"OK"} default button "OK" with icon note with title "${APP_TITLE}"
OSA

# ------------- Helpers -------------
extract_json_num() { local f="$1" key="$2"; LC_ALL=C sed -nE "s/.*\"${key}\"[[:space:]]*:[[:space:]]*([-+]?([0-9]*\.)?[0-9]+).*/\1/p" "$f" | head -n1; }

spotcheck_file() { # INFILE OUT_TXT
  local F="$1" OUT="$2" J
  J="$(mktemp -t pdlufs_check.XXXXXX.json 2>/dev/null || echo "/tmp/pdlufs_check.$RANDOM.json")"
  "$FFMPEG" -hide_banner -nostats -y -i "$F" \
    -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:print_format=json" \
    -f null - 2> "$J"
  if [ $? -ne 0 ]; then
    echo "I=n/a TP=n/a" > "$OUT"
  else
    local fi tp
    fi="$(extract_json_num "$J" input_i)"; tp="$(extract_json_num "$J" input_tp)"
    echo "I=${fi:-n/a} TP=${tp:-n/a}" > "$OUT"
  fi
  rm -f "$J" 2>/dev/null || true
}

# ------------- Processing -------------
TOTAL=$#
INDEX=0
OKC=0
FAILED=0
SKIPPED=0

for IN in "$@"; do
  INDEX=$((INDEX+1))
  if [ ! -f "$IN" ]; then echo "Skip (not a file): $IN"; SKIPPED=$((SKIPPED+1)); continue; fi

  BASE="$(basename "$IN")"
  SRC_DIR="$(cd "$(dirname "$IN")" && pwd -P)"
  OUT_DIR="$SRC_DIR"
  [ -w "$OUT_DIR" ] || { echo "Skip (not writable): $OUT_DIR for ${BASE}"; SKIPPED=$((SKIPPED+1)); continue; }

  echo "--> (${INDEX}/${TOTAL}) $IN"
  STEM="${BASE%.*}"
  STEM_TAG="${STEM}-lev-${TARGET_I}LUFS"

  # Final, visible targets
  WAV_OUT="${OUT_DIR}/${STEM_TAG}.wav"
  MP3_OUT="${OUT_DIR}/${STEM_TAG}.mp3"

  # Hidden temps (stay invisible until success)
  TMP_WAV="$(hidden_tmp "$OUT_DIR" "$STEM_TAG" "wav")"; TEMP_FILES+=("$TMP_WAV")
  TMP_MP3="$(hidden_tmp "$OUT_DIR" "$STEM_TAG" "mp3")" # add to TEMP_FILES only when used

  # Pass 1 — measure only
  PASS1_JSON="$(mktemp -t pdlufs_pass1.XXXXXX.json 2>/dev/null || echo "/tmp/pdlufs_pass1.$RANDOM.json")"
  "$FFMPEG" -hide_banner -nostats -y -i "$IN" \
    -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:print_format=json" \
    -f null - 2> "$PASS1_JSON"
  P1_RC=$?

  MEAS_I="$(extract_json_num "$PASS1_JSON" input_i)"
  MEAS_TP="$(extract_json_num "$PASS1_JSON" input_tp)"
  MEAS_LRA="$(extract_json_num "$PASS1_JSON" input_lra)"
  MEAS_THRESH="$(extract_json_num "$PASS1_JSON" input_thresh)"
  MEAS_OFFSET="$(extract_json_num "$PASS1_JSON" target_offset)"
  rm -f "$PASS1_JSON" 2>/dev/null || true

  HAVE_MEAS=0
  if [ $P1_RC -eq 0 ] && [ -n "${MEAS_I:-}" ] && [ -n "${MEAS_TP:-}" ] && [ -n "${MEAS_LRA:-}" ] && [ -n "${MEAS_THRESH:-}" ] && [ -n "${MEAS_OFFSET:-}" ]; then HAVE_MEAS=1; fi

  # Pass 2 — render WAV to hidden temp (linear gain only)
  if [ $HAVE_MEAS -eq 1 ]; then
    echo "  Two-pass render → hidden WAV (linear gain only)"
    "$FFMPEG" -hide_banner -nostats -y -i "$IN" \
      -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:measured_I=${MEAS_I}:measured_TP=${MEAS_TP}:measured_LRA=${MEAS_LRA}:measured_thresh=${MEAS_THRESH}:offset=${MEAS_OFFSET}:linear=true:print_format=summary" \
      -ar 44100 -c:a pcm_s24le -f wav "$TMP_WAV"
  else
    echo "  Pass 1 parse incomplete; single-pass render → hidden WAV (linear gain)"
    "$FFMPEG" -hide_banner -nostats -y -i "$IN" \
      -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:linear=true:print_format=summary" \
      -ar 44100 -c:a pcm_s24le -f wav "$TMP_WAV"
  fi

  if [ ! -s "$TMP_WAV" ]; then
    echo "!! WAV render FAILED for: $BASE"
    FAILED=$((FAILED+1))
    continue
  fi

  # If WAV requested, reveal it atomically now
  if [ "$OUTMODE" = "wav" ] || [ "$OUTMODE" = "both" ]; then
    mv -f "$TMP_WAV" "$WAV_OUT"
    # remove from temp tracking (already moved)
    for i in "${!TEMP_FILES[@]}"; do [ "${TEMP_FILES[$i]}" = "$TMP_WAV" ] && unset 'TEMP_FILES[i]'; done
  fi

  # MP3 if requested — encode from the hidden WAV (or revealed WAV if already moved)
  if [ "$OUTMODE" = "mp3" ] || [ "$OUTMODE" = "both" ]; then
    SRC_FOR_MP3="$TMP_WAV"
    [ -f "$WAV_OUT" ] && SRC_FOR_MP3="$WAV_OUT"

    # Mark TMP_MP3 for cleanup only when used
    TEMP_FILES+=("$TMP_MP3")
    echo "  Encoding MP3 (${MP3_BITRATE}) → hidden temp"
    "$FFMPEG" -hide_banner -nostats -y -i "$SRC_FOR_MP3" \
      -c:a "$MP3_CODEC" -b:a "$MP3_BITRATE" -ar 44100 -ac 2 -f mp3 "$TMP_MP3"

    if [ ! -s "$TMP_MP3" ]; then
      echo "!! MP3 encode FAILED for: $BASE"
      FAILED=$((FAILED+1))
      # If WAV wasn't requested (mp3-only), leave hidden WAV temp for cleanup; otherwise WAV is already revealed.
      continue
    fi

    # Reveal MP3 atomically
    mv -f "$TMP_MP3" "$MP3_OUT"
    for i in "${!TEMP_FILES[@]}"; do [ "${TEMP_FILES[$i]}" = "$TMP_MP3" ] && unset 'TEMP_FILES[i]'; done
  fi

  # Spot-check (log only; prefer the revealed WAV if it exists, else hidden temp)
  SC_TXT="$(mktemp -t pdlufs_sc.XXXXXX.txt 2>/dev/null || echo "/tmp/pdlufs_sc.$RANDOM.txt")"
  if [ -f "$WAV_OUT" ]; then
    spotcheck_file "$WAV_OUT" "$SC_TXT"
  else
    spotcheck_file "$TMP_WAV" "$SC_TXT"
  fi

  if [ "$OUTMODE" = "wav" ]; then
    echo "✓ ${BASE} → $(basename "$WAV_OUT")  $(cat "$SC_TXT" 2>/dev/null || echo "")"
  elif [ "$OUTMODE" = "mp3" ]; then
    echo "✓ ${BASE} → $(basename "$MP3_OUT")  $(cat "$SC_TXT" 2>/dev/null || echo "")"
  else
    echo "✓ ${BASE} → $(basename "$WAV_OUT"), $(basename "$MP3_OUT")  $(cat "$SC_TXT" 2>/dev/null || echo "")"
  fi
  rm -f "$SC_TXT" 2>/dev/null || true

  # If mp3-only, we used hidden WAV temp just as an intermediate — remove it now
  if [ "$OUTMODE" = "mp3" ] && [ -f "$TMP_WAV" ]; then
    rm -f "$TMP_WAV"
    for i in "${!TEMP_FILES[@]}"; do [ "${TEMP_FILES[$i]}" = "$TMP_WAV" ] && unset 'TEMP_FILES[i]'; done
  fi

  OKC=$((OKC+1))
done

# ------------- Completion (notification + blocking dialog) -------------
# Titles match confirmation pop-up (APP_TITLE). Bodies contain no version text.
COMPLETE_BODY="OK=${OKC}  Failed=${FAILED}  Skipped=${SKIPPED}\nTarget: ${TARGET_I} LUFS (−1 dBTP)\nOutput: ${OUTMODE}"
if [ "$OUTMODE" = "mp3" ] || [ "$OUTMODE" = "both" ]; then COMPLETE_BODY="${COMPLETE_BODY}\nMP3: ${MP3_BITRATE}"; fi

/usr/bin/osascript <<OSA >/dev/null 2>&1
display notification "$(printf "%b" "${COMPLETE_BODY}")" with title "${APP_TITLE}" sound name "default"
display dialog "$(printf "%b" "${COMPLETE_BODY}")" buttons {"OK"} default button "OK" with icon note with title "${APP_TITLE}"
OSA

echo "Selections: Target=${TARGET_I} LUFS | Output=${OUTMODE} | MP3=${MP3_BITRATE}"
echo "Summary: OK=${OKC}  Failed=${FAILED}  Skipped=${SKIPPED} | Version: ${VERSION}"
echo "======== $(date '+%Y-%m-%d %H:%M:%S') — Run end ========" >>"$LOG_FILE"
exit 0
