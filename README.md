# Sevmo's Podcast Leveler

A macOS Automator-friendly Bash script for leveling podcast audio with FFmpeg.

## Features
- Two-pass `loudnorm` normalization (−18 or −16 LUFS, −1 dBTP ceiling)
- Output as WAV (24-bit/44.1k), MP3 (CBR 128/160/192), or both
- Simple dialogs for options
- macOS notifications when complete

⚠️ **Important:** Wait for the completion confirmation before opening generated files.
