#!/bin/sh
# WaxOn CLI — Consistent, safe, and DAW-ready audio
# DC block → (optional) declip → 20 Hz HPF → mono(L) → resample → loudnorm -25 LUFS → brickwall limiter → (TP resample/dither) → 24-bit WAV
# Tested with FFmpeg 8.x (macOS). POSIX sh; no AppleScript/UI deps.

set -u
set +e
unset POSIXLY_CORRECT >/dev/null 2>&1 || true

LC_ALL="${LC_ALL:-en_US.UTF-8}"; LANG="${LANG:-en_US.UTF-8}"
export LC_ALL LANG
PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

VERSION="v1.0.2"
APP_NAME="WaxOn"
TAGLINE="Consistent, safe, and DAW-ready audio."

# -------- Defaults (override via flags) --------
SAMPLE_RATE=44100               # 44100 or 48000
LIMIT_DB="-1.0"                 # limiter ceiling in dBFS
ATTACK_MS=5
RELEASE_MS=50
TRUEPEAK=1                      # 1/0
TP_OVERSAMPLE=4                 # 4 or 8
DITHER=1                        # 1/0 final-stage TPDF-HP
CLIP_REPAIR="auto"              # auto|on|off
CLIP_THRESHOLD=1                # clipped samples threshold for auto
DC_BLOCK_HZ=20                  # first highpass
LUFS_TARGET="-25"               # fixed DAW working level
OUTDIR=""                       # default: alongside source (or fallback)
SUFFIX_BASE="waxon"
LOG="${HOME}/Library/Logs/waxon_${VERSION}_cli.log"
QUIET=0
DRYRUN=0

# -------- Utilities --------
FFMPEG_BIN="$(command -v ffmpeg || true)"
FFPROBE_BIN="$(command -v ffprobe || true)"

log()   { printf '%s\n' "$*" >>"$LOG"; [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }
die()   { printf 'ERROR: %s\n' "$*" | tee -a "$LOG" 1>&2; exit 1; }
nz()    { [ -n "${1:-}" ] && printf '%s' "$1" || printf 'n/a'; }
to_amp(){ awk -v db="$1" 'BEGIN{print exp((db/20.0)*log(10))}'; }
strip0(){ printf "%s" "$1" | sed 's/\(\.[0-9]*[1-9]\)0\+$//; s/\.0$//'; }

usage() {
  cat <<EOF
${APP_NAME} ${VERSION} — ${TAGLINE}

Usage:
  waxon.sh [options] file1 [file2 ...]
Options:
  -r, --rate {44100|48000}     Output sample rate (default: 44100)
  -c, --ceiling DB             Limiter ceiling dBFS (default: -1.0)
  -p, --truepeak {1|0}         True-peak oversampling on/off (default: 1)
  -o, --oversample {4|8}       TP oversample factor (default: 4)
  -d, --dither {1|0}           Final-stage TPDF-HP dither on/off (default: 1)
  -R, --repair {auto|on|off}   Declip mode (default: auto)
  -T, --clip-threshold N       Enable declip when clipped samples >= N (default: 1)
  -b, --dc-block HZ            DC/infra high-pass corner (default: 20 Hz)
  -L, --lufs TARGET            Loudness target (default: -25, DAW working level)
  -O, --outdir DIR             Output directory (default: alongside source; fallback to ~/Music/WaxOn or ~/Desktop)
  -S, --suffix TAG             Base filename tag (default: waxon)
  -l, --log PATH               Log file path (default: ~/Library/Logs/waxon_${VERSION}_cli.log)
  -q, --quiet                  Suppress stdout (log still written)
  -n, --dry-run                Print actions, don’t render
  -h, --help                   Show help

Examples:
  waxon.sh -r 48000 -c -1.5 -O ~/Desktop/outs *.wav
  waxon.sh --repair auto --clip-threshold 2 "Guest A.aif" "Guest B.mp3"

Notes:
  • -25 LUFS is a staging level for DAW import (not distribution). Silence/pauses are included in integrated LUFS with ITU gating.
  • Chain: DC block → (optional) declip → 20 Hz HPF → mono(L) → resample → loudnorm → limiter (peaks only) → (TP resample/dither) → 24-bit WAV.
EOF
}

# -------- Parse args (POSIX-friendly long/short) --------
parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -r|--rate)           SAMPLE_RATE="$2"; shift 2;;
      -c|--ceiling)        LIMIT_DB="$2"; shift 2;;
      -p|--truepeak)       TRUEPEAK="$2"; shift 2;;
      -o|--oversample)     TP_OVERSAMPLE="$2"; shift 2;;
      -d|--dither)         DITHER="$2"; shift 2;;
      -R|--repair)         CLIP_REPAIR="$2"; shift 2;;
      -T|--clip-threshold) CLIP_THRESHOLD="$2"; shift 2;;
      -b|--dc-block)       DC_BLOCK_HZ="$2"; shift 2;;
      -L|--lufs)           LUFS_TARGET="$2"; shift 2;;
      -O|--outdir)         OUTDIR="$2"; shift 2;;
      -S|--suffix)         SUFFIX_BASE="$2"; shift 2;;
      -l|--log)            LOG="$2"; shift 2;;
      -q|--quiet)          QUIET=1; shift;;
      -n|--dry-run)        DRYRUN=1; shift;;
      -h|--help)           usage; exit 0;;
      --)                  shift; break;;
      -*)
        echo "Unknown option: $1" 1>&2; usage; exit 2;;
      *)
        # First non-flag means files begin
        break;;
    esac
  done
  # Remaining args are files
  INPUTS="$@"
}

