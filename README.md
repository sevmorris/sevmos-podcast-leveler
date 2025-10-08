# WaxOn (CLI)
**Consistent, safe, and DAW-ready audio** — a fast, no-nonsense preprocessing step for podcast dialogue and VO.

WaxOn converts mixed-quality sources into clean, **24-bit mono WAV** files at a fixed **working loudness** of **−25 LUFS**, applies a **brick-wall limiter** at the end (no makeup gain), and handles practical safety steps (DC blocking, optional declip, true-peak oversampling, proper dither). The result is predictable, unclipped, and ready to drop into your DAW timeline.

> **Why −25 LUFS?**  
> It’s a *staging* level for editing — not a publishing target. It keeps tracks consistent while leaving wide headroom for EQ boosts and compression.  
> Integrated loudness is computed across the **entire** file (silence included) with standard gating, so the working level reflects real perceived loudness, not just speech-only moments.

---

## Features
- **24-bit PCM WAV, mono (left channel)** at **44.1 kHz** or **48 kHz**  
- **Two-pass** normalization to **−25 LUFS** (when possible)  
- **Limiter last** (brick-wall, no makeup gain) with configurable ceiling  
- **DC block** (gentle high-pass @ 20 Hz)  
- **Optional declip** repair (auto/on/off) before any gain changes  
- **True-peak oversampling** (4×/8×) and **TPDF high-pass dither**  
- Atomic writes (hidden temp → final file), robust logging, and clear errors

---

## Install

### Symlink install (recommended for development)
Keeps the global `waxon` command pointing at the script in this repo, so edits here take effect immediately.
```bash
./install.sh
# or force overwrite existing:
./install.sh --force
