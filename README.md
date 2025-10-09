# WaxOn — Interactive CLI (DAW-ready, fixed −25 LUFS, WAV only)

**WaxOn** is the **first, intermediate step** in your pipeline. It prepares **mono** program audio (channel 0) for DAW work by applying a **DC block**, optional **declipping**, **two-pass loudness normalization to −25 LUFS**, and a final **brickwall limiter** — with **true-peak oversampling** and optional **HP dither**. Outputs are **24-bit WAV mono** at **44.1k or 48k** with safe, atomic writes.

> Final delivery step? Use **WaxOff** → https://github.com/sevmorris/WaxOff

---

## Key points

- **Loudness**: fixed at **−25 LUFS** (two-pass `loudnorm`)
- **Format**: **WAV 24-bit mono** only (no FLAC/MP3 here)
- **Limiter ceiling**: selectable −1..−6 dBFS (default −1.0)
- **True-peak** oversampling (default on, ×4) and **HP dither**
- **DC block** first in chain; optional **declipping** (auto/on/off)
- **Atomic** hidden temp writes → visible file on success

---

## Install (general)

Prereq: `ffmpeg` in your PATH (macOS: `brew install ffmpeg`).

```bash
bash -c 'd=$(mktemp -d); git clone --depth=1 https://github.com/sevmorris/WaxOn "$d" && (cd "$d" && chmod +x waxon install.sh && ./install.sh) && rm -rf "$d"'
```

## Install (dev symlink)

```bash
bash -c 'd="$HOME/src/WaxOn"; [ -d "$d/.git" ] || git clone https://github.com/sevmorris/WaxOn "$d"; (cd "$d" && git pull --ff-only && chmod +x waxon install.sh && ./install.sh --dev)'
```

> Dev mode symlinks the `waxon` script so edits take effect immediately.

---

## Interactive usage

```bash
waxon *.wav
# Prompts for:
#   • Sample rate (44100 or 48000)
#   • Limiter ceiling (−1..−6 dBFS)
#   • Clip repair (auto / on / off)

# Notes:
#   • Loudness is fixed at −25 LUFS (two-pass loudnorm)
#   • Output format is fixed to 24-bit mono WAV
```

### Example

```bash
waxon ~/Audio_Raw/host_track.wav
# → Outputs: host_track-waxon-44k-1dB.wav (or 48k if chosen)
```

---

## Non-interactive usage (flags / env)

```bash
waxon --no-prompt -L -1.0 -s 48000 --clip-repair auto input.wav
# or
PROMPT=0 SAMPLE_RATE=44100 LIMIT_DB=-1.0 waxon input.wav
```

### Common flags

```
  -L, --limit-db <dB>      Limiter ceiling (default: -1.0)
  -s, --samplerate <hz>    44100 or 48000
  --truepeak <0|1>         True-peak oversampling (default: 1)
  --tp-oversample <N>      Oversample factor (default: 4)
  --dither <0|1>           Triangular HP dither (default: 1)
  --clip-repair <mode>     auto | 1 | 0   (default: auto)
  --clip-threshold <N>     Trigger threshold for auto (default: 1)
  --dc-block <Hz>          DC blocker high-pass (default: 20)
  -l, --log <path>         Log path (default: ~/Library/Logs/waxon_cli.log)
  --no-prompt              Skip interactive questions
  -q, --quiet              Reduce console output
  -n, --dry-run            Show actions without writing files
```

---

## Workflow

1) **WaxOn** → create clean, consistent mono WAVs ready for editing.  
2) **Edit / mix** in your DAW.  
3) **WaxOff** → final loudness (−18/−16 LUFS) + deliverables (WAV/MP3/FLAC).

---

## Update

Dev install:

```bash
cd ~/src/WaxOn && git pull && ./install.sh --dev
```

General reinstall:

```bash
bash -c 'd=$(mktemp -d); git clone --depth=1 https://github.com/sevmorris/WaxOn "$d" && (cd "$d" && ./install.sh) && rm -rf "$d"'
```

---

## Uninstall

```bash
./install.sh --uninstall
```

License: MIT
