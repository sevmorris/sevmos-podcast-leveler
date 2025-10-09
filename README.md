# WaxOn — Interactive CLI (−25 LUFS, WAV-only)

**WaxOn** is the first, “prep” step in the chain. It makes raw recordings **DAW-ready** by:
- DC-blocking and gentle high-pass at 20 Hz  
- Optional **auto declip** (detects clipped samples, repairs when needed)  
- **Two-pass** BS.1770/EBU R128 normalization to **−25 LUFS** (fixed)  
- Final **brickwall limiter** (you choose −1…−6 dBFS)  
- Optional true-peak oversampling + triangular HP dither  
- 24-bit **WAV mono (ch0)** at **44.1 k** or **48 k**  
- Hidden temp writes, atomic reveal  
- **Interactive file picker** if you start it with no filenames  
- **Live console output** mirrored to a log via `tee`

> **Companion:** After WaxOn, finish and deliver with **[WaxOff](https://github.com/sevmorris/WaxOff)** (stereo leveling to −18/−16 LUFS + WAV/MP3/FLAC).

## Requirements

```bash
brew install ffmpeg
```

## Install (user)

```bash
mkdir -p ~/bin && curl -fsSL https://raw.githubusercontent.com/sevmorris/WaxOn/refs/heads/main/waxon -o ~/bin/waxon && chmod +x ~/bin/waxon && case ":$PATH:" in *":$HOME/bin:"*) :;; *) echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc && export PATH="$HOME/bin:$PATH";; esac && echo "Installed waxon -> ~/bin/waxon"
```

## Dev setup

```bash
git clone https://github.com/sevmorris/WaxOn.git
cd WaxOn
chmod +x waxon
./waxon --help
```

## Quick start

```bash
waxon
waxon *.wav
waxon --no-prompt -L -1 --samplerate 48000 input.wav
```

## Workflow with WaxOff

1. **WaxOn** → prepare clean mono WAVs ready for editing.  
2. **Edit/mix** in DAW.  
3. **WaxOff** → finalize stereo loudness and formats (WAV/MP3/FLAC).