# -------- Start --------
mkdir -p "$(dirname "$LOG")" || true
echo "" >>"$LOG"
log "======== $(date '+%Y-%m-%d %H:%M:%S') — Start run ========"
log "App: ${APP_NAME} ${VERSION} — ${TAGLINE}"

parse_args "$@"
if [ -z "${INPUTS:-}" ]; then usage; exit 2; fi

[ -z "$FFMPEG_BIN" ]  && die "FFmpeg not found. Install with: brew install ffmpeg"
[ -z "$FFPROBE_BIN" ] && die "ffprobe not found. Reinstall FFmpeg."

case "$SAMPLE_RATE" in 44100|48000) :;; *) die "Invalid --rate. Use 44100 or 48000.";; esac
case "$TRUEPEAK" in 0|1) :;; *) die "Invalid --truepeak. Use 0 or 1.";; esac
case "$TP_OVERSAMPLE" in 4|8) :;; *) die "Invalid --oversample. Use 4 or 8.";; esac
case "$DITHER" in 0|1) :;; *) die "Invalid --dither. Use 0 or 1.";; esac
case "$CLIP_REPAIR" in auto|on|off) :;; *) die "Invalid --repair. Use auto|on|off.";; esac

LIMIT_DB_CLEAN="$(strip0 "$LIMIT_DB")"
LIMIT_TAG="${LIMIT_DB_CLEAN}dB"
RATE_TAG="$( [ "$SAMPLE_RATE" -eq 48000 ] && echo 48k || echo 44k )"
SUFFIX="${RATE_TAG}${SUFFIX_BASE}"
limit_amp="$(to_amp "$LIMIT_DB")"

log "Settings: SR=${SAMPLE_RATE}  LUFS=${LUFS_TARGET} TP=${TRUEPEAK}x${TP_OVERSAMPLE}  Dither=${DITHER}  Limit=${LIMIT_DB}  DC=${DC_BLOCK_HZ}Hz  Repair=${CLIP_REPAIR}/${CLIP_THRESHOLD}"
log "Log: $LOG"

# -------- Helpers --------
detect_clipped_samples() {
  in_file="$1"
  "$FFMPEG_BIN" -nostdin -hide_banner -v error -i "$in_file" \
    -af "astats=metadata=1:reset=0" -f null - 2>&1 \
  | awk '
    BEGIN{sum=0}
    /clipped[[:space:]]+samples/i {
      for (i=1;i<=NF;i++) if ($i ~ /^[0-9]+$/) sum += $i
    }
    END{ if (sum=="") sum=0; print sum }'
}

