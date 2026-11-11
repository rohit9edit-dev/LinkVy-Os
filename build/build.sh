#!/usr/bin/env bash
# LinkVy OS v1.0 — ISO remaster driver.
# Runs on the GitHub Actions runner (as root via sudo).
# Base: Xubuntu 24.04.5 minimal ISO -> customized LinkVy OS ISO.
# Method: unpack the ISO, unsquashfs the live filesystem, customize it
# in a chroot, repack, rebuild a bootable ISO reusing the original
# El Torito boot parameters.
set -euo pipefail

VERSION="${VERSION:-1.0}"
BASE_ISO_URL="${BASE_ISO_URL:-https://cdimage.ubuntu.com/xubuntu/releases/24.04/release/xubuntu-24.04.5-minimal-amd64.iso}"
BASE_ISO_NAME="$(basename "$BASE_ISO_URL")"
WORK="$GITHUB_WORKSPACE/work"
OUT="$GITHUB_WORKSPACE/output"
REPO="$GITHUB_WORKSPACE"

mkdir -p "$WORK" "$OUT"
cd "$WORK"

echo "== [1/8] Download base ISO =="
curl -fL --retry 3 -o "$BASE_ISO_NAME" "$BASE_ISO_URL"
ls -lh "$BASE_ISO_NAME"

echo "== [2/8] Verify SHA256 =="
curl -fL -o SHA256SUMS.txt https://cdimage.ubuntu.com/xubuntu/releases/24.04/release/SHA256SUMS
grep "$BASE_ISO_NAME" SHA256SUMS.txt | sha256sum -c -

echo "== [3/8] Extract ISO contents =="
mkdir -p iso
xorriso -osirrox on -indev "$BASE_ISO_NAME" -extract / iso
ls -lh iso/casper/

echo "== [4/8] Unpack the live filesystem =="
mkdir -p rootfs
unsquashfs -d rootfs iso/casper/filesystem.squashfs
df -h .

echo "== [5/8] Customize inside chroot =="
cp /etc/resolv.conf rootfs/etc/resolv.conf
mount --bind /dev rootfs/dev
mount -t proc proc rootfs/proc
mount -t sysfs sys rootfs/sys
cp "$REPO/build/customize.sh" rootfs/customize.sh
cp "$REPO/build/linkvy-update-check.sh" rootfs/usr/local/bin/linkvy-update-check
chmod +x rootfs/usr/local/bin/linkvy-update-check
# Wallpaper: convert the repo's SVG to PNG on the runner, copy into the image.
rsvg-convert -w 1920 -h 1080 "$REPO/theme/wallpaper.svg" -o rootfs/usr/share/backgrounds/linkvy-aurora.png
chroot rootfs /bin/bash /customize.sh
rm -f rootfs/customize.sh
umount rootfs/sys rootfs/proc rootfs/dev || true

echo "== [6/8] Repack the filesystem =="
rm -f iso/casper/filesystem.squashfs
mksquashfs rootfs iso/casper/filesystem.squashfs -comp xz -b 1M -noappend
du -sx --block-size=1 rootfs | cut -f1 > iso/casper/filesystem.size
chroot rootfs dpkg-query -W --showformat='${Package}\t${Version}\n' > iso/casper/filesystem.manifest || true

echo "== [7/8] Rebuild the ISO =="
# Reuse the original ISO's El Torito boot parameters, only changing
# the volume id and the output file.
xorriso -indev "$BASE_ISO_NAME" -report_el_torito as_mkisofs > mkisofs_args.txt
cat mkisofs_args.txt
NEW_VOLID="LinkVy OS v${VERSION}"
NEW_OUT="$OUT/linkvy-os-v${VERSION}-amd64.iso"
python3 - "$NEW_VOLID" "$NEW_OUT" iso <<'PYEOF'
import shlex, subprocess, sys
volid, out, isodir = sys.argv[1], sys.argv[2], sys.argv[3]
raw = open("mkisofs_args.txt").read().strip()
args = shlex.split(raw)
# The report line starts with "xorriso -as mkisofs ...". Replace -V and -o.
saw_v = False
saw_o = False
i = 0
while i < len(args):
    if args[i] == "-V" and i + 1 < len(args):
        args[i + 1] = volid
        saw_v = True
        i += 2
        continue
    if args[i] == "-o" and i + 1 < len(args):
        args[i + 1] = out
        saw_o = True
        i += 2
        continue
    i += 1
# The last arg is the ISO source dir; make sure it is our extracted dir.
if args[-1] != isodir:
    args.append(isodir)
# Insert -o / -V if the report did not carry them.
if not saw_o:
    args.insert(-1, "-o")
    args.insert(-1, out)
if not saw_v:
    args.insert(-1, "-V")
    args.insert(-1, volid)
print("Running:", " ".join(shlex.quote(a) for a in args))
subprocess.run(args, check=True)
PYEOF

echo "== [8/8] Checksums + permissions =="
ls -lh "$OUT/"
sha256sum "$OUT/linkvy-os-v${VERSION}-amd64.iso" > "$OUT/SHA256SUMS"
cat "$OUT/SHA256SUMS"
# The upload-artifact step runs as the runner user, not root.
if [ -n "${SUDO_USER:-}" ]; then
  chown -R "$SUDO_USER:$SUDO_USER" "$OUT" || true
fi
echo "DONE."
