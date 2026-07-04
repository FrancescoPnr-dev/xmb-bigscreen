// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// Home overlay: a layer-shell window over the running app. Controller/keyboard hub with
// open apps to switch between, "back to XMB", and system actions (volume, power, network).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import org.kde.layershell as LayerShell
import org.kde.plasma.private.sessions as Sessions
import org.kde.plasma.plasma5support as P5Support

Window {
    id: overlay

    visible: false
    color: Qt.rgba(0, 0, 0, 0.72)
    flags: Qt.FramelessWindowHint

    LayerShell.Window.scope: "overlay"
    LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom
                             | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
    LayerShell.Window.layer: LayerShell.Window.LayerOverlay
    LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityOnDemand
    LayerShell.Window.exclusionZone: -1

    function showOverlay() {
        visible = true
        overlay.requestActivate()
        readSettings()
        if (tasksModel.count > 0)
            appsList.forceActiveFocus()
        else
            systemList.forceActiveFocus()
    }
    function hideOverlay() { visible = false }
    function toggle() { visible ? hideOverlay() : showOverlay() }
    function goHome() {
        tasksModel.minimizeAllTasks()
        hideOverlay()
    }

    Sessions.SessionManagement { id: session }

    TaskManager.TasksModel {
        id: tasksModel
        groupMode: TaskManager.TasksModel.GroupDisabled
        filterByScreen: false
        filterByVirtualDesktop: false
        filterByActivity: false
        filterHidden: true

        function minimizeAllTasks() {
            for (var i = 0; i < tasksModel.count; i++) {
                var idx = tasksModel.makeModelIndex(i)
                if (!tasksModel.data(idx, TaskManager.AbstractTasksModel.IsMinimized))
                    tasksModel.requestToggleMinimized(idx)
            }
        }
    }

    // Volume/brightness read and step, same backends as the mouse reveal bar.
    property int volPct: -1
    property int briPct: -1
    property int _briRaw: 0
    property int _briMax: 0
    readonly property string briBase: "org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement/Actions/BrightnessControl"

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (src, data) => {
            var out = ((data["stdout"] || "") + "").trim()
            if (src.indexOf("get-volume") !== -1) {
                var m = out.match(/([0-9]*\.?[0-9]+)/)
                if (m) overlay.volPct = Math.round(parseFloat(m[1]) * 100)
            } else if (src.indexOf("BRI_READ") !== -1) {
                var p = out.replace("BRI_READ", "").trim().split(/\s+/)
                if (p.length >= 2) {
                    overlay._briRaw = parseInt(p[0]); overlay._briMax = parseInt(p[1])
                    overlay.briPct = overlay._briMax > 0 ? Math.round(overlay._briRaw * 100 / overlay._briMax) : -1
                }
            }
            exec.disconnectSource(src)
        }
    }
    function run(c) { exec.connectSource(c) }
    function readSettings() {
        run("wpctl get-volume @DEFAULT_AUDIO_SINK@")
        run("echo BRI_READ $(qdbus6 " + briBase + " brightness) $(qdbus6 " + briBase + " brightnessMax)")
    }
    Timer { id: volReread; interval: 120; onTriggered: overlay.run("wpctl get-volume @DEFAULT_AUDIO_SINK@") }
    function volStep(up) {
        run("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%" + (up ? "+" : "-"))
        volReread.restart()
    }
    function briStep(up) {
        if (_briMax <= 0) return
        var step = Math.max(1, Math.round(_briMax * 0.05))
        var v = Math.max(0, Math.min(_briMax, _briRaw + (up ? step : -step)))
        _briRaw = v
        briPct = Math.round(v * 100 / _briMax)
        run("qdbus6 " + briBase + " setBrightnessSilent " + v)
    }

    readonly property var systemActions: [
        { act: "home",     label: i18n("Back to XMB"), icon: "go-home",             on: true },
        { act: "voldown",  label: i18n("Volume") + " −",     icon: "audio-volume-low",    on: true },
        { act: "volup",    label: i18n("Volume") + " +",     icon: "audio-volume-high",   on: true },
        { act: "bridown",  label: i18n("Brightness") + " −", icon: "video-display",       on: _briMax > 0 },
        { act: "briup",    label: i18n("Brightness") + " +", icon: "video-display",       on: _briMax > 0 },
        { act: "network",  label: i18n("Network"),     icon: "network-wireless",    on: true },
        { act: "suspend",  label: i18n("Sleep"),       icon: "system-suspend",      on: session.canSuspend },
        { act: "reboot",   label: i18n("Restart"),     icon: "system-reboot",       on: session.canReboot },
        { act: "shutdown", label: i18n("Shut down"),   icon: "system-shutdown",     on: session.canShutdown },
        { act: "lock",     label: i18n("Lock"),        icon: "system-lock-screen",  on: session.canLock },
        { act: "logout",   label: i18n("Log out"),     icon: "system-log-out",      on: session.canLogout }
    ]
    function triggerSystem(act) {
        switch (act) {
        case "home":     goHome(); return
        case "voldown":  volStep(false); return
        case "volup":    volStep(true); return
        case "bridown":  briStep(false); return
        case "briup":    briStep(true); return
        case "network":  run("kcmshell6 kcm_networkmanagement"); hideOverlay(); return
        case "suspend":  session.suspend(); hideOverlay(); return
        case "reboot":   session.requestReboot(); hideOverlay(); return
        case "shutdown": session.requestShutdown(); hideOverlay(); return
        case "lock":     session.lock(); hideOverlay(); return
        case "logout":   session.requestLogout(); hideOverlay(); return
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.86, 1500)
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.leftMargin: Kirigami.Units.gridUnit
            text: tasksModel.count > 0 ? i18n("Open apps") : i18n("No open apps")
            color: "white"
            font.pixelSize: 34
            font.weight: Font.Light
        }

        ListView {
            id: appsList
            visible: tasksModel.count > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 9
            orientation: ListView.Horizontal
            spacing: Kirigami.Units.largeSpacing
            clip: true
            model: tasksModel
            keyNavigationWraps: true
            KeyNavigation.down: systemList

            delegate: Item {
                id: tile
                required property int index
                required property var model
                width: Kirigami.Units.gridUnit * 11
                height: ListView.view.height
                readonly property bool current: ListView.isCurrentItem

                Rectangle {
                    anchors.fill: parent
                    radius: Kirigami.Units.smallSpacing
                    color: tile.current && appsList.activeFocus ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.06)
                    border.width: tile.current && appsList.activeFocus ? 2 : 0
                    border.color: "white"
                }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        source: tile.model.decoration
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: tile.model.display
                        color: "white"
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
                TapHandler {
                    onTapped: { appsList.currentIndex = tile.index; overlay.activateCurrent() }
                }
            }

            Keys.onReturnPressed: overlay.activateCurrent()
            Keys.onEnterPressed: overlay.activateCurrent()
            Keys.onEscapePressed: overlay.hideOverlay()
        }

        QQC2.Label {
            Layout.leftMargin: Kirigami.Units.gridUnit
            color: "white"
            opacity: 0.7
            font.pixelSize: 18
            visible: overlay.volPct >= 0 || overlay.briPct >= 0
            text: {
                var parts = []
                if (overlay.volPct >= 0) parts.push(i18n("Volume") + " " + overlay.volPct + "%")
                if (overlay.briPct >= 0) parts.push(i18n("Brightness") + " " + overlay.briPct + "%")
                return parts.join("   ·   ")
            }
        }

        ListView {
            id: systemList
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 5
            orientation: ListView.Horizontal
            spacing: Kirigami.Units.largeSpacing
            clip: true
            keyNavigationWraps: true
            KeyNavigation.up: appsList
            model: overlay.systemActions.filter(a => a.on !== false)

            delegate: Item {
                id: sTile
                required property int index
                required property var modelData
                width: Kirigami.Units.gridUnit * 8
                height: ListView.view.height
                readonly property bool current: ListView.isCurrentItem

                Rectangle {
                    anchors.fill: parent
                    radius: Kirigami.Units.smallSpacing
                    color: sTile.current && systemList.activeFocus ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.06)
                    border.width: sTile.current && systemList.activeFocus ? 2 : 0
                    border.color: "white"
                }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillHeight: true
                        Layout.preferredWidth: height
                        source: sTile.modelData.icon
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        text: sTile.modelData.label
                        color: "white"
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 16
                    }
                }
                TapHandler {
                    onTapped: { systemList.currentIndex = sTile.index; overlay.triggerSystem(sTile.modelData.act) }
                }
            }

            Keys.onReturnPressed: triggerCurrent()
            Keys.onEnterPressed: triggerCurrent()
            Keys.onEscapePressed: overlay.hideOverlay()
            function triggerCurrent() {
                var a = overlay.systemActions.filter(x => x.on !== false)[currentIndex]
                if (a) overlay.triggerSystem(a.act)
            }
        }
    }

    function activateCurrent() {
        if (appsList.currentIndex < 0)
            return
        tasksModel.requestActivate(tasksModel.makeModelIndex(appsList.currentIndex))
        hideOverlay()
    }

    // If the last app closes while open, drop the now-empty app row focus to the system row.
    Connections {
        target: tasksModel
        function onCountChanged() {
            if (overlay.visible && tasksModel.count === 0)
                systemList.forceActiveFocus()
        }
    }

}
