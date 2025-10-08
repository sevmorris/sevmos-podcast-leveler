# WaxOn (CLI)
**Consistent, safe, and DAW-ready audio** — a fast, no-nonsense preprocessing step for podcast dialogue and VO.

WaxOn converts mixed-quality sources into clean, **24-bit mono WAV** files at a fixed **working loudness** of **−25 LUFS**, applies a **brick-wall limiter** at the end (no makeup gain), and handles practical safety steps (DC blocking, optional declip, true-peak oversampling, and proper dithering). The result is predictable, unclipped, and ready to drop into your DAW timeline.

> **Why −25 LUFS?**  
> It’s a *staging* level for editing — not a publishing target. It keeps tracks consistent while leaving wide headroom for EQ boosts and compression.  
> Loudness is measured across the **entire file (including silence)** using ITU-R BS.1770-4 gating, which ensures realistic perceived loudness without over-normalizing pauses or breath noise.

---

## Features
- **24-bit PCM WAV**, mono (left channel) at **44.1 kHz** or **48 kHz**
- **Two-pass normalization** to −25 LUFS (when possible)
- **Brick-wall limiter last**, with configurable ceiling (default −1.0 dBFS)
- **DC blocker** (gentle first-order high-pass @ 20 Hz)
- **Optional declip** repair (auto/on/off) before any gain changes
- **True-peak oversampling** (4×/8×) and **TPDF high-pass dither**
- **Atomic writes** (hidden temp → final file)
- Robust logging and clear macOS-native dialogs for droplet use

---

## Quick Install

### Easiest way (auto-installs Homebrew + FFmpeg if needed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sevmorris/WaxOn/main/install.sh)" -- --yes
```

### Minimal install (Homebrew + FFmpeg already installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sevmorris/WaxOn/main/install.sh)"
```

### Copy install instead of symlink (for CI or standalone use)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sevmorris/WaxOn/main/install.sh)" -- --copy --yes
```

### Manual (development mode)
Clone the repo and link the CLI directly:
```bash
git clone https://github.com/sevmorris/WaxOn.git
cd WaxOn
./install.sh
```

Uninstall at any time:
```bash
./uninstall.sh
```

---

## Verified Install
To confirm WaxOn is installed correctly:
```bash
waxon --version
```

Example output:
```
WaxOn v1.0 — Consistent, safe, and DAW-ready audio.
FFmpeg 8.0 detected.
Log file: /Users/you/Library/Logs/waxon_v1.0.log
```

Test with a sample file:
```bash
waxon ~/Desktop/test.mp3
```
You should see a `.wav` file appear next to your input:
```
test-44kwaxon--1dB.wav
```

---

## Usage

### Basic
```bash
waxon input.wav
waxon "Guest A.mp3" "Guest B.aif"
```

### Common options
```bash
waxon -r 48000 -c -1.5 *.wav           # 48 kHz, limiter ceiling −1.5 dBFS
waxon --repair auto --clip-threshold 2 input.wav
waxon --truepeak 1 --oversample 8 input.wav
waxon --outdir ~/Desktop/WaxOnOut *.mp3
```

### Full help
```
waxon [options] file1 [file2 ...]
Options:
  -r, --rate {44100|48000}     Output sample rate (default: 44100)
  -c, --ceiling DB             Limiter ceiling dBFS (default: -1.0)
  -p, --truepeak {1|0}         True-peak oversampling on/off (default: 1)
  -o, --oversample {4|8}       TP oversample factor (default: 4)
  -d, --dither {1|0}           Final-stage TPDF-HP dither on/off (default: 1)
  -R, --repair {auto|on|off}   Declip mode (default: auto)
  -T, --clip-threshold N       Enable declip when clipped samples ≥ N (default: 1)
  -b, --dc-block HZ            DC/infra high-pass corner (default: 20 Hz)
  -L, --lufs TARGET            Loudness target (default: −25 LUFS)
  -O, --outdir DIR             Output directory (default: alongside source)
  -S, --suffix TAG             Base filename tag (default: waxon)
  -l, --log PATH               Log path (default: ~/Library/Logs/waxon.log)
  -q, --quiet                  Suppress console output
  -n, --dry-run                Print actions, don’t render
  -h, --help                   Show help
```

---

## How It Works
1. **DC Block:** removes low-frequency drift or DC offset (20 Hz HPF).  
2. **Declip (optional):** attempts to reconstruct flattened peaks.  
3. **High-pass filter → mono downmix → resample.**  
4. **Loudness measurement** and two-pass normalization to −25 LUFS.  
5. **Brick-wall limiter** ensures peaks never exceed the chosen ceiling.  
6. **True-peak oversampling** (4× or 8×) prevents inter-sample overs.  
7. **Final dithering** adds noise shaping to preserve low-level detail.  
8. Output is written atomically — you’ll never see a partial file.

---

## Output
- Format: **24-bit WAV**, mono (channel 0)  
- Naming: `inputname-48kwaxon--1dB.wav`  
- Log file: `~/Library/Logs/waxon_v1.0.log`

---

## Requirements
- macOS (Intel or Apple Silicon)
- [Homebrew](https://brew.sh) (auto-installed if missing)
- [FFmpeg](https://ffmpeg.org) (auto-installed if missing)

Manual install:
```bash
brew install ffmpeg
```

---

## Development
WaxOn can run as both a **macOS droplet** and a **CLI tool**.  
The CLI version is maintained directly in this repo and installs globally via `install.sh`.

For contributors:
```bash
# Edit and test in-place
nano waxon.sh
# Run directly
./waxon.sh test.wav
```

---

## License
MIT License — © Seven Morris
