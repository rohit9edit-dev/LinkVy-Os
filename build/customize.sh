#!/usr/bin/env bash
# LinkVy OS v1.0 — customization, runs INSIDE the chroot as root.
# Called by build/build.sh. Keep it focused: packages, Brave, theme,
# version file, updater. The full custom Home app lands in a later release.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

echo "== customize: package lists =="
apt-get update -y

echo "== customize: remove unwanted browsers/apps =="
apt-get remove -y --purge firefox firefox-locale-* thunderbird 2>/dev/null || true
apt-get autoremove -y || true

echo "== customize: install our apps =="
apt-get install -y --no-install-recommends \
  xfce4-terminal mousepad ristretto rhythmbox gnome-calculator \
  gnome-software flatpak curl wget gnupg ca-certificates \
  arc-theme || true

echo "== customize: install Brave (official repo) =="
curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
  -o /usr/share/keyrings/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" \
  > /etc/apt/sources.list.d/brave-browser-release.list
apt-get update -y
apt-get install -y brave-browser

echo "== customize: Brave as default browser =="
update-alternatives --set x-www-browser /usr/bin/brave-browser || true
update-alternatives --set gnome-www-browser /usr/bin/brave-browser || true

echo "== customize: wallpaper + theme (new users) =="
# wallpaper.png was copied in by build.sh to /usr/share/backgrounds/
mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml /etc/skel/.config
cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/linkvy-aurora.png"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF
cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-xsettings.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-xsettings" version="1.0">
  <property name="Gtk" type="empty">
    <property name="ThemeName" type="string" value="Arc-Dark"/>
    <property name="IconThemeName" type="string" value="elementary-xfce-dark"/>
  </property>
  <property name="Xft" type="empty">
    <property name="Antialias" type="int" value="1"/>
  </property>
</channel>
EOF
cat > /etc/skel/.config/mimeapps.list <<'EOF'
[Default Applications]
x-scheme-handler/http=brave-browser.desktop
x-scheme-handler/https=brave-browser.desktop
text/html=brave-browser.desktop
EOF

echo "== customize: login screen (LightDM greeter) =="
# First thing seen at boot — make it ours too, not stock Xubuntu.
cat > /etc/lightdm/lightdm-gtk-greeter.conf <<'EOF'
[greeter]
theme-name = Arc-Dark
icon-theme-name = elementary-xfce-dark
background = /usr/share/backgrounds/linkvy-aurora.png
EOF

echo "== customize: version + updater =="
printf 'LINKVY_OS_NAME=LinkVy OS\nLINKVY_OS_VERSION=1.0\n' > /etc/linkvy-os-release
# linkvy-update-check was copied to /usr/local/bin by build.sh
chmod +x /usr/local/bin/linkvy-update-check || true

echo "== customize: clean up =="
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
rm -f /etc/resolv.conf
echo "customize: DONE"
