# WaxOn — Pre‑Edit Audio Preprocessor

Purpose: WaxOn prepares raw recordings for editing by rendering a clean, DAW‑ready 24‑bit mono WAV from any input. It applies a DC block, optional declip repair, resamples to 44.1 kHz or 48 kHz, and finishes with a true‑peak brickwall limiter (user‑selectable ceiling: −1 to −6 dBFS). No loudness normalization is performed in WaxOn.

> Use **WaxOff** after editing to set final program loudness and export deliverables.

---

## Features

- DC blocker (gentle high‑pass; default 20 Hz)  
- Optional clip repair (`adeclip`) in auto / on / off modes  
- Limiter‑only final stage (attack/release, true‑peak oversampling)  
- TP oversampling (×4 by default), optional triangular HP dither  
- 24‑bit PCM mono (channel 0), 44.1 kHz (default) or 48 kHz  
- Interactive prompts or fully scriptable via flags/env  
- Atomic writes (hidden temp then reveal)  
- Minimal dependencies: `bash`, `ffmpeg`

---

## Install (one‑liner)

Installs to `~/WaxOn` and symlinks `waxon` into `~/bin` (or `~/.local/bin`):

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sevmorris/WaxOn/main/install.sh)"
```

> Make sure your shell can find `~/bin`:  
>  
> ```sh
> # zsh
> echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc  
> # bash (macOS / Linux)
> echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bash_profile
> ```

---

## Usage

### Interactive

```sh
waxon *.wav
```

You’ll be prompted for:

- Sample rate: 44.1 kHz or 48 kHz  
- Limiter ceiling: −1..−6 dBFS  
- Clip repair: auto / on / off  
- Confirmation of full selections

### Non‑interactive

```sh
# with flags
waxon --no-prompt -s 48000 --limit-db -2.0 --clip-repair auto *.mp3

# or via environment variables
WAXON_PROMPT=0 SAMPLE_RATE=48000 LIMIT_DB=-2.0 CLIP_REPAIR=auto waxon *.mp3
```

#### Common flags

- `-s, --samplerate <Hz>`: `44100` | `48000` (default: `44100`)  
- `-l, --limit-db <dB>`: limiter ceiling (default `-1.0`; range `-1..-6`)  
- `--truepeak <0|1>`: enable true‑peak oversampling (default `1`)  
- `--tp-oversample <N>`: oversample factor (default `4`)  
- `--dither <0|1>`: triangular HP dither on final resample (default `1`)  
- `--clip-repair <mode>`: `auto` | `1` (on) | `0` (off) (default `auto`)  
- `--clip-threshold <N>`: min clipped‑sample count to trigger in auto (default `1`)  
- `--dc-block-hz <Hz>`: DC blocker high‑pass corner (default `20`)  
- `--no-prompt`: skip interactive prompts  
- `-q, --quiet`: less console output  
- `-n, --dry-run`: show actions without writing  

---

## Typical Workflow

1. **WaxOn** → produce a safe, unclipped mono WAV for editing  
2. Edit in your DAW (comp, cut, repair, mix)  
3. **WaxOff** → set final program loudness, export deliverables  

---

## License

MIT © Seven Morris

---

## About

WaxOn is a minimal, robust preprocessing tool to get your recordings into a clean, consistent starting point for editing.
