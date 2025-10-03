# 🎙️ Sevmo's Podcast Leveler

A macOS Automator-friendly Bash script for podcast audio leveling using **FFmpeg**.  
It provides simple dialogs for choosing loudness, output formats, and MP3 bitrate, and ensures professional, broadcast-standard results with minimal setup.

---

## ✨ Features
- **Two-pass loudness normalization** via FFmpeg’s `loudnorm`
  - Targets −18 LUFS (recommended) or −16 LUFS
  - True Peak ceiling of −1.0 dBTP
- **Flexible output formats**
  - WAV (24-bit/44.1kHz)
  - MP3 (CBR 128, 160, or 192 kbps)
  - Or both
- **Interactive macOS dialogs**
  - Choose loudness target, output type, and MP3 bitrate
- **Notifications**
  - macOS alert and completion dialog when processing is finished
- **Robust handling**
  - Skips non-files or unwritable directories
  - Logs each run to `~/Library/Logs/sevmo_podcast_leveler.log`

---

## ⚠️ Important
You **must wait for the completion confirmation** before opening the generated files.  
Files may appear part-way through processing but are not finalized until the script confirms completion.

---

## 📦 Requirements
- macOS with [Homebrew](https://brew.sh/)
- FFmpeg installed:

```bash
brew install ffmpeg
```

---

## 🚀 Usage

### As a Script
1. Clone this repo and make the script executable:

   ```bash
   git clone https://github.com/sevmorris/podcast-leveler.git
   cd podcast-leveler
   chmod +x SevmosPodcastLeveler.sh
   ```

2. Run with one or more audio files:

   ```bash
   ./SevmosPodcastLeveler.sh track1.wav track2.wav
   ```

3. Follow the on-screen dialogs to choose:
   - Loudness target (−18 or −16 LUFS)
   - Output format (WAV, MP3, or both)
   - MP3 bitrate (128, 160, 192 kbps)

4. Wait for the **completion notification** before opening your output files.

---

### As an Automator App
- Import the script into an Automator "Run Shell Script" action.
- Save as an Application.
- Drag and drop audio files onto the Automator app for batch processing.

---

## 📂 Output
Files are written to the same directory as the input, with suffixes indicating loudness target:

```
input.wav   →  input-lev-18LUFS.wav
input.wav   →  input-lev-18LUFS.mp3
```

---

## 📝 License
MIT License — feel free to adapt for your own workflows.

---

## 🙌 Credits
Created by **Seven Morris (Sev)**  
for efficient podcast post-production on macOS.
