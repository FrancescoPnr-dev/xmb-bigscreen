#!/bin/sh
# SPDX-FileCopyrightText: 2026 Francesco Panarese
# SPDX-License-Identifier: GPL-3.0-only
# Launch the XMB session on the current VT for testing (from a text login on a
# spare VT, not the desktop), logging to ~/xmb-tty.log. Needs install.sh first.
LOG="$HOME/xmb-tty.log"
echo "=== XMB tty session started ===" > "$LOG"
exec /usr/lib/plasma-dbus-run-session-if-needed /usr/bin/plasma-xmbbigscreen-wayland >> "$LOG" 2>&1
