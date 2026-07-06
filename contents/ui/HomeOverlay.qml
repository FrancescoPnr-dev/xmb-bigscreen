// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// Home overlay: a layer-shell window over the running app, laid out as a text-only
// mini XMB (PS3 in-game style): horizontal category labels, vertical items under the
// selected one. Home / open apps / power-session actions / quick settings.
import QtQuick
import QtQuick.Effects
import org.kde.plasma.private.sessions as Sessions
import org.kde.plasma.plasma5support as P5Support
import org.kde.taskmanager as TaskManager
import org.kde.layershell as LayerShell

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

    // Injected by main.qml so the overlay matches the dashboard's tick sound.
    property url navTickSource: ""
    property real navTickVolume: 0.5

    signal configRequested()

    function showOverlay() {
        visible = true
        overlay.requestActivate()
        readSettings()
        currentCategoryIndex = 0
        itemList.currentIndex = 0
        content.forceActiveFocus()
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

    // Non-visual mirror of the open tasks, so categories stay plain JS arrays.
    property var taskItems: []
    Instantiator {
        id: taskSource
        model: tasksModel
        delegate: QtObject {
            required property string display
            required property int index
        }
        onObjectAdded: Qt.callLater(overlay.rebuildTaskItems)
        onObjectRemoved: Qt.callLater(overlay.rebuildTaskItems)
    }
    function rebuildTaskItems() {
        var arr = []
        for (var i = 0; i < taskSource.count; i++) {
            var o = taskSource.objectAt(i)
            if (o)
                arr.push({ act: "task", row: o.index, label: o.display })
        }
        taskItems = arr
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

    property int currentCategoryIndex: 0
    readonly property var categories: [
        { name: i18n("Home"), items: [
            { act: "home", label: i18n("Back to XMB") }
        ]},
        { name: i18n("Applications"), items:
            taskItems.length > 0 ? taskItems
                                 : [{ act: "none", label: i18n("No open apps") }]
        },
        { name: i18n("Power"), items: [
            { act: "suspend",    label: i18n("Sleep"),       on: session.canSuspend },
            { act: "hibernate",  label: i18n("Hibernate"),   on: session.canHibernate },
            { act: "reboot",     label: i18n("Restart"),     on: session.canReboot },
            { act: "shutdown",   label: i18n("Shut down"),   on: session.canShutdown },
            { act: "logout",     label: i18n("Log out"),     on: session.canLogout },
            { act: "switchuser", label: i18n("Switch user"), on: session.canSwitchUser },
            { act: "lock",       label: i18n("Lock"),        on: session.canLock }
        ].filter(a => a.on !== false)},
        { name: i18n("Settings"), items: [
            { act: "volup",   label: i18n("Volume") + " +" },
            { act: "voldown", label: i18n("Volume") + " −" },
            { act: "briup",   label: i18n("Brightness") + " +", on: _briMax > 0 },
            { act: "bridown", label: i18n("Brightness") + " −", on: _briMax > 0 },
            { act: "network", label: i18n("Network") },
            { act: "config",  label: i18n("XMB settings") }
        ].filter(a => a.on !== false)}
    ]
    readonly property var currentItems: categories[currentCategoryIndex].items

    // Live labels for the stepper items, without rebuilding the arrays (keeps the index).
    function itemLabel(item) {
        if ((item.act === "volup" || item.act === "voldown") && volPct >= 0)
            return item.label + "   " + volPct + "%"
        if ((item.act === "briup" || item.act === "bridown") && briPct >= 0)
            return item.label + "   " + briPct + "%"
        return item.label
    }

    function trigger(item) {
        switch (item.act) {
        case "home":       goHome(); return
        case "task":       tasksModel.requestActivate(tasksModel.makeModelIndex(item.row)); hideOverlay(); return
        case "none":       return
        case "suspend":    session.suspend(); hideOverlay(); return
        case "hibernate":  session.hibernate(); hideOverlay(); return
        case "reboot":     session.requestReboot(); hideOverlay(); return
        case "shutdown":   session.requestShutdown(); hideOverlay(); return
        case "logout":     session.requestLogout(); hideOverlay(); return
        case "switchuser": session.switchUser(); hideOverlay(); return
        case "lock":       session.lock(); hideOverlay(); return
        case "volup":      volStep(true); tick.play(); return
        case "voldown":    volStep(false); tick.play(); return
        case "briup":      briStep(true); tick.play(); return
        case "bridown":    briStep(false); tick.play(); return
        case "network":    run("kcmshell6 kcm_networkmanagement"); hideOverlay(); return
        case "config":     configRequested(); hideOverlay(); return
        }
    }

    function selectCategory(index) {
        index = Math.max(0, Math.min(categories.length - 1, index))
        if (index === currentCategoryIndex)
            return
        currentCategoryIndex = index
        itemList.currentIndex = 0
        tick.play()
    }

    XmbSound {
        id: tick
        source: overlay.navTickSource
        volume: overlay.navTickVolume
    }

    Item {
        id: content
        anchors.fill: parent
        focus: true

        Row {
            id: categoryRow
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.24
            spacing: 56

            Repeater {
                model: overlay.categories
                Text {
                    required property var modelData
                    required property int index
                    readonly property bool current: index === overlay.currentCategoryIndex

                    anchors.baseline: categoryRow.top
                    anchors.baselineOffset: 48
                    text: modelData.name
                    color: "white"
                    opacity: current ? 1.0 : 0.40
                    font.pixelSize: current ? 38 : 26
                    font.weight: Font.Light
                    font.letterSpacing: 2
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Behavior on font.pixelSize { NumberAnimation { duration: 180 } }

                    TapHandler { onTapped: overlay.selectCategory(index) }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                }
            }
        }

        // Vertical arm: items of the selected category, text only, XMB emphasis.
        ListView {
            id: itemList
            anchors.horizontalCenter: parent.horizontalCenter
            y: categoryRow.y + 120
            width: Math.min(parent.width * 0.7, 900)
            height: parent.height - y
            spacing: 26
            interactive: false
            keyNavigationEnabled: false
            model: overlay.currentItems
            preferredHighlightBegin: parent.height * 0.14
            preferredHighlightEnd: parent.height * 0.14
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: 200
            highlightMoveVelocity: -1
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem

                width: itemList.width
                height: 52

                // Slow PS3 "breathing" glow on the focused label, as on the dashboard.
                property real glowPulse: 0.0
                SequentialAnimation on glowPulse {
                    running: row.current && overlay.visible
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.30; to: 0.90; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.90; to: 0.30; duration: 1500; easing.type: Easing.InOutSine }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    text: overlay.itemLabel(row.modelData)
                    color: "white"
                    opacity: row.current ? 1.0 : Math.max(0.25, 0.6 - Math.abs(row.index - itemList.currentIndex) * 0.1)
                    font.pixelSize: row.current ? 30 : 22
                    font.weight: Font.Light
                    font.letterSpacing: 1
                    elide: Text.ElideMiddle
                    width: Math.min(implicitWidth, row.width)
                    horizontalAlignment: Text.AlignHCenter
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Behavior on font.pixelSize { NumberAnimation { duration: 160 } }

                    layer.enabled: row.current
                    layer.effect: MultiEffect {
                        autoPaddingEnabled: true
                        blurMax: 32
                        shadowEnabled: true
                        shadowColor: "white"
                        shadowBlur: 1.0
                        shadowVerticalOffset: 0
                        shadowHorizontalOffset: 0
                        shadowOpacity: row.glowPulse
                    }
                }

                TapHandler {
                    onTapped: {
                        if (row.current)
                            overlay.trigger(row.modelData)
                        else
                            itemList.currentIndex = row.index
                    }
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }

        Keys.onLeftPressed: overlay.selectCategory(overlay.currentCategoryIndex - 1)
        Keys.onRightPressed: overlay.selectCategory(overlay.currentCategoryIndex + 1)
        Keys.onUpPressed: {
            var i = itemList.currentIndex
            itemList.decrementCurrentIndex()
            if (itemList.currentIndex !== i) tick.play()
        }
        Keys.onDownPressed: {
            var i = itemList.currentIndex
            itemList.incrementCurrentIndex()
            if (itemList.currentIndex !== i) tick.play()
        }
        Keys.onReturnPressed: overlay.trigger(overlay.currentItems[itemList.currentIndex])
        Keys.onEnterPressed: overlay.trigger(overlay.currentItems[itemList.currentIndex])
        Keys.onEscapePressed: overlay.hideOverlay()
    }
}
