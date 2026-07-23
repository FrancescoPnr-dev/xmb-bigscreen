// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// The Plasma battery backend, alone in this file so SystemControl can load it through a
// Loader: it is a private import, and a future Plasma dropping it must cost the
// indicator, not the whole shell.
import QtQuick
import org.kde.plasma.private.battery as Battery

Battery.BatteryControlModel {
    // A wireless pad registers as a battery too, so hasBatteries alone would light the
    // indicator up on a desktop; only an internal pack carries a cumulative charge.
    readonly property bool available: hasInternalBatteries && hasCumulative
}
