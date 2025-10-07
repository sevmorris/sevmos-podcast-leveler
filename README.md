# 🎧 Audio Droplet Scripts

Automation-friendly macOS shell scripts for fast, consistent podcast/audio processing using **FFmpeg**. Each script is designed to be dropped into an **Automator Application** so you can drag files onto it and get clean, leveled output with clear dialogs and logging.

This repo currently includes:

- **Sevmo’s Peak-Limited Mono WAV Maker** — mono conversion + two-pass loudness to **−25 LUFS** + true-peak-safe brickwall limiting.  
  File: `SevmosPeakLimitedMonoWavMaker.sh` (Version defaults to **v2.3.6**)

- **Sevmo’s Podcast Leveler** — two-pass loudness to **−18 LUFS** (or **−16 LUFS**) with output to **WAV**, **MP3** (CBR), or **both**.  
  File: `SevmosPodcastLeveler.sh` (Version banner indicates **v1.2**)

---

## 🚀 Quick Start (Automator App)

1. Open **Automator** → **New Document** → choose **Application**.  
2. Add **Run Shell Script**.  
   - *Pass input*: **as arguments**  
   - *Shell*: **/bin/sh** (or **/bin/bash** for the podcast leveler; either works on macOS)  
3. Paste the contents of the desired script.  
4. Save the app (e.g., `Mono WAV Maker.app` or `Podcast Leveler.app`).  
5. **Drag audio files** onto the app icon to process.  
6. Wait for the macOS completion dialog/notification before opening outputs.

> Both scripts write a session log to `~/Library/Logs/…` so you can diagnose issues easily.

---

## 📦 Requirements

- macOS (tested with Automator)
- **FFmpeg** (includes `ffprobe`) installed and on `PATH`  
  Recommended via Homebrew:
  ```bash
  brew install ffmpeg
  ```

---

## 🟣 Sevmo’s Peak-Limited Mono WAV Maker (`SevmosPeakLimitedMonoWavMaker.sh`)

### Purpose
Convert any source to **24-bit mono (channel 0)** at **44.1 kHz** or **48 kHz**, normalize program loudness to **−25 LUFS** using **two-pass `loudnorm`**, then apply a **brickwall peak limiter** with **true-peak protection** (4× oversampling, on by default). Outputs are written as hidden temp files first and **atomically revealed** when done — so you never see partials.

### Key features
- ✅ **Two-pass** EBU R128 loudness normalization (target **−25 LUFS**)
- ✅ **True-peak limiting** (ENABLED by default; **4× oversampling**)
- ✅ **Limiter ceiling menu** (−1 dB to −6 dB) or fixed via env var
- ✅ **Sample-rate menu** (44.1 kHz / 48 kHz)
- ✅ **Hidden temp → atomic reveal** of final WAV
- ✅ **Verbose completion dialog** with per-file stats (in/out LUFS & dBTP)
- ✅ **macOS notifications** with a concise summary

### Defaults (from the script)
- Version banner: `v2.3.6`
- Loudness target: `LUFS_TARGET=-25`
- True-peak limiting: `TRUEPEAK=1` (enabled)
- Limiter: `alimiter` with `ATTACK_MS=5`, `RELEASE_MS=50`
- Limiter ceiling (if not prompted): `LIMIT_DB=-1.0`  
  *(Note: the line in the script shows a leading space; both `" -1.0"` and `"-1.0"` behave the same.)*
- Filename suffix base: `SUFFIX_BASE=k24_mono0_lim`
- Completion sound: `SOUND=/System/Library/Sounds/Glass.aiff` (optional)

### What you’ll see
- **Menu 1:** choose **44.1 kHz** or **48 kHz**
- **Menu 2:** choose limiter ceiling (−1 dB … −6 dB) *if* `PROMPT_LIMIT=1`
- **Start dialog + Notification** (processing may take a few minutes)
- **Completion dialog** with human-friendly narrative + per-file stats
- Outputs next to source as:
  ```
  <source-stem>-<44k|48k>k24_mono0_lim-<ceilingTag>.wav
  # e.g. Interview-44kk24_mono0_lim--1dB.wav
  ```

