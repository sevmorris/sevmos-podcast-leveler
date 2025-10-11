# WaxOn (CLI) — Limiter‑Only Preprocessor v1.4

**Consistent, safe, and DAW‑ready audio** — converts mixed‑quality sources into 24‑bit **mono** WAV at **44.1 or 48 kHz**, applies a **DC blocker** and a **brick‑wall peak limiter** (no makeup gain). Optional true‑peak‑style oversampling and HP‑TPDF dither. Uses **hidden temp files** until completion for atomic writes.

> This CLI matches the current **WaxOn droplet v1.4** behavior: **no loudness normalization** (no −25 LUFS stage), **mono from Left or Right only**, limiter‑only ceiling (−1…−6 dBFS), and a gentle DC block at the start of the chain.

---

## What it does

1. **DC offset removal** via gentle high‑pass (default **20 Hz**).
2. **Channel select to mono**: choose **Left** or **Right** only (no summing).
3. **Sample‑rate convert** to **44.1 kHz** or **48 kHz** using SOXR.
4. **Limiter‑only render** using `alimiter` with **no makeup gain**.
   - Ceiling selectable: **−1 to −6 dBFS**.
   - **Attack/Release** (defaults **5/50 ms**).
   - **True‑peak path** (default on): oversamples (×4 default), limits, then downsamples.
   - **HP‑TPDF dither** on final downsample (default on).
5. **Formats**: **24‑bit WAV mono** output.
6. **Atomic writes**: render to a **dotfile** first, then reveal on success.
7. **Logging**: `~/Library/Logs/waxon_cli_v1.4.log`

---

## Install (minimal)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sevmorris/WaxOn/main/install.sh)"
# or clone this repo and run:
./install.sh
```

The installer will place a `waxon` executable into `~/bin` (or `~/.local/bin`) and print PATH hints.

Uninstall the symlinked binary with:

```bash
./uninstall.sh
```

---

## Usage

Interactive (default):

```bash
waxon *.wav
```

Prompts for **sample rate**, **mono channel (L/R)**, and optionally **limiter ceiling**.

Non‑interactive / scriptable:

```bash
waxon --no-prompt -s 48000 -c right -l -3 input.wav
# or via env:
PROMPT=0 SAMPLE_RATE=48000 CHANNEL=right LIMIT_DB=-3 waxon input.wav
```

### Common options

- `--no-prompt` — disable interactive prompts (or `PROMPT=0`).
- `-s, --samplerate <Hz>` — **44100** or **48000**.
- `-c, --channel <left|right|0|1>` — pick **Left** or **Right** channel for mono.
- `-l, --limit <dB>` — limiter ceiling in **dBFS** (`-1 .. -6`).
- `--attack <ms>`, `--release <ms>` — default **5/50 ms**.
- `--truepeak <0|1>` — enable oversampled path (**default 1**).
- `--oversample <N>` — oversample factor (**4** default).
- `--dither <0|1>` — enable HP‑TPDF on downsample (**default 1**).
- `--dc <Hz>` — HP cutoff (**20** default).
- `-o, --outdir <dir>` — destination; default beside source, fallback to `~/Music/WaxOn`.
- `--log <path>` — custom log file path.

---

## Dependencies

- **ffmpeg** and **ffprobe** (`brew install ffmpeg`)
- `bash`, `sed`, `awk`, `mktemp` (macOS default)

---

## Notes & tips

- The limiter runs **without makeup gain**; it only prevents peaks from exceeding the ceiling.
- If your source is already very quiet, this stage **won’t boost it**—that’s by design.
- For final delivery loudness (e.g., −18 / −16 LUFS), use your **WaxOff** pipeline after editing.

---

## License

MIT © Seven Morris
