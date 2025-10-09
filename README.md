# WaxOn — Dialogue / Voice Preprocessing Pipeline

**Purpose:**  
WaxOn prepares raw dialogue or voice tracks for mixing and editorial use. It ensures consistent, clean, and DAW‑ready audio without introducing any destructive processing. WaxOn is designed as a **pre‑mix prep tool**, not a final loudness normalizer.

---

## 🧩 What It Does

WaxOn applies a transparent preprocessing chain to each input file:

1. **DC offset removal** — ensures zero‑centered waveform.
2. **Clip repair** — optional interpolation for clipped samples.
3. **Gain leveling** — normalize to target LUFS (default −25 LUFS).
4. **Brick‑wall limiting** — safe peak control (default −1 dBTP).
5. **Dithering** — optional, for 16/24‑bit consistency.
6. **Mono conversion** — collapses to channel 0 (if desired).
7. **Output formatting** — 24‑bit WAV, FLAC, etc., 44.1 kHz or 48 kHz.

It **does not** perform compression, gating, EQ, or any tonal or dynamic enhancement. Its mission: *clean, safe, consistent* dialogue ready for editing.

---

## ⚙️ Install

Clones to your home directory and creates a symlink in `~/bin` (or `~/.local/bin`).

### Quick Install
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sevmorris/WaxOn/main/install.sh)"
```

### Verify
```bash
waxon -h
```

If `~/bin` isn’t in your PATH:
```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
```

### Uninstall (symlink only)
```bash
~/WaxOn/uninstall.sh
```

---

## 🧰 Usage

### Interactive Mode
```bash
waxon *.wav
```
Prompts for:
- Target LUFS (default −25)
- Sample rate (44.1 kHz or 48 kHz)
- Output mode (WAV, FLAC, etc.)
- Dither options

### Non‑Interactive / Scriptable
```bash
waxon --no-prompt -t -25 -s 48000 -m wav *.aif
```

Or via environment variables:
```bash
PROMPT=0 TARGET_I=-25 SAMPLE_RATE=48000 OUTMODE=wav waxon *.wav
```

### Common Flags
```
-t, --target <LUFS>     Target loudness (default −25)
-s, --samplerate <Hz>   44100 or 48000
-m, --mode <mode>       wav | flac | both | all
-o, --output-dir <dir>  Destination directory
--no-prompt             Skip questions
--dither-depth <bits>   16 or 24
-l, --log <path>        Log path (default ~/Library/Logs/waxon_cli.log)
```

---

## 🧾 Behavior Summary

| Step | Operation | Notes |
|------|------------|-------|
| 1 | DC Offset Removal | Always on |
| 2 | Clip Repair | `auto` by default |
| 3 | LUFS Normalization | −25 LUFS default |
| 4 | Brick‑Wall Limiting | −1 dBTP ceiling |
| 5 | Dithering | Optional |
| 6 | Mono Conversion | Channel 0 |
| 7 | Export | WAV/FLAC, 24‑bit, 44.1 kHz or 48 kHz |

---

## 🧱 Dependencies

- `bash`, `git`
- `ffmpeg` (`brew install ffmpeg`)

---

## 🔁 Typical Workflow

1. Record voice or dialogue (Zoom, mic, etc.).  
2. Run **WaxOn** → produces a clean, level, mono WAV.  
3. Import into DAW for creative editing and mixing.  
4. After final mix, run **WaxOff** to set broadcast LUFS (−18 / −16).

---

## 🧩 Troubleshooting

- **Too quiet/loud?** Input was already normalized; adjust target LUFS.  
- **PATH not found?** Ensure `~/bin` or `~/.local/bin` is on your PATH.  
- **Output clipping?** Check if input was hard‑limited; WaxOn will never boost past its true‑peak ceiling.  

---

## 📄 License

MIT License © Seven Morris
