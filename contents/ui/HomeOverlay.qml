// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// Home overlay: a layer-shell window over the running app, laid out as a text-only
// mini XMB (PS3 in-game style): horizontal category labels, vertical items under the
// selected one. Home / open apps / power-session actions / quick settings.
import QtQuick
import QtQuick.Effects
import org.kde.taskmanager as TaskManager
import org.kde.layershell as LayerShell
import org.kde.bigscreen as Bigscreen

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

    // Injected by main.qml: the shared backend gateway and the dashboard's tick sound.
    property var system: null
    property url navTickSource: ""
    property real navTickVolume: 0.5

    signal configRequested()

    function showOverlay() {
        visible = true
        overlay.requestActivate()
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

    readonly property var session: system ? system.session : null

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

    // Volume/brightness come reactive from the shared backend gateway.
    readonly property int volPct: system ? system.volumePercent : -1
    readonly property int briPct: system ? system.brightnessPercent : -1

    // Native flow: hide the overlay, then shoot once it has faded out.
    Timer {
        id: screenshotTimer
        interval: 500
        onTriggered: Bigscreen.Global.takeScreenshot()
    }

    property int currentCategoryIndex: 0
    readonly property var categories: [
        { name: i18n("Home"), items: [
            { act: "home", label: i18n("Back to XMB") },
            { act: "screenshot", label: i18n("Screenshot") }
        ]},
        { name: i18n("Applications"), items:
            taskItems.length > 0 ? taskItems
                                 : [{ act: "none", label: i18n("No open apps") }]
        },
        { name: i18n("Power"), items: [
            { act: "suspend",    label: i18n("Sleep"),       on: session ? session.canSuspend : false },
            { act: "hibernate",  label: i18n("Hibernate"),   on: session ? session.canHibernate : false },
            { act: "reboot",     label: i18n("Restart"),     on: session ? session.canReboot : false },
            { act: "shutdown",   label: i18n("Shut down"),   on: session ? session.canShutdown : false },
            { act: "logout",     label: i18n("Log out"),     on: session ? session.canLogout : false },
            { act: "switchuser", label: i18n("Switch user"), on: session ? session.canSwitchUser : false },
            { act: "lock",       label: i18n("Lock"),        on: session ? session.canLock : false },
            { act: "swapsession", label: i18n("Exit to desktop"), on: Bigscreen.Global.launchReason === "swap" }
        ].filter(a => a.on !== false)},
        { name: i18n("Settings"), items: [
            { act: "volup",   label: i18n("Volume") + " +",     on: volPct >= 0 },
            { act: "voldown", label: i18n("Volume") + " −",     on: volPct >= 0 },
            { act: "briup",   label: i18n("Brightness") + " +", on: briPct >= 0 },
            { act: "bridown", label: i18n("Brightness") + " −", on: briPct >= 0 },
            { act: "network",  label: i18n("Network") },
            { act: "audio",    label: i18n("Audio device") },
            { act: "allsettings", label: i18n("All settings") },
            { act: "config",   label: i18n("XMB settings") }
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
        case "screenshot": hideOverlay(); screenshotTimer.restart(); return
        case "task":       tasksModel.requestActivate(tasksModel.makeModelIndex(item.row)); hideOverlay(); return
        case "none":       return
        case "suspend":    session.suspend(); hideOverlay(); return
        case "hibernate":  session.hibernate(); hideOverlay(); return
        case "reboot":     session.requestReboot(); hideOverlay(); return
        case "shutdown":   session.requestShutdown(); hideOverlay(); return
        case "logout":     session.requestLogout(); hideOverlay(); return
        case "switchuser": session.switchUser(); hideOverlay(); return
        case "lock":       session.lock(); hideOverlay(); return
        case "swapsession": Bigscreen.Global.swapSession(); hideOverlay(); return
        case "volup":      system.volumeStep(true); tick.play(); return
        case "voldown":    system.volumeStep(false); tick.play(); return
        case "briup":      system.brightnessStep(true); tick.play(); return
        case "bridown":    system.brightnessStep(false); tick.play(); return
        case "network":    system.openSettings("kcm_mediacenter_wifi"); hideOverlay(); return
        case "audio":      system.openSettings("kcm_mediacenter_audiodevice"); hideOverlay(); return
        case "allsettings": system.openSettings(""); hideOverlay(); return
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
