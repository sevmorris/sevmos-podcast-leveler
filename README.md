# WaxOn — Pre‑Edit Audio Preprocessor

**Limiter‑only, no loudness normalization.** WaxOn prepares raw recordings for editing by rendering a clean, DAW‑ready 24‑bit mono WAV from any input. It applies a DC block, optional clip repair, resamples to 44.1 kHz or 48 kHz, and finishes with a brick‑wall peak limiter (user‑selectable ceiling −1 to −6 dBFS).

> Use **WaxOff** *after editing* to set final program loudness and export deliverables.

---

## Install (one‑liner)

Installs to `~/WaxOn` and symlinks `waxon` into `~/bin` (or `~/.local/bin`):

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sevmorris/WaxOn/main/install.sh)"
```

If a proxy/CDN is serving a cached copy, try this cache‑busting variant:

```sh
/bin/bash -c "$(curl -fsSL "https://raw.githubusercontent.com/sevmorris/WaxOn/main/install.sh?nocache=$(date +%s)")"
```

Ensure your shell can find `~/bin` (or `~/.local/bin`):
```sh
# zsh
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && exec zsh
# bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bash_profile && source ~/.bash_profile
```

---

## Usage

### Interactive

```sh
waxon *.wav
```
You’ll be prompted for:
- Sample rate: 44.1 kHz or 48 kHz
- Limiter ceiling: −1..−6 dBFS
- Channel: Left or Right (mono render from that channel)
- Clip repair: on / off

### Non‑interactive

```sh
# flags
waxon --no-prompt -s 48000 --limit-db -2.0 --channel L --clip-repair on *.mp3

# envs
WAXON_PROMPT=0 SAMPLE_RATE=48000 LIMIT_DB=-2.0 CHANNEL=L CLIP_REPAIR=on waxon *.mp3
```

#### Common flags
- `-s, --samplerate <Hz>`: `44100` | `48000` (default: `44100`)
- `-l, --limit-db <dB>`: limiter ceiling (default `-1.0`; range `-1..-6`)
- `-c, --channel <L|R>`: choose source channel for mono render (default `L`)
- `--dc-block-hz <Hz>`: DC blocker high‑pass corner (default `20`)
- `--clip-repair <on|off>`: enable/disable clip repair (default `off`)
- `--dither <0|1>`: triangular HP dither on final resample (default `1`)
- `--no-prompt`: skip interactive prompts
- `-n, --dry-run`: show actions without writing
- `-q, --quiet`: less console output
- `-h, --help`: help
- `--version`: print version

---

## Typical Workflow

1. **WaxOn** → produce a safe, unclipped mono WAV for editing  
2. Edit in your DAW (comp, cut, repair, mix)  
3. **WaxOff** → set final program loudness, export deliverables

---

## Troubleshooting

- **`BASH_SOURCE[0]: unbound variable`** — You pulled a cached installer. Re‑run the cache‑busting one‑liner above.
- **`waxon` not found** — Add `~/bin` (or `~/.local/bin`) to your PATH (see Install section).
- **`ffmpeg: command not found`** — Install ffmpeg first (macOS: `brew install ffmpeg`).

---

## License

MIT © Seven Morris
