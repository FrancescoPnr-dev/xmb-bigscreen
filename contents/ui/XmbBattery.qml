// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// Charge readout for the system overlay: Breeze glyph plus percentage, matching the
// clock it sits beside.
import QtQuick
import org.kde.kirigami as Kirigami

Row {
    id: battery

    property int percent: 0
    property bool charging: false
    property int pixelSize: 22

    height: Math.round(pixelSize * 1.4)
    spacing: Math.round(pixelSize * 0.35)
    opacity: 0.92

    // Breeze steps the glyph every 10%, on the thresholds the Plasma applet uses.
    readonly property int _step: percent > 5 ? Math.round(Math.min(100, percent) / 10) * 10 : 0
    readonly property string iconName:
        "battery-" + ("00" + _step).slice(-3) + (charging ? "-charging" : "") + "-symbolic"

    Kirigami.Icon {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.round(battery.pixelSize * 1.15)
        height: width
        source: battery.iconName
        color: "white"
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: battery.percent + "%"
        color: "white"
        font.pixelSize: battery.pixelSize
        font.weight: Font.Light
        font.letterSpacing: 1
    }
}