### Environment variables you can set
| Variable       | Default                         | What it does |
|----------------|----------------------------------|--------------|
| `VERSION`      | `v2.3.6`                         | UI/log banner |
| `LUFS_TARGET`  | `-25`                            | Integrated loudness target (LUFS) |
| `PROMPT_LIMIT` | `1`                              | `1` shows the ceiling picker; `0` uses `LIMIT_DB` silently |
| `LIMIT_DB`     | `-1.0`                           | Limiter ceiling (dBFS) |
| `ATTACK_MS`    | `5`                              | Limiter attack (ms) |
| `RELEASE_MS`   | `50`                             | Limiter release (ms) |
| `TRUEPEAK`     | `1`                              | `1` enables true-peak (4×); `0` disables |
| `SUFFIX_BASE`  | `k24_mono0_lim`                  | Forms the output suffix before the dB tag |
| `SOUND`        | `/System/Library/Sounds/Glass.aiff` | Optional success sound |
| `PATH`         | `/opt/homebrew/bin:…`           | Ensure `ffmpeg`/`ffprobe` resolve |

### Logging
- Log file: `~/Library/Logs/sevmo_mono_limiter_v2.3.6.log`  
  *(Filename reflects the `VERSION` you run with.)*

---

## 🟢 Sevmo’s Podcast Leveler (`SevmosPodcastLeveler.sh`)

### Purpose
Two-pass EBU R128 loudness normalization to **−18 LUFS** (recommended) **or −16 LUFS**, then output **WAV** (24-bit/44.1 kHz), **MP3** (CBR **128/160/192 kbps**), or **both** — with simple macOS dialogs.

### Key features
- ✅ Two-pass `loudnorm` to **−18 LUFS** (or **−16 LUFS**)
- ✅ True Peak ceiling **−1.0 dBTP**
- ✅ Output formats: **WAV**, **MP3**, or **Both**
- ✅ Interactive dialogs for **target**, **output type**, and **MP3 bitrate**
- ✅ Per-run logging to `~/Library/Logs/sevmo_podcast_leveler.log`

### What you’ll see
- **Target menu:** −18 LUFS (default) or −16 LUFS
- **Output menu:** WAV / MP3 / Both
- **Bit-rate menu (if MP3):** 128k / 160k / 192k
- Filenames like:
  ```
  <stem>-lev-18LUFS.wav
  <stem>-lev-18LUFS.mp3
  ```

> The podcast leveler prints **VERSION v1.2** in the header and follows the flow noted at the top of the script.

---

## 🧪 Verifying Loudness

You can quickly verify an output’s integrated loudness and true peak with FFmpeg:

```bash
ffmpeg -i "Output.wav" -af "loudnorm=I=-25:TP=-1.0:LRA=11:print_format=summary" -f null -
# For podcast leveler outputs:
# ffmpeg -i "Output.wav" -af "loudnorm=I=-18:TP=-1.0:LRA=11:print_format=summary" -f null -
```

---

## 🛠️ Troubleshooting

- **FFmpeg not found**
  ```bash
  brew install ffmpeg
  which ffmpeg
  ffmpeg -version
  ```
- **Gain jump at the start**  
  Use the current scripts — both are **two-pass** loudnorm to avoid single-pass “hot start” behavior (especially on MP3 sources).
- **Hidden temp rename error** (Mono WAV Maker)  
  Ensure the destination folder is writable and has enough space. The script writes `.<name>.wav.tmp` then renames atomically.
- **No dialogs appear**  
  Make sure the Automator **Run Shell Script** action is set to **Pass input: as arguments**.
- **True-peak status unclear**  
  Mono WAV Maker (v2.3.6) shows true-peak lines explicitly in the final dialog. It’s **ENABLED** at **4×** oversampling by default.

---

## 🧷 Repo Notes

- `.gitignore` is present to avoid committing transient/macOS files.
- The repo includes a `.git` folder in the archive you shared; if you extracted over an existing repo, double-check that your intended remote and history are correct.

---

## 🗒️ Changelog (high level)

- **Mono WAV Maker**
  - **v2.3.6** — Human-friendly completion dialog; true-peak spelled out; oversampling line only when enabled. Two-pass −25 LUFS; hidden temp → atomic reveal; per-file stats; macOS notifications.
  - **v2.3.1–v2.3.5** — Two-pass loudnorm added to eliminate “hot start”; clarified notifications/dialog text.
  - **v2.2** — Original stable baseline (menus, mono ch0, limiter).

- **Podcast Leveler**
  - **v1.2** — Two-pass −18/−16 LUFS, WAV/MP3 outputs, dialogs for target/output/bitrate, logging.

---

## 📜 License

These scripts are provided as-is; use at your own discretion. **FFmpeg** is licensed under LGPL/GPL — consult FFmpeg’s license for details.
