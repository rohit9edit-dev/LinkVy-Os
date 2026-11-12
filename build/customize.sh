#!/usr/bin/env bash
# LinkVy OS v1.0 — customization, runs INSIDE the chroot as root.
# Called by build/build.sh.
#
# v1 (rebuild, 2026-11-12) — Xubuntu 24.04.5 minimal base + Aurora Flow
# desktop, direction C (apna unique design, na Windows ki copy na macOS ki):
# aurora wallpaper, Arc-Dark, big center clock (Conky), animated bottom dock
# (Plank), compositor animations, IST timezone, Brave as the only browser.
# The fullscreen Home app + Settings Center land in a later release.
#
# LESSON 2026-11-12 (found live-testing the run-#6 ISO): theming written
# only to /etc/skel does NOT reach the live session — the live user
# "xubuntu" already has a home dir in the image, so skel is never applied
# to it (only to users created at install time). So every desktop config
# below is written to BOTH /etc/skel (new users) AND /home/xubuntu
# (the live user), then chowned to the live user.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

LIVE_HOME="/home/xubuntu"
SKEL="/etc/skel"

copy_launcher () {
  # $1 = source .desktop file, $2 = target file (full path)
  if [ -f "$1" ]; then
    cp "$1" "$2"
  else
    echo "customize: launcher source missing, skipped: $1" >&2
  fi
}

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

echo "== customize: install dock (Plank) =="
apt-get install -y --no-install-recommends plank \
  || echo "WARNING: plank install failed (bottom dock will be missing)" >&2

echo "== customize: install clock (Conky) =="
apt-get install -y --no-install-recommends conky-all \
  || apt-get install -y --no-install-recommends conky \
  || echo "WARNING: conky install failed (big clock will be missing)" >&2

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

echo "== customize: timezone IST + hostname =="
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
printf 'Asia/Kolkata\n' > /etc/timezone
printf 'linkvy-os\n' > /etc/hostname
sed -i 's/^127\.0\.1\.1.*/127.0.1.1\tlinkvy-os/' /etc/hosts || true

echo "== customize: wallpaper + theme + animations =="
mkdir -p "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml" "$SKEL/.config"
mkdir -p "$SKEL/.config/conky" "$SKEL/.config/plank/dock1/launchers" "$SKEL/.config/autostart"

cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" <<'EOF'
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
        <property name="workspace1" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/linkvy-aurora.png"/>
        </property>
        <property name="workspace2" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/linkvy-aurora.png"/>
        </property>
        <property name="workspace3" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="image-style" type="int" value="5"/>
          <property name="last-image" type="string" value="/usr/share/backgrounds/linkvy-aurora.png"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-xsettings.xml" <<'EOF'
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

cat > "$SKEL/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="use_compositing" type="bool" value="true"/>
  <property name="show_frame_shadow" type="bool" value="true"/>
  <property name="show_popup_shadow" type="bool" value="true"/>
</channel>
EOF

cat > "$SKEL/.config/mimeapps.list" <<'EOF'
[Default Applications]
x-scheme-handler/http=brave-browser.desktop
x-scheme-handler/https=brave-browser.desktop
text/html=brave-browser.desktop
EOF

echo "== customize: big center clock (Conky) =="
cat > "$SKEL/.config/conky/conky.conf" <<'EOF'
conky.config = {
    alignment = 'middle_middle',
    background = false,
    border_width = 0,
    cpu_avg_samples = 1,
    default_color = 'FFFFFF',
    double_buffer = true,
    draw_borders = false,
    draw_graph_borders = false,
    draw_outline = false,
    draw_shades = false,
    gap_x = 0,
    gap_y = -60,
    minimum_height = 220,
    minimum_width = 800,
    net_avg_samples = 1,
    no_buffers = true,
    out_to_console = false,
    out_to_stderr = false,
    own_window = true,
    own_window_class = 'Conky',
    own_window_type = 'desktop',
    own_window_transparent = true,
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',
    show_graph_range = false,
    show_graph_scale = false,
    stippled_borders = 0,
    update_interval = 1.0,
    uppercase = false,
    use_spacer = 'none',
    use_xft = true,
    font = 'DejaVu Sans:size=96',
    color1 = 'FFFFFF',
}

conky.text = [[
${alignc}${time %H:%M}
${alignc}${font DejaVu Sans:size=26}${time %A, %d %B %Y}${font}
${alignc}${font DejaVu Sans:size=16}${color AAB4D6}LinkVy OS${color}${font}
]]
EOF

echo "== customize: animated bottom dock (Plank) =="
cat > "$SKEL/.config/plank/dock1/settings" <<'EOF'
[dock1]
alignment='center'
auto-pinning=false
hide-delay=0
hide-mode='none'
icon-size=48
items-alignment='center'
lock-items=false
monitor=''
offset=0
pinned-only=false
position='bottom'
pressure-reveal=false
show-dock-item=false
theme='Transparent'
tooltips-enabled=true
unhide-delay=0
zoom-enabled=true
zoom-percent=150
EOF

LAUNCHERS="$SKEL/.config/plank/dock1/launchers"
copy_launcher /usr/share/applications/brave-browser.desktop "$LAUNCHERS/brave-browser.desktop"
if [ -f /usr/share/applications/thunar.desktop ]; then
  cp /usr/share/applications/thunar.desktop "$LAUNCHERS/thunar.desktop"
elif [ -f /usr/share/applications/org.xfce.Thunar.desktop ]; then
  cp /usr/share/applications/org.xfce.Thunar.desktop "$LAUNCHERS/thunar.desktop"
else
  echo "customize: launcher source missing, skipped: thunar" >&2
fi
copy_launcher /usr/share/applications/xfce4-terminal.desktop "$LAUNCHERS/xfce4-terminal.desktop"
copy_launcher /usr/share/applications/org.gnome.Software.desktop "$LAUNCHERS/org.gnome.Software.desktop"
copy_launcher /usr/share/applications/xfce-settings-manager.desktop "$LAUNCHERS/xfce-settings-manager.desktop"

cat > "$LAUNCHERS/menu.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Menu
Comment=Search and launch apps
Exec=xfce4-appfinder
Icon=system-search
Terminal=false
Categories=Utility;
OnlyShowIn=XFCE;
EOF

echo "== customize: autostart dock + clock =="
cat > "$SKEL/.config/autostart/plank.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=LinkVy Dock
Comment=Aurora Flow bottom dock
Exec=plank
Icon=plank
Terminal=false
Categories=Utility;
OnlyShowIn=XFCE;
EOF

cat > "$SKEL/.config/autostart/conky.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=LinkVy Clock
Comment=Aurora Flow big clock on the desktop
Exec=conky -p 5
Icon=clock
Terminal=false
Categories=Utility;
OnlyShowIn=XFCE;
EOF

echo "== customize: apply the same configs to the live user =="
mkdir -p "$LIVE_HOME/.config"
cp -a "$SKEL/.config/." "$LIVE_HOME/.config/"
LIVE_UID=$(id -u xubuntu 2>/dev/null || echo 999)
LIVE_GID=$(id -g xubuntu 2>/dev/null || echo 999)
chown -R "$LIVE_UID:$LIVE_GID" "$LIVE_HOME/.config"

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
