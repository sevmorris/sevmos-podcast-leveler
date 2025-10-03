#!/usr/bin/env bash
# Sevmo's Podcast Leveler — VERSION v1.2
# Flow: OPTIONS (target → output → bitrate if needed) → message dialog → processing → blocking completion.
# Processing: two-pass ffmpeg loudnorm with linear=true to target (-18 or -16 LUFS), TP -1 dBTP.
# Outputs: WAV (24-bit/44.1k), MP3 (CBR 128/160/192), or Both.
# Filenames: <stem>-lev-<targetLUFS>.wav/.mp3  (e.g., myfile-lev-18LUFS.wav)

set +e
IFS=$'\n\t'

# ---- Version & defaults ----
VERSION="v1.2"
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
  /usr/bin/osascript -e 'display dialog "FFmpeg not found.\n\nInstall with: brew install ffmpeg" with title "Sevmo'\''s Podcast Leveler v1" buttons {"OK"} default button "OK" with icon stop' >/dev/null 2>&1
  echo "FFMPEG missing"; exit 0;
}

# ------------- OPTION PICKERS -------------

# 1) Target loudness
CHOICE_TARGET="$(
/usr/bin/osascript <<'APPLESCRIPT'
set targetOpts to {"Stereo −18 LUFS (recommended)", "Stereo −16 LUFS"}
set ch to (choose from list targetOpts with title "Sevmo's Podcast Leveler v1" with prompt "Choose loudness target (True Peak = −1.0 dBTP):" default items {"Stereo −18 LUFS (recommended)"} OK button name "Continue" cancel button name "Cancel")
if ch is false then
  return ""
end if
if item 1 of ch is "Stereo −16 LUFS" then
  return "-16"
else
  return "-18"
end if
APPLESCRIPT
)"
[ -z "$CHOICE_TARGET" ] && { echo "User cancelled target picker."; exit 0; }
TARGET_I="$CHOICE_TARGET"

# 2) Output format
CHOICE_OUTPUT="$(
/usr/bin/osascript <<'APPLESCRIPT'
set outOpts to {"WAV (24-bit)", "MP3 (CBR)", "Both WAV + MP3"}
set ch to (choose from list outOpts with title "Sevmo's Podcast Leveler v1" with prompt "Choose your deliverable(s):" default items {"Both WAV + MP3"} OK button name "Continue" cancel button name "Cancel")
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
APPLESCRIPT
)"
[ -z "$CHOICE_OUTPUT" ] && { echo "User cancelled output picker."; exit 0; }
OUTMODE="$CHOICE_OUTPUT"

# 3) MP3 bitrate (only if MP3 is included)
if [ "$OUTMODE" = "mp3" ] || [ "$OUTMODE" = "both" ]; then
  CHOICE_BR="$(
  /usr/bin/osascript <<'APPLESCRIPT'
display dialog "Choose MP3 constant bit-rate." with title "Sevmo's Podcast Leveler v1 — MP3 Bit-rate" buttons {"128 kbps","160 kbps (recommended)","192 kbps"} default button "160 kbps (recommended)" cancel button "160 kbps (recommended)"
set btn to the button returned of the result
if btn is "192 kbps" then
  return "192k"
else if btn is "128 kbps" then
  return "128k"
else
  return "160k"
end if
APPLESCRIPT
  )"
  MP3_BITRATE="${CHOICE_BR:-160k}"
fi

echo "Selections → Target: ${TARGET_I} LUFS | Output: ${OUTMODE} | MP3: ${MP3_BITRATE} | Version: ${VERSION}"

# ------------- MESSAGE (after options, before processing) -------------
/usr/bin/osascript <<'OSA' >/dev/null 2>&1
display dialog "Sevmo's Podcast Leveler v1

Please be patient — this may take a few minutes.

You’ll get a completion notification when it’s done.

