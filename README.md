# WaxOn (CLI)
**Consistent, safe, and DAW-ready audio** — a fast, no-nonsense preprocessing step for podcast dialogue and VO.

WaxOn converts mixed-quality recordings into clean, **24-bit mono WAV** files at a fixed **working loudness** of **−25 LUFS**, applies a **brick-wall limiter** (no makeup gain), and performs essential safety cleanup (DC blocking, optional declip repair, true-peak oversampling, proper dithering).  
The result is predictable, unclipped, and ready to drop into your DAW timeline.

> **Why −25 LUFS?**  
> It’s a *working* loudness target for editing — not a mastering level.  
> At this stage you want headroom, not maximum volume.  
> −25 LUFS provides a consistent baseline that keeps different voices comparable while leaving space for EQ boosts, compression, and mastering downstream.  
> Loudness normalization follows the EBU R128 algorithm (integrated LUFS, gated), so silences and natural pauses are factored into the final level — giving you a realistic “real-world” loudness reading.

---

## Features

- **24-bit PCM WAV, mono (left channel)** at **44.1 kHz** or **48 kHz**
- **Two-pass normalization** to **−25 LUFS** when possible (single-pass fallback)
- **Brick-wall limiter** (no makeup gain) with configurable ceiling
- **DC blocker** (gentle 20 Hz high-pass to remove offsets)
- **Optional declip** repair (auto/on/off) before gain adjustment
- **True-peak oversampling** (4× / 8×) + **TPDF high-pass dither**
- **Atomic writes:** hidden temp file until complete (no half-written renders)
- **Detailed logging** at `~/Library/Logs/waxon_v*.log`

---

## Installation

WaxOn requires **macOS** and **FFmpeg** (installed automatically if missing).  
Two install options are available:

### 🧩 Minimal user install
Downloads the latest `waxon.sh` and installs it globally.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sevmorris/WaxOn/main/install.sh)"
```

After installation, you can run WaxOn from anywhere:
```bash
waxon input.wav
```

---

### 🧑‍💻 Developer install (clone + symlink)
For contributors or power users who want the local repo for quick updates.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sevmorris/WaxOn/main/install.sh)" -- --dev
```

This clones the repo to:
```
~/.local/share/waxon/
```

…and creates a symlink in `/usr/local/bin` or `/opt/homebrew/bin`.  
To update later:
```bash
cd ~/.local/share/waxon && git pull
```

To uninstall:
```bash
sudo rm -f /usr/local/bin/waxon
rm -rf ~/.local/share/waxon
```

---

## Usage

```bash
waxon [file1] [file2] ...
```

Each file is converted and leveled individually.  
You’ll be prompted to select a sample rate (44.1 kHz / 48 kHz) and limiter ceiling (−1 dBFS … −6 dBFS).  

Output files are written next to the originals:

```
example.wav     → example-44kwaxon--1dB.wav
```

---

## Output summary

| Stage | Description |
|--------|-------------|
| **Input** | Any PCM, MP3, AAC, AIF, etc. |
| **DC block** | Removes low-frequency offset and sub-20 Hz rumble |
| **Auto declip** | Detects clipped samples and repairs if needed |
| **Leveling** | Normalizes to −25 LUFS (two-pass when possible) |
| **Limiter** | Brick-wall peak limiter with adjustable ceiling |
| **Dither** | TPDF high-pass (only on down-conversion) |
| **Output** | 24-bit mono WAV, named with sample rate and limit tag |

---

## Logs

All sessions write a detailed log file under:
```
~/Library/Logs/waxon_v1.x.log
```
These logs include ffmpeg filters used, LUFS readings, limiter activity, and any error messages.

---

## Requirements

- **macOS 10.15 or later**
- **FFmpeg 8.0 +**
- **Homebrew** (installed automatically if missing)

---

## Versioning

Current: **WaxOn v1.x — initial CLI release**

Future versions may add:
- Batch-mode options (non-interactive)
- Preset profiles for specific workflows
- Cross-platform Linux support

---

## License
MIT License © 2025 Seven Morris

---

## Credits
Built for podcasters, editors, and post engineers who want **clean, consistent, DAW-ready dialogue without the guesswork**.
