#!/bin/sh
# SPDX-FileCopyrightText: 2026 Francesco Panarese
# SPDX-License-Identifier: GPL-3.0-only
# Installs the XMB BigScreen homescreen, shell profile and Wayland session under $PREFIX.
# Needs plasma-bigscreen installed (the session reuses its backend).
set -eu

PREFIX="${PREFIX:-/usr}"
SRC="$(CDPATH= cd "$(dirname "$0")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "Installs into $PREFIX and needs root. Run: sudo $0" >&2
    exit 1
fi

PLASMOID="$PREFIX/share/plasma/plasmoids/org.kde.plasma.xmbbigscreen"
SHELL_PKG="$PREFIX/share/plasma/shells/org.kde.plasma.xmbbigscreen"

echo "homescreen containment -> $PLASMOID"
rm -rf "$PLASMOID"
install -d "$PLASMOID"
install -m644 "$SRC/metadata.json" "$PLASMOID/metadata.json"
cp -r "$SRC/contents" "$PLASMOID/"

echo "shell profile       -> $SHELL_PKG"
rm -rf "$SHELL_PKG"
install -d "$SHELL_PKG"
cp -r "$SRC/shell/org.kde.plasma.xmbbigscreen/." "$SHELL_PKG/"

echo "startup script      -> $PREFIX/bin/plasma-xmbbigscreen-wayland"
install -Dm755 "$SRC/session/plasma-xmbbigscreen-wayland" "$PREFIX/bin/plasma-xmbbigscreen-wayland"

echo "wayland session     -> $PREFIX/share/wayland-sessions/plasma-xmbbigscreen-wayland.desktop"
install -Dm644 "$SRC/session/plasma-xmbbigscreen-wayland.desktop" "$PREFIX/share/wayland-sessions/plasma-xmbbigscreen-wayland.desktop"

echo "stick-swap tool     -> $PREFIX/bin/xmb-bigscreen-stick-swap"
install -Dm755 "$SRC/session/xmb-bigscreen-stick-swap" "$PREFIX/bin/xmb-bigscreen-stick-swap"
install -Dm644 "$SRC/session/inputhandler-stick-swap.conf" \
    "$PREFIX/lib/systemd/user/app-org.kde.plasma.bigscreen.inputhandler@.service.d/xmb-stick-swap.conf"

# Best-effort cache refresh for the invoking user.
[ -n "${SUDO_USER:-}" ] && sudo -u "$SUDO_USER" kbuildsycoca6 >/dev/null 2>&1 || true

echo "Done. Log out and pick \"XMB BigScreen\" at the login manager."
