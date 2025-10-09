# WaxOn — Interactive CLI (DAW-ready)

**WaxOn** is the **first, intermediate step** in your editing pipeline. It prepares **mono** program audio (channel 0) for DAW work by applying a DC block, optional declipping, loudness normalization, and a brickwall limiter with true-peak oversampling — all with safe, atomic writes. It’s interactive by default and mirrors WaxOff’s UX.

> Looking for the **final delivery** step? Use **WaxOff** → https://github.com/sevmorris/WaxOff

- **Loudness target** (two-pass): default **−25 LUFS** (option for −23 LUFS)
- **Limiter ceiling**: default **−1.0 dBFS** (adjustable −1..−6 dB)
- **True-peak** oversampling (default on, ×4) and **HP dither**
- **Outputs**: **WAV 24-bit mono** (44.1k/48k), optional **FLAC**
- Atomic hidden-temp writes; succinct per-file loudness summary
- Installs to **`~/bin`** (fallback **`~/.local/bin`**) — same location as **WaxOff**

---

## Install

**Prereq:** `ffmpeg` in your PATH (macOS: `brew install ffmpeg`).

**One-liner (general install):**
```bash
bash -c 'd=$(mktemp -d); git clone --depth=1 https://github.com/sevmorris/WaxOn "$d" && (cd "$d" && chmod +x waxon install.sh && ./install.sh) && rm -rf "$d"'
```

**One-liner (dev symlink install):**
```bash
bash -c 'd="$HOME/src/WaxOn"; [ -d "$d/.git" ] || git clone https://github.com/sevmorris/WaxOn "$d"; (cd "$d" && git pull --ff-only && chmod +x waxon install.sh && ./install.sh --dev)'
```

> The dev one-liner clones (or updates) to `~/src/WaxOn` and symlinks `waxon` into your user bin dir so edits take effect immediately.

---

## Interactive usage

```bash
waxon *.wav
# Prompts for:
#   • Target LUFS (−25 / −23)
#   • Output mode (wav | flac | both)
#   • FLAC compression level (if flac is included)
#   • Sample rate (44100 or 48000)
#   • Limiter ceiling (−1..−6 dBFS)
#   • Clip repair (auto / on / off)
```

### Example

```bash
waxon ~/Audio_Raw/host_track.wav
# → Outputs host_track-44k24_waxon-1dB.wav to the same directory
```

---

## Non-interactive usage (flags / env)

```bash
waxon --no-prompt -i -25 -L -1.0 -s 48000 -m both --clip-repair auto *.aif
# or
PROMPT=0 LUFS_TARGET=-23 OUTMODE=wav SAMPLE_RATE=44100 waxon *.wav
```

### Common options

```
  -i, --lufs <I>           Target integrated LUFS (default: -25)
  -L, --limit-db <dB>      Limiter ceiling in dBFS (default: -1.0)
  -s, --samplerate <hz>    44100 or 48000
  -m, --mode <mode>        wav | flac | both (default: wav)
  --flac-level <N>         0..12 compression (default: 8)

  --truepeak <0|1>         Enable true-peak oversampling (default: 1)
  --tp-oversample <N>      Oversample factor (default: 4)
  --dither <0|1>           Triangular HP dither (default: 1)

  --clip-repair <mode>     auto | 1 | 0   (default: auto)
  --clip-threshold <N>     Minimum clipped-sample count to trigger (default: 1)
  --dc-block <Hz>          DC blocker high-pass frequency (default: 20)

  -l, --log <path>         Log file path (default: ~/Library/Logs/waxon_cli.log)
  --no-prompt              Skip interactive questions
  -q, --quiet              Reduce console output
  -n, --dry-run            Show actions without writing files
```

---

## Updating

To pull the latest version (dev install only):
```bash
cd ~/src/WaxOn && git pull && ./install.sh --dev
```

To reinstall the general version:
```bash
bash -c 'd=$(mktemp -d); git clone --depth=1 https://github.com/sevmorris/WaxOn "$d" && (cd "$d" && ./install.sh) && rm -rf "$d"'
```

---

## Recommended workflow

1) **WaxOn** on raw takes → clean, consistent mono WAV/FLAC.  
2) **Edit / mix** in your DAW.  
3) **WaxOff** for final loudness (−18/−16 LUFS) and deliverables (WAV/MP3/FLAC). → https://github.com/sevmorris/WaxOff

---

## Uninstall

```bash
./install.sh --uninstall
```

License: MIT
