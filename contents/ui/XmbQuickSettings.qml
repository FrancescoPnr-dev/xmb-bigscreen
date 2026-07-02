// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.plasma5support as P5Support

Item {
    id: qs

    property int labelSize: 18
    property bool active: false
    property var translate: (s) => s
    readonly property bool hovered: bandHover.hovered
    signal closeRequested()

    // covers the gaps between labels so the hover band is continuous; the WheelHandler on the bar root calls wheelStep()
    HoverHandler { id: bandHover }
    function wheelStep(up) {
        if (briHover.hovered) qs.briStep(up)
        else if (volHover.hovered) qs.volStep(up)
    }

    property int volPct: -1
    property int briPct: -1
    property int _briRaw: 0
    property int _briMax: 0

    // a bare Item doesn't adopt implicitWidth/Height, so set it explicitly (with padding for the hover band)
    implicitWidth: rowL.implicitWidth + Math.round(labelSize * 2.6)
    implicitHeight: rowL.implicitHeight + Math.round(labelSize * 1.2)
    width: implicitWidth
    height: implicitHeight

    readonly property string briBase: "org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl"
    readonly property string volReadCmd: "wpctl get-volume @DEFAULT_AUDIO_SINK@"
    property string briReadCmd: "echo BRI_READ $(qdbus6 " + briBase + " brightness) $(qdbus6 " + briBase + " brightnessMax)"

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (src, data) => {
            var out = ((data["stdout"] || "") + "").trim()
            if (src.indexOf("get-volume") !== -1) {
                var m = out.match(/([0-9]*\.?[0-9]+)/)
                if (m) qs.volPct = Math.round(parseFloat(m[1]) * 100)
            } else if (src.indexOf("BRI_READ") !== -1) {
                var p = out.replace("BRI_READ", "").trim().split(/\s+/)
                if (p.length >= 2) {
                    qs._briRaw = parseInt(p[0]); qs._briMax = parseInt(p[1])
                    qs.briPct = qs._briMax > 0 ? Math.round(qs._briRaw * 100 / qs._briMax) : -1
                }
            }
            exec.disconnectSource(src)
        }
    }
    function run(c) { exec.connectSource(c) }
    function readAll() { run(volReadCmd); run(briReadCmd) }
    onActiveChanged: if (active) readAll()

    Timer { id: volReread; interval: 120; onTriggered: qs.run(qs.volReadCmd) }
    function volStep(up) {
        run("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%" + (up ? "+" : "-"))
        volReread.restart()
    }
    function briStep(up) {
        if (qs._briMax <= 0) return
        var step = Math.max(1, Math.round(qs._briMax * 0.05))
        var v = Math.max(0, Math.min(qs._briMax, qs._briRaw + (up ? step : -step)))
        qs._briRaw = v
        qs.briPct = Math.round(v * 100 / qs._briMax)
        run("qdbus6 " + briBase + " setBrightnessSilent " + v)
    }

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
                onTapped: { qs.run("kcmshell6 kcm_networkmanagement"); qs.closeRequested() }
            }
        }
    }
}
