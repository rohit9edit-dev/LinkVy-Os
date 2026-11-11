# LinkVy OS

My own custom Linux OS — built for my personal laptop, on top of Xubuntu (Ubuntu 24.04 LTS).

**Version:** v1.0 (in progress)
**Status:** Building — the ISO is made by GitHub Actions from this repo.

## What it is

LinkVy OS is Ubuntu/Xubuntu underneath, with my own look and my own apps on top:

- **Aurora Flow theme** — dark blue-purple aurora look everywhere; no Ubuntu orange anywhere
- **Brave only** — the only browser; Firefox and other browsers removed (still installable from the App Store if ever needed)
- **Terminal included** — real terminal, always there
- **Light apps only** — Files, Terminal, Settings, App Store, Music, Photos, Text Editor, Calculator preinstalled; the rest (VS Code, VLC, GIMP, LibreOffice, OBS, Inkscape, Telegram) comes from the App Store
- **Settings → System Update** — when v2 is ready, updating from Settings installs it; version becomes v2, files stay

## Build

The ISO is built in the cloud by GitHub Actions — see `.github/workflows/build.yml`.

To build: **Actions → Build LinkVy OS ISO → Run workflow**. The finished ISO is published as a GitHub Release.

## Install

1. Write the ISO to a USB pen drive (Fedora Media Writer / balenaEtcher)
2. Boot the laptop from the pen drive and test it live first (WiFi, Brave, App Store, speed)
3. Install on the SSD — **full wipe, no backup** (my decision)

Target laptop: HP Laptop 15q, AMD A9-9420 dual-core, 3.7 GB RAM, 128 GB SSD.

## Files

- `build-recipe-v1.md` — the full v1 build recipe (base, packages, theme, updater, test checklist)
- `.github/workflows/build.yml` — the cloud build workflow

Built with my personal AI agent Christy.
