# WaxOn — Interactive CLI (DAW-ready)

**WaxOn** is the *first, intermediate step* in your editing pipeline. It prepares **mono** program audio (channel 0) for DAW work by applying a DC block, optional declipping, loudness normalization, and a brickwall limiter with true-peak oversampling — all with safe, atomic writes. It’s interactive by default and mirrors WaxOff’s UX.

> Looking for the **final delivery** step? See **[WaxOff](https://github.com/sevmorris/WaxOff)** — the stereo podcast leveler with WAV/MP3/FLAC outputs.

- **Loudness target** (two-pass): default **−25 LUFS** (option for −23 LUFS)
- **Limiter ceiling**: default **−1.0 dBFS** (adjustable −1..−6 dB)
- **True-peak** oversampling (default on, ×4) and **HP dither**
- **Outputs**: **WAV 24-bit mono** (44.1k/48k), optional **FLAC**; filenames include sample-rate and ceiling
- Installs to **`~/bin`** (or `~/.local/bin`), same location as **WaxOff**

## Install

```bash
brew install ffmpeg
chmod +x waxon
./install.sh            # copy install to ~/bin (or ~/.local/bin)
./install.sh --dev      # symlink install (development mode)
./install.sh --prefix "$HOME/.dotfiles/bin" --dev   # custom prefix + dev
```

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

## Non-interactive (flags / env)

```bash
waxon --no-prompt -i -25 -L -1.0 -s 48000 -m both --clip-repair auto *.aif
# or
PROMPT=0 LUFS_TARGET=-23 OUTMODE=wav SAMPLE_RATE=44100 waxon *.wav
```

### Options (common ones)

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

## Workflow: WaxOn → edit in DAW → WaxOff
1. **WaxOn** on the raw take(s) to produce clean, consistent mono WAVs/FLACs.
2. **Edit/mix** in your DAW.
3. **WaxOff** for final loudness to −18/−16 LUFS and deliverables (WAV/MP3/FLAC).

**Next:** [WaxOff on GitHub](https://github.com/sevmorris/WaxOff)

## Uninstall

```bash
./install.sh --uninstall
```

License: MIT