IMPORTANT: You must wait for the completion confirmation before opening the generated files." buttons {"OK"} default button "OK" with icon note
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

  # NEW: mirrored suffix style: <stem>-lev-18LUFS
  WAV_OUT="${OUT_DIR}/${STEM}-lev-${TARGET_I}LUFS.wav"
  MP3_OUT="${OUT_DIR}/${STEM}-lev-${TARGET_I}LUFS.mp3"

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

  # Prepare temp vs final WAV
  TMP_WAV="$WAV_OUT"; DELETE_WAV_AFTER=0
  [ "$OUTMODE" = "mp3" ] && { TMP_WAV="$(mktemp -t leveled_${TARGET_I}LUFS.XXXXXX.wav)"; DELETE_WAV_AFTER=1; }

  # Pass 2 — render with pure gain (linear=true)
  if [ $HAVE_MEAS -eq 1 ]; then
    echo "  Two-pass render → WAV (linear gain only)"
    "$FFMPEG" -hide_banner -nostats -y -i "$IN" \
      -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:measured_I=${MEAS_I}:measured_TP=${MEAS_TP}:measured_LRA=${MEAS_LRA}:measured_thresh=${MEAS_THRESH}:offset=${MEAS_OFFSET}:linear=true:print_format=summary" \
      -ar 44100 -c:a pcm_s24le "$TMP_WAV"
  else
    echo "  Pass 1 parse incomplete; single-pass render (linear gain)"
    "$FFMPEG" -hide_banner -nostats -y -i "$IN" \
      -af "loudnorm=I=${TARGET_I}:TP=${TARGET_TP}:LRA=${TARGET_LRA}:linear=true:print_format=summary" \
      -ar 44100 -c:a pcm_s24le "$TMP_WAV"
  fi

  if [ ! -s "$TMP_WAV" ]; then echo "!! WAV render FAILED for: $BASE"; FAILED=$((FAILED+1)); [ $DELETE_WAV_AFTER -eq 1 ] && rm -f "$TMP_WAV"; continue; fi

  # Deliver WAV if requested
  if [ "$OUTMODE" = "wav" ] || [ "$OUTMODE" = "both" ]; then
    if [ "$TMP_WAV" != "$WAV_OUT" ]; then mv -f "$TMP_WAV" "$WAV_OUT"; TMP_WAV="$WAV_OUT"; DELETE_WAV_AFTER=0; fi
  fi

  # MP3 if requested
  if [ "$OUTMODE" = "mp3" ] || [ "$OUTMODE" = "both" ]; then
    echo "  Encoding MP3 (${MP3_BITRATE})"
    "$FFMPEG" -hide_banner -nostats -y -i "$TMP_WAV" -c:a "$MP3_CODEC" -b:a "$MP3_BITRATE" -ar 44100 -ac 2 "$MP3_OUT"
    if [ ! -s "$MP3_OUT" ]; then echo "!! MP3 encode FAILED for: $BASE"; FAILED=$((FAILED+1)); [ $DELETE_WAV_AFTER -eq 1 ] && rm -f "$TMP_WAV"; continue; fi
  fi

  # Spot-check (log only; run on the WAV)
  SC_TXT="$(mktemp -t pdlufs_sc.XXXXXX.txt 2>/dev/null || echo "/tmp/pdlufs_sc.$RANDOM.txt")"
  spotcheck_file "${WAV_OUT:-$TMP_WAV}" "$SC_TXT"
  if [ "$OUTMODE" = "wav" ]; then
    echo "✓ ${BASE} → $(basename "$WAV_OUT")  $(cat "$SC_TXT" 2>/dev/null || echo "")"
  elif [ "$OUTMODE" = "mp3" ]; then
    echo "✓ ${BASE} → $(basename "$MP3_OUT")  $(cat "$SC_TXT" 2>/dev/null || echo "")"
  else
    echo "✓ ${BASE} → $(basename "$WAV_OUT"), $(basename "$MP3_OUT")  $(cat "$SC_TXT" 2>/dev/null || echo "")"
  fi
  rm -f "$SC_TXT" 2>/dev/null || true

  [ $DELETE_WAV_AFTER -eq 1 ] && rm -f "$TMP_WAV"
  OKC=$((OKC+1))
done

# ------------- Completion (notification + blocking dialog) -------------
COMPLETE_BODY="OK=${OKC}  Failed=${FAILED}  Skipped=${SKIPPED}\nTarget: ${TARGET_I} LUFS (−1 dBTP)\nOutput: ${OUTMODE}\nVersion: ${VERSION}"
if [ "$OUTMODE" = "mp3" ] || [ "$OUTMODE" = "both" ]; then COMPLETE_BODY="${COMPLETE_BODY}\nMP3: ${MP3_BITRATE}"; fi

/usr/bin/osascript <<OSA >/dev/null 2>&1
display notification "$(printf "%b" "${COMPLETE_BODY}")" with title "Sevmo's Podcast Leveler — Complete ${VERSION}" sound name "default"
display dialog "Sevmo's Podcast Leveler — Complete ${VERSION}

$(printf "%b" "${COMPLETE_BODY}")" buttons {"OK"} default button "OK" with icon note
OSA

echo "Selections: Target=${TARGET_I} LUFS | Output=${OUTMODE} | MP3=${MP3_BITRATE}"
echo "Summary: OK=${OKC}  Failed=${FAILED}  Skipped=${SKIPPED} | Version: ${VERSION}"
echo "======== $(date '+%Y-%m-%d %H:%M:%S') — Run end ========" >>"$LOG_FILE"
exit 0
