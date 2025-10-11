# WaxOn — Dialogue / Voice Preprocessing (Limiter‑Only CLI)
**Version v1.0.3 (CLI)** · Consistent, safe, and DAW‑ready audio

> This refactor aligns the **CLI** with the Automator droplet behavior: **no loudness normalization** and **no gain adjustments**. WaxOn now preserves program loudness and applies **only a brick‑wall limiter** at a user‑selected ceiling (no makeup gain).

## What It Does
WaxOn prepares raw recordings for editorial/mixing, without making creative level decisions. The chain is:

1. **DC/infra‑DC block** (gentle high‑pass; default 20 Hz)  
2. **Optional declip** (auto/force/off)  
3. **Hygiene high‑pass** (~20 Hz)  
4. **Mono selection** (channel 0)  
5. **Resample** to 44.1 kHz or 48 kHz (SOXR)  
6. **Brick‑wall limiter** at chosen ceiling (no makeup gain)  
7. **True‑peak oversampling** (4× default)  
8. **Final TPDF high‑pass dither**  
9. **24‑bit PCM WAV** output with **atomic reveal**

**No LUFS targeting. No auto‑leveling.**

## Install
Quick install to `~/bin/waxon` (symlink); clones repo into `~/WaxOn`:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sevmorris/WaxOn/main/install.sh)"
# or locally from this folder:
./install.sh
```

Verify:
```bash
waxon -h
```

## Usage
Basic:
```bash
waxon input1.wav input2.aif
```

Choose a limiter ceiling and sample rate (defaults: **−1.0 dBFS**, **48 kHz**):
```bash
waxon -l -2.0 -s 44100 *.wav
```

Non‑interactive (no prompts):
```bash
waxon --no-prompt -l -3.0 -s 48000 *.wav
```

### Flags
```
-s, --samplerate <Hz>    44100 | 48000 (default: 48000)
-l, --limit-db <dBFS>    Limiter ceiling (default: -1.0)
--attack <ms>            Limiter attack (default: 5)
--release <ms>           Limiter release (default: 50)
--truepeak <0|1>         True-peak oversampling on/off (default: 1)
--tp-oversample <N>      Oversampling factor (4 or 8; default: 4)
--dither <0|1>           Final-stage TPDF HP dither on/off (default: 1)
--clip-repair <mode>     auto | 1 (force) | 0 (off)  (default: auto)
--clip-threshold <n>     Min clipped-sample count to enable declip (default: 1)
--dc-block-hz <Hz>       DC/infra-DC high-pass corner (default: 20)
--outdir <dir>           Output dir (default: alongside source; falls back to ~/Music/WaxOn then ~/Desktop)
--suffix-base <tag>      Suffix token before limiter tag (default: "waxon")
--log <path>             Log file (default: ~/Library/Logs/waxon_cli_v1.0.3.log)
--no-prompt              Do not prompt when flags/env provide values
-h, --help               Show help
```

### Environment Variables
All flags have env equivalents, e.g.:
```
LIMIT_DB=-2.0 SAMPLE_RATE=44100 TRUEPEAK=1 TP_OVERSAMPLE=8 DITHER=1 waxon *.wav
```

## Output & Naming
- **24‑bit WAV**, mono (channel 0), at **44.1 kHz** or **48 kHz**.  
- Filenames include a rate token and limiter tag, e.g.:  
  `take-48kwaxon--1dB.wav`, `voice-44kwaxon--6dB.wav`

## Workflow
1. Run **WaxOn** to prep/limit for safe, unclipped import into the DAW.  
2. Perform editing, EQ, dynamics, and mix decisions in the DAW.  
3. Set distribution loudness later (e.g., with **WaxOff** at −18/−16 LUFS).

## Dependencies
- macOS / bash, `ffmpeg` & `ffprobe` (Homebrew recommended)
  ```bash
  brew install ffmpeg
  ```

## Troubleshooting
- **“ffmpeg not found”**: Add Homebrew bin dirs to your PATH or pass `FFMPEG_BIN` / `FFPROBE_BIN`.  
- **No output**: Check permissions; tool falls back to `~/Music/WaxOn` then `~/Desktop`.  
- **Limiter audible**: Try a higher ceiling (e.g., −2 dBFS) or adjust attack/release.  
- **True-peak overs still clip?** Raise oversample from 4× to 8×.

## License
MIT © Seven Morris
