#!/bin/sh
# SPDX-FileCopyrightText: 2026 Francesco Panarese
# SPDX-License-Identifier: GPL-3.0-only
# Removes everything install.sh added. Other sessions and plasma-bigscreen are untouched.
set -eu

PREFIX="${PREFIX:-/usr}"

if [ "$(id -u)" -ne 0 ]; then
    echo "Removes from $PREFIX and needs root. Run: sudo $0" >&2
    exit 1
fi

rm -rf "$PREFIX/share/plasma/plasmoids/org.kde.plasma.xmbbigscreen"
rm -rf "$PREFIX/share/plasma/shells/org.kde.plasma.xmbbigscreen"
rm -f  "$PREFIX/bin/plasma-xmbbigscreen-wayland"
rm -f  "$PREFIX/share/wayland-sessions/plasma-xmbbigscreen-wayland.desktop"

[ -n "${SUDO_USER:-}" ] && sudo -u "$SUDO_USER" kbuildsycoca6 >/dev/null 2>&1 || true

echo "Removed XMB BigScreen."
