// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: qs

    property var system: null
    property int labelSize: 18
    property bool active: false
    property var translate: (s) => s
    readonly property bool hovered: bandHover.hovered
    signal closeRequested()

    // covers the gaps between labels so the hover band is continuous; the WheelHandler on the bar root calls wheelStep()
    HoverHandler { id: bandHover }
    function wheelStep(up) {
        if (briHover.hovered && qs.system) qs.system.brightnessStep(up)
        else if (volHover.hovered && qs.system) qs.system.volumeStep(up)
    }

    readonly property int volPct: system ? system.volumePercent : -1
    readonly property int briPct: system ? system.brightnessPercent : -1

    // a bare Item doesn't adopt implicitWidth/Height, so set it explicitly (with padding for the hover band)
    implicitWidth: rowL.implicitWidth + Math.round(labelSize * 2.6)
    implicitHeight: rowL.implicitHeight + Math.round(labelSize * 1.2)
    width: implicitWidth
    height: implicitHeight

    RowLayout {
        id: rowL
        anchors.centerIn: parent
        spacing: Math.round(qs.labelSize * 2.2)

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.7)
            shadowBlur: 0.7; shadowVerticalOffset: 1
        }

        // Brightness
        ColumnLayout {
            spacing: 1
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qs.translate("Brightness"); color: "white"
                opacity: briHover.hovered ? 1.0 : 0.74
                font.pixelSize: qs.labelSize; font.weight: Font.Light; font.letterSpacing: 1
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qs.briPct >= 0 ? qs.briPct + "%" : "—"
                color: "white"; opacity: briHover.hovered ? 0.9 : 0.0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                font.pixelSize: Math.round(qs.labelSize * 0.8); font.weight: Font.Light
            }
            HoverHandler { id: briHover; cursorShape: Qt.PointingHandCursor }
        }

        // Volume
        ColumnLayout {
            spacing: 1
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qs.translate("Volume"); color: "white"
                opacity: volHover.hovered ? 1.0 : 0.74
                font.pixelSize: qs.labelSize; font.weight: Font.Light; font.letterSpacing: 1
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qs.volPct >= 0 ? qs.volPct + "%" : "—"
                color: "white"; opacity: volHover.hovered ? 0.9 : 0.0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                font.pixelSize: Math.round(qs.labelSize * 0.8); font.weight: Font.Light
            }
            HoverHandler { id: volHover; cursorShape: Qt.PointingHandCursor }
        }

        // Network (click only)
        ColumnLayout {
            spacing: 1
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qs.translate("Network"); color: "white"
                opacity: netHover.hovered ? 1.0 : 0.74
                font.pixelSize: qs.labelSize; font.weight: Font.Light; font.letterSpacing: 1
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: qs.translate("Settings")
                color: "white"; opacity: netHover.hovered ? 0.9 : 0.0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                font.pixelSize: Math.round(qs.labelSize * 0.8); font.weight: Font.Light
            }
            HoverHandler { id: netHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    if (qs.system) qs.system.openSettings("kcm_mediacenter_wifi")
                    qs.closeRequested()
                }
            }
        }
    }
}
