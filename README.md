# WaxOn (CLI)

**Consistent, safe, and DAW‑ready audio.**

WaxOn converts mixed‑quality sources into 24‑bit **mono** WAV at **44.1 kHz** or **48 kHz**, applies a **gentle DC blocker** at the start of the chain, and performs **brick‑wall peak limiting with no makeup gain**. Output files are written atomically by rendering to a hidden temporary file and revealing the final file only after a successful render.

---

## Features

- **Mono from a single channel**: choose **Left** or **Right** (no summing).
- **Sample‑rate conversion**: **44.1 kHz** or **48 kHz** via SOXR.
- **Limiter‑only** workflow: set the ceiling (−1 to −6 dBFS).
- Configurable **attack**/**release** (defaults 5/50 ms).
- Optional **true‑peak style** oversampling path (×4 by default).
- Optional **HP‑TPDF dither** on the final downsample.
- **Atomic writes** using hidden dotfiles.
- **Logging** to `~/Library/Logs/waxon_cli.log` (or a custom path).

---

## Install

```bash
./install.sh
```

Installs a `waxon` executable into `~/bin` (or `~/.local/bin`). Ensure that directory is on your `PATH`.

Uninstall with:

```bash
./uninstall.sh
```

---

## Usage

Interactive (prompts for sample rate, channel, limiter ceiling):

```bash
waxon input1.wav input2.wav
```

Non‑interactive examples:

```bash
waxon --no-prompt -s 48000 -c right -l -3 input.wav

# or with environment variables
PROMPT=0 SAMPLE_RATE=48000 CHANNEL=right LIMIT_DB=-3 waxon input.wav
```

### Options

```
--no-prompt               Run non‑interactively (or set PROMPT=0).
-s, --samplerate <Hz>     44100 or 48000.
-c, --channel <ch>        left | right | 0 | 1  (default: left).
-l, --limit <dB>          Limiter ceiling in dBFS (e.g., -1, -2, -3 ...).
--attack <ms>             Limiter attack (default 5).
--release <ms>            Limiter release (default 50).
--truepeak <0|1>          Enable oversampled path (default 1).
--oversample <N>          Oversample factor (default 4).
--dither <0|1>            TPDF‑HP dither on final render (default 1).
--dc <Hz>                 High‑pass cutoff for DC blocking (default 20).
-o, --outdir <dir>        Destination directory (default: alongside source).
--log <path>              Log path (default: ~/Library/Logs/waxon_cli.log).
-h, --help                Show help.
```

All options are also available as environment variables (`SAMPLE_RATE`, `CHANNEL`, `LIMIT_DB`, `TRUEPEAK`, `TP_OVERSAMPLE`, `DITHER`, `DC_BLOCK_HZ`, `OUTDIR`, `LOG`, etc.).

---

## Notes

- The limiter **does not add makeup gain**; it only prevents peaks from exceeding the ceiling.
- If your source is quiet, this process will **not** boost it.
- Output files are **24‑bit WAV mono** at the selected sample rate.

---

## Dependencies

- **ffmpeg** and **ffprobe**
- Standard POSIX tools (`bash`, `sed`, `awk`, `mktemp`)
