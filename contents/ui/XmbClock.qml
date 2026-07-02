// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Effects

Text {
    id: clock

    property var now: new Date()
    property int pixelSize: 30
    property int timeFormat: 0   // 0 system, 1 12h, 2 24h
    property int dateFormat: 0   // 0 system, 1 dd/mm, 2 mm/dd
    property bool showDate: true

    text: {
        var d = clock.now
        var t = timeFormat === 1 ? Qt.formatTime(d, "h:mm AP")
              : timeFormat === 2 ? Qt.formatTime(d, "HH:mm")
              : Qt.formatTime(d, Qt.locale().timeFormat(Locale.ShortFormat))
        if (!clock.showDate) return t
        // system = locale short date with the year stripped out
        var df = dateFormat === 1 ? "dd/MM"
               : dateFormat === 2 ? "MM/dd"
               : Qt.locale().dateFormat(Locale.ShortFormat).replace(/[^dM]*y+[^dM]*/, "")
        return Qt.formatDate(d, df) + "   " + t
    }

    color: "#ffffff"
    opacity: 0.92
    font.pixelSize: clock.pixelSize
    font.weight: Font.Light
    font.letterSpacing: 1

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.55)
        shadowBlur: 0.6
        shadowVerticalOffset: 1
        shadowHorizontalOffset: 0
    }

    Timer {
        interval: 1000
        running: clock.visible
        repeat: true
        onTriggered: clock.now = new Date()
    }
}
