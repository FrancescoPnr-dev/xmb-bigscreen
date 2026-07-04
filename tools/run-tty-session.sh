#!/bin/sh
# SPDX-FileCopyrightText: 2026 Francesco Panarese
# SPDX-License-Identifier: GPL-3.0-only
# Launch the XMB session on the current VT for testing, logging to ~/xmb-tty.log.
# Run it from a text login on a spare VT (e.g. Ctrl+Alt+F5), NOT from the desktop
# session. Needs `sudo ./install.sh` to have installed the session first.
LOG="$HOME/xmb-tty.log"
echo "=== XMB tty session started ===" > "$LOG"
exec /usr/lib/plasma-dbus-run-session-if-needed /usr/bin/plasma-xmbbigscreen-wayland >> "$LOG" 2>&1