choose_outdir() {
  src_dir="$1"
  if [ -n "$OUTDIR" ]; then
    mkdir -p "$OUTDIR" 2>/dev/null || true
    if [ -w "$OUTDIR" ]; then printf "%s" "$OUTDIR"; return; fi
  fi
  if [ -w "$src_dir" ]; then printf "%s" "$src_dir"; return; fi
  fallback="${HOME}/Music/WaxOn"
  mkdir -p "$fallback" 2>/dev/null || true
  if [ -w "$fallback" ]; then printf "%s" "$fallback"; return; fi
  printf "%s" "${HOME}/Desktop"
}

# -------- Process --------
success_n=0
fail_n=0

for in_path in $INPUTS; do
  log "--- Processing: $in_path"
  if [ ! -f "$in_path" ]; then log "Skip (not a file)"; fail_n=$((fail_n+1)); continue; fi

  dir="$(dirname "$in_path")"
  base="$(basename "$in_path")"
  stem="${base%.*}"

  OUTDIR_CHOSEN="$(choose_outdir "$dir")"
  out_path="${OUTDIR_CHOSEN}/${stem}-${SUFFIX}-${LIMIT_TAG}.wav"
  hidden_tmp="${OUTDIR_CHOSEN}/.${stem}-${SUFFIX}-${LIMIT_TAG}.wav.tmp"
  mid_path="$(mktemp -t waxon_mid_XXXXXX).wav"

  # Decide declip
  apply_declip=0
  file_clipped="?"
  case "$CLIP_REPAIR" in
    on)  apply_declip=1; file_clipped="FORCED" ;;
    off) apply_declip=0; file_clipped="OFF" ;;
    auto)
      clips="$(detect_clipped_samples "$in_path")"
      file_clipped="$clips"
      [ "$clips" -ge "$CLIP_THRESHOLD" ] && apply_declip=1
      ;;
  esac

  # Step 1: DC block → (optional) declip → HPF 20 Hz → monoL → resample (soxr)
  step1_af="highpass=f=${DC_BLOCK_HZ}"
  [ "$apply_declip" -eq 1 ] && step1_af="${step1_af},adeclip"
  step1_af="${step1_af},highpass=f=20,pan=1c|c0=c0,aresample=${SAMPLE_RATE}:resampler=soxr"

  log "Step 1 → ${mid_path}  (dc=${DC_BLOCK_HZ}Hz; declip=${apply_declip}; detected=${file_clipped})"
  if [ "$DRYRUN" -eq 0 ]; then
    if ! "$FFMPEG_BIN" -nostdin -hide_banner -loglevel error -y \
         -i "$in_path" -af "$step1_af" \
         -c:a pcm_s24le -ar ${SAMPLE_RATE} -ac 1 \
         "$mid_path"
    then
      log "Step 1 failed"; fail_n=$((fail_n+1)); rm -f "$mid_path" 2>/dev/null || true; continue
    fi
  fi

  # Step 2a: measure for two-pass loudnorm (TP=0.0; limiter is last ceiling)
  PASS1=""
  if [ "$DRYRUN" -eq 0 ]; then
    PASS1="$("$FFMPEG_BIN" -nostdin -hide_banner -v error -i "$mid_path" \
              -af "loudnorm=I=${LUFS_TARGET}:TP=0.0:LRA=11:print_format=json" \
              -f null - 2>&1 || true)"
  fi
  num_or_blank() { sed -nE "s/.*$1[[:space:]]*:[[:space:]]*\"([-+]?[0-9]+([.][0-9]+)?)\".*/\1/p" | head -n1; }
  I="$(printf '%s\n' "$PASS1" | num_or_blank '"input_i"')"
  TP="$(printf '%s\n' "$PASS1" | num_or_blank '"input_tp"')"
  LRA="$(printf '%s\n' "$PASS1" | num_or_blank '"input_lra"')"
  THRESH="$(printf '%s\n' "$PASS1" | num_or_blank '"input_thresh"')"
  OFFSET="$(printf '%s\n' "$PASS1" | num_or_blank '"target_offset"')"

  # Limiter (post-loudness)
  lim="alimiter=limit=$(to_amp "$LIMIT_DB"):attack=${ATTACK_MS}:release=${RELEASE_MS}:level=disabled"

  # Step 2b: loudnorm pass-2
  if [ -n "${I:-}" ] && [ -n "${TP:-}" ] && [ -n "${LRA:-}" ] && [ -n "${THRESH:-}" ]; then
    loudnorm_p2="loudnorm=I=${LUFS_TARGET}:TP=0.0:LRA=11:measured_I=${I}:measured_TP=${TP}:measured_LRA=${LRA}:measured_thresh=${THRESH}:linear=true:print_format=summary"
    [ -n "${OFFSET:-}" ] && loudnorm_p2="${loudnorm_p2}:offset=${OFFSET}"
  else
    loudnorm_p2="loudnorm=I=${LUFS_TARGET}:TP=0.0:LRA=11:linear=true:print_format=summary"
  fi

  # Step 2c: final AF chain (TP oversampling & dither)
  if [ "$TRUEPEAK" -eq 1 ]; then
    oversample=$(( SAMPLE_RATE * TP_OVERSAMPLE ))
    if [ "$DITHER" -eq 1 ]; then
      af="${loudnorm_p2},aresample=${oversample}:resampler=soxr,${lim},aresample=${SAMPLE_RATE}:resampler=soxr:dither_method=triangular_hp"
    else
      af="${loudnorm_p2},aresample=${oversample}:resampler=soxr,${lim},aresample=${SAMPLE_RATE}:resampler=soxr"
    fi
  else
    if [ "$DITHER" -eq 1 ]; then
      af="${loudnorm_p2},${lim},aresample=${SAMPLE_RATE}:resampler=soxr:dither_method=triangular_hp"
    else
      af="${loudnorm_p2},${lim},aresample=${SAMPLE_RATE}:resampler=soxr"
    fi
  fi

  # Step 3: render to hidden temp; capture loudnorm summary
  [ -f "$hidden_tmp" ] && rm -f "$hidden_tmp"
  pass2_log="$(mktemp -t waxon_pass2_XXXXXX)"
  log "Step 3 → ${hidden_tmp}"
  if [ "$DRYRUN" -eq 0 ]; then
    if "$FFMPEG_BIN" -nostdin -hide_banner -loglevel error -y \
         -i "$mid_path" -af "$af" \
         -c:a pcm_s24le -ar ${SAMPLE_RATE} -ac 1 \
         -f wav "$hidden_tmp" 2>"$pass2_log"
    then
      if [ ! -s "$hidden_tmp" ]; then
        log "Render produced no data"; tail -n 40 "$pass2_log" >>"$LOG"; fail_n=$((fail_n+1))
        rm -f "$pass2_log" "$mid_path" "$hidden_tmp" 2>/dev/null || true
        continue
      fi
      # Reveal with mv→cp fallback
      if mv -f "$hidden_tmp" "$out_path" 2>/dev/null || cp -f "$hidden_tmp" "$out_path"; then
        :
      else
        log "Reveal failed for: $out_path"; fail_n=$((fail_n+1))
        rm -f "$pass2_log" "$mid_path" "$hidden_tmp" 2>/dev/null || true
        continue
      fi
      if [ -s "$out_path" ]; then
        OUT_I="$(sed -nE 's/.*Output Integrated:[[:space:]]*([-+]?[0-9]+([.][0-9]+)?) .*/\1/p' "$pass2_log" | head -n1)"
        OUT_TP="$(sed -nE 's/.*Output True Peak:[[:space:]]*([-+]?[0-9]+([.][0-9]+)?) .*/\1/p' "$pass2_log" | head -n1)"
        log "✅ $out_path"
        log "    in ≈ $(nz "${I:-}") LUFS, TP $(nz "${TP:-}") dBTP → out ≈ $(nz "${OUT_I:-}") LUFS, TP $(nz "${OUT_TP:-}") dBTP"
        success_n=$((success_n+1))
      else
        log "Post-reveal check failed — missing: $out_path"
        fail_n=$((fail_n+1))
      fi
    else
      log "Render failed"; tail -n 40 "$pass2_log" >>"$LOG"; fail_n=$((fail_n+1))
    fi
    rm -f "$pass2_log" 2>/dev/null || true
  else
    log "(dry-run) would write: $out_path"
  fi

  rm -f "$mid_path" "$hidden_tmp" 2>/dev/null || true
done

log "Done: ${success_n} ok, ${fail_n} failed"
[ "$QUIET" -eq 1 ] || printf 'Log: %s\n' "$LOG"
[ "$fail_n" -gt 0 ] && exit 1 || exit 0
