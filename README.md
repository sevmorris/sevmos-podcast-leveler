# WaxOn (CLI)
**Consistent, safe, and DAW-ready audio** — a fast, no-nonsense preprocessing step for podcast dialogue and VO.

WaxOn converts mixed-quality sources into clean, **24-bit mono WAV** files at a fixed **−25 LUFS**, applies a **brick‑wall limiter**, and includes safety steps (DC blocking, clip repair, and dithering).

---

## 🧩 Install

This project installs by cloning to your home directory and creating a symlink in `~/bin` (or `~/.local/bin`).

### Quick install
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sevmorris/WaxOn/main/install.sh)"
```

### Verify installation
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

## 🧰 Behavior

- Clones repo to `~/WaxOn`
- Creates symlink `waxon` in `~/bin` (or `~/.local/bin`)
- Idempotent: can be re‑run to update both repo and symlink

---

## ⚙️ Dependencies

- `bash`, `git`
- `ffmpeg` (Homebrew install: `brew install ffmpeg`)

---

## 🧾 License

MIT License © Seven Morris
