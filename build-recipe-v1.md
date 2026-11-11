# LinkVy OS v1.0 — Build Recipe

**Status: IN PROGRESS — GitHub connected, repo `rohit9edit-dev/LinkVy-Os` live (public), README + recipe pushed 2026-11-11. Next: build workflow (§7), then the cloud build (Step 5).**
**Date:** 2026-11-11
**Target laptop:** HP Laptop 15q-by0xx, AMD A9-9420 dual-core, 3.7 GB RAM, 128 GB SSD (install target), Realtek RTL8723DE WiFi. Fedora 44 currently on it (to be wiped at install).

## 1. Base

- **Start from Xubuntu 24.04.5 minimal ISO** (`xubuntu-24.04.5-minimal-amd64.iso`, 3.0 GB, verified live 2026-11-11: https://cdimage.ubuntu.com/xubuntu/releases/24.04/release/xubuntu-24.04.5-minimal-amd64.iso) — Ubuntu 24.04 + Xfce, minimal variant (smaller download, smaller rootfs, faster build; we add only what we need). The workflow downloads it at build time — the base ISO is NOT stored in this repo.
- Build method: **Cubic** (custom ISO builder) inside a **GitHub Actions workflow** (free cloud build; Christy's VM has only 7.5 GB disk, a full ISO build cannot run there).
- Repo: `LinkVy-Os` on GitHub — **PUBLIC** (user decision 2026-11-11, revised from private: public = unlimited free Actions minutes; private = 2,000/month. Personal details must NOT go in the repo. The repo can be flipped back to private later if he ever wants.)
- Result of each build: a bootable live ISO, published as a **GitHub Release** asset. v1.0 first.

## 2. What gets removed (default Ubuntu/Xubuntu look)

- Firefox and any other browsers (Brave is the only browser; Firefox stays installable from the App Store if ever needed).
- Thunderbird (email) — not essential.
- Ubuntu orange Yaru theme, default wallpaper, default GNOME/Xfce branding — the whole default look is stripped.

## 3. What gets added (preinstalled — light, only the useful apps)

| App | Real package | Notes |
|---|---|---|
| Brave (default browser) | `brave-browser` (Brave's official apt repo) | Default browser, everywhere |
| Files | Thunar (Xfce default) | File manager |
| Terminal | `xfce4-terminal` | **Essential** — real terminal |
| Settings | `xfce4-settings` + our custom Settings screens | Main settings ours; deep settings stay Ubuntu's |
| App Store | GNOME Software + Flatpak support | Play-Store-like store |
| Music | Rhythmbox | Music player |
| Photos | Ristretto | Image viewer |
| Text Editor | Mousepad | Notes / light editing |
| Calculator | `gnome-calculator` | |

Everything else (VS Code, VLC, GIMP, LibreOffice, OBS Studio, Inkscape, Telegram) is **installable from the App Store**, not preinstalled — keeps the ISO light and the laptop fast.

## 4. Theming — Aurora Flow (the look)

- Wallpaper: dark blue-purple aurora waves (generated image, matches the locked design).
- GTK theme: dark, blue-purple accent. No Ubuntu orange anywhere.
- Window controls, icons, panel styling: same Aurora Flow palette.
- Panel layout: bottom dock (Brave, Files, Terminal, App Store, Settings) + small **Menu** button bottom-left (opens the App Launcher — Whisker Menu) + live clock at top-right.
- **Home screen:** the prototype's Home (cards, clock, search, weather, Quick Access, Recent Files, System Overview) becomes a small fullscreen app built from the same HTML/CSS/JS, launched at login. It is the design reference — the prototype at `home-screen` artifact. v1 scope: the themed Xfce desktop (aurora wallpaper + Arc-Dark + Brave default) ships first; the custom fullscreen Home app lands in a later release.
- Lock Screen: Xfce lock screen themed with the Aurora Flow look; shows the live clock + Rohit name.
- Name everywhere: **LinkVy OS** (not "Aurora Flow" — that is only the style name). Version in About: **v1.0**.
- About credit: small "Based on Ubuntu" line (trademark rule: a modified version cannot be called Ubuntu; Linux Mint / Pop!_OS do exactly this).

## 5. Installer

- Installer = Xubuntu's installer (Ubiquity), unchanged — it installs the customised system.
- Install target: SSD (`/dev/sda`). **Full wipe, no backup** (user decision 2026-11-11: "Sab kuch delete maar denge").
- Wipe scope still unconfirmed: SSD only, or SSD + the 931 GB HDD too? Ask before the install step.

## 6. Updater (v1 → v2 model)

- **Version file:** `/etc/linkvy-os-release` — `LINKVY_OS_VERSION=1.0`.
- **Settings → System Update** (already in the prototype): "Check for Updates" button runs `/usr/local/bin/linkvy-update-check`:
  - It checks the `linkvy-os` GitHub Releases for a newer version tag.
  - v1 has no v2 release yet → shows "You're up to date — LinkVy OS v1.0 is the latest version" + real Last checked time.
  - When v2 is published: the updater downloads the v2 update payload from the release and applies it, bumps the version file to 2.0. User files stay untouched.
- **Separate from Ubuntu updates:** Ubuntu security/package updates still come from Ubuntu's normal repos (`apt`) — they do not change the LinkVy OS version number. LinkVy OS version (v1 → v2) only changes when a LinkVy OS release is installed.

## 7. GitHub Actions workflow (the cloud build)

`linkvy-os/.github/workflows/build.yml`, runs on `ubuntu-latest`:

1. Check out repo (recipe + theme assets + wallpaper + installer config).
2. Download Xubuntu 24.04 LTS ISO.
3. Remaster by hand (no Cubic — Cubic is GUI-driven, not scriptable): extract ISO → unsquashfs → chroot `build/customize.sh` (remove/add packages §2–§3, Brave, wallpaper + dark theme §4, updater §6 + version file) → mksquashfs → rebuild a bootable ISO reusing the original El Torito boot parameters (`build/build.sh`).
4. Build the new ISO → upload as a workflow artifact + publish as GitHub Release `v1.0`.
5. Download ISO → write to the 512 GB HP pen drive (Fedora Media Writer / balenaEtcher) → live USB test.

## 8. Live USB test checklist (before installing)

- [ ] Boots from the pen drive (UEFI)
- [ ] WiFi connects (RTL8723DE — test this first, driver can be flaky)
- [ ] Brave opens, default browser
- [ ] App Store opens, an app installs
- [ ] Terminal opens
- [ ] Settings → System Update shows v1.0, "up to date"
- [ ] Speed feels smooth on 4 GB RAM, no lag on the desktop

## 9. Steps after this recipe

1. **GitHub connect** — DONE 2026-11-11 (account rohit9edit-dev, App installed, repo added).
2. Create repo `LinkVy-Os`, push this recipe + workflow + assets. — DONE 2026-11-11 (repo created public; README + recipe pushed).
3. Run the Actions build → ISO.
4. Live USB test (his laptop, checklist above).
5. Fixes + rebuild if needed.
6. Wipe + install on SSD (confirm wipe scope first).
7. Post-install check.
8. Personal AI agent bundled later (Step 10 of the original plan).

## Open questions (need his word)

- GitHub connect — the one thing blocking the build.
- Wipe scope: SSD only, or SSD + HDD?
- App list OK, or add/remove anything?
