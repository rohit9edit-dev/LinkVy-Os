#!/usr/bin/env bash
# LinkVy OS — check GitHub Releases for a newer LinkVy OS version.
# Called by Settings -> System Update. The repo is public, so the
# Releases API works without a login.
# Output: "up-to-date 1.0" or "update-available 2.0 (current 1.0)".
set -uo pipefail

VERSION_FILE="/etc/linkvy-os-release"
CURRENT="1.0"
if [ -f "$VERSION_FILE" ]; then
  CURRENT="$(grep '^LINKVY_OS_VERSION=' "$VERSION_FILE" | cut -d= -f2)"
fi

LATEST="$(curl -fsSL --max-time 15 https://api.github.com/repos/rohit9edit-dev/LinkVy-Os/releases/latest 2>/dev/null \
  | grep '"tag_name"' | head -1 | cut -d'"' -f4 | sed 's/^v//')"

if [ -z "$LATEST" ]; then
  echo "up-to-date $CURRENT (could not check for updates)"
  exit 0
fi

if [ "$LATEST" = "$CURRENT" ]; then
  echo "up-to-date $CURRENT"
else
  echo "update-available $LATEST (current $CURRENT)"
fi
