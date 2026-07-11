// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// System overlay: a layer-shell window over the running app, laid out as a top
// band in the reveal-bar style: power and settings drop-downs, live volume and
// brightness steppers, open apps, back-to-XMB. One UI for controller and mouse.
import QtQuick
import QtQuick.Effects
import org.kde.taskmanager as TaskManager
import org.kde.layershell as LayerShell
import org.kde.bigscreen as Bigscreen

Window {
    id: overlay

    visible: false
    // Single fade driver for the backdrop dim and the content on show.
    property real dim: visible ? 0.5 : 0.0
    Behavior on dim { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
    color: Qt.rgba(0, 0, 0, dim)
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

    readonly property var session: system ? system.session : null
    readonly property int volPct: system ? system.volumePercent : -1
    readonly property int briPct: system ? system.brightnessPercent : -1
    readonly property int labelSize: Math.max(16, Math.round(height * 0.021))

    function showOverlay() {
        visible = true
        overlay.requestActivate()
        expanded = ""
        band.currentIndex = firstTaskIndex()
        content.forceActiveFocus()
    }
    function hideOverlay() {
        expanded = ""
        visible = false
    }
    function toggle() { visible ? hideOverlay() : showOverlay() }
    // Back closes the open drop-down first, then the overlay.
    function back() {
        if (expanded !== "")
            expanded = ""
        else
            hideOverlay()
    }
    function goHome() {
        tasksModel.minimizeAllTasks()
        hideOverlay()
    }

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

    // Non-visual mirror of the open tasks, so the band model stays a plain JS array.
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

    // The band: drop-down anchors first, steppers and quick entries, then open apps.
    // Availability booleans keep the model stable while the percentages change,
    // so stepping a value never resets the ListView and the focus.
    readonly property bool briAvailable: briPct >= 0
    readonly property bool volAvailable: volPct >= 0
    readonly property var bandItems: [
        { act: "power",    label: i18n("Power"),      expand: true },
        { act: "bri",      label: i18n("Brightness"), on: briAvailable },
        { act: "vol",      label: i18n("Volume"),     on: volAvailable },
        { act: "network",  label: i18n("Network") },
        { act: "settings", label: i18n("Settings"),   expand: true }
    ].filter(i => i.on !== false)
     .concat(taskItems)
     .concat([{ act: "home", label: i18n("Back to XMB") }])

    readonly property var powerItems: [
        { act: "suspend",    label: i18n("Sleep"),       on: session ? session.canSuspend : false },
        { act: "hibernate",  label: i18n("Hibernate"),   on: session ? session.canHibernate : false },
        { act: "reboot",     label: i18n("Restart"),     on: session ? session.canReboot : false },
        { act: "shutdown",   label: i18n("Shut down"),   on: session ? session.canShutdown : false },
        { act: "logout",     label: i18n("Log out"),     on: session ? session.canLogout : false },
        { act: "switchuser", label: i18n("Switch user"), on: session ? session.canSwitchUser : false },
        { act: "lock",       label: i18n("Lock"),        on: session ? session.canLock : false },
        { act: "swapsession", label: i18n("Exit to desktop"), on: Bigscreen.Global.launchReason === "swap" }
    ].filter(a => a.on !== false)
    readonly property var settingsItems: [
        { act: "audio",       label: i18n("Audio device") },
        { act: "allsettings", label: i18n("All settings") },
        { act: "config",      label: i18n("XMB settings") }
    ]

    // "" or the act of the open drop-down ("power"/"settings").
    property string expanded: ""
    readonly property var expandedItems:
        expanded === "power" ? powerItems : expanded === "settings" ? settingsItems : []

    function firstTaskIndex() {
        for (var i = 0; i < bandItems.length; i++)
            if (bandItems[i].act === "task")
                return i
        return 0
    }

    function valueLabel(item) {
        if (item.act === "bri") return briPct + "%"
        if (item.act === "vol") return volPct + "%"
        if (item.expand || item.act === "network") return i18n("Open")
        return ""
    }

    function trigger(item) {
        if (!item)
            return
        switch (item.act) {
        case "power":
        case "settings":
            if (expanded === item.act) { expanded = "" } else { expanded = item.act; subList.currentIndex = 0 }
            tick.play(); return
        case "bri":        system.brightnessStep(true); return
        case "vol":        system.volumeStep(true); return
        case "network":    system.openSettings("kcm_mediacenter_wifi"); hideOverlay(); return
        case "task":       tasksModel.requestActivate(tasksModel.makeModelIndex(item.row)); hideOverlay(); return
        case "home":       goHome(); return
        case "suspend":    session.suspend(); hideOverlay(); return
        case "hibernate":  session.hibernate(); hideOverlay(); return
        case "reboot":     session.requestReboot(); hideOverlay(); return
        case "shutdown":   session.requestShutdown(); hideOverlay(); return
        case "logout":     session.requestLogout(); hideOverlay(); return
        case "switchuser": session.switchUser(); hideOverlay(); return
        case "lock":       session.lock(); hideOverlay(); return
        case "swapsession": Bigscreen.Global.swapSession(); hideOverlay(); return
        case "audio":      system.openSettings("kcm_mediacenter_audiodevice"); hideOverlay(); return
        case "allsettings": system.openSettings(""); hideOverlay(); return
        case "config":     configRequested(); hideOverlay(); return
        }
    }

    // Up/down on the steppers adjusts; on a drop-down anchor it opens/navigates.
    function stepCurrent(up) {
        var item = bandItems[band.currentIndex]
        if (!item) return
        if (item.act === "bri") { system.brightnessStep(up); tick.play() }
        else if (item.act === "vol") { system.volumeStep(up); tick.play() }
        else if (!up && item.expand && expanded === "") trigger(item)
    }

    function selectBand(index) {
        index = Math.max(0, Math.min(bandItems.length - 1, index))
        if (index === band.currentIndex)
            return
        if (expanded !== "")
            expanded = ""
        band.currentIndex = index
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
        opacity: overlay.dim / 0.5

        // Click on the dimmed app below closes; taps in the band/drop-down zone
        // are handled by the delegates.
        TapHandler {
            onTapped: (eventPoint) => {
                var zone = overlay.expanded !== "" ? overlay.height * 0.55 : band.height * 2
                if (eventPoint.position.y > zone)
                    overlay.hideOverlay()
            }
        }

        // Scrim so the band reads over bright apps.
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: band.height * 3
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.6) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ListView {
            id: band
            orientation: ListView.Horizontal
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: Math.round(overlay.height * 0.025)
            anchors.leftMargin: Math.round(overlay.width * 0.03)
            anchors.rightMargin: Math.round(overlay.width * 0.03)
            height: Math.round(overlay.labelSize * 4)
            spacing: Math.round(overlay.labelSize * 2.2)
            interactive: false
            keyNavigationEnabled: false
            model: overlay.bandItems
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem

                width: Math.min(mainLabel.implicitWidth, overlay.labelSize * 12)
                height: band.height

                property real glowPulse: 0.0
                SequentialAnimation on glowPulse {
                    running: cell.current && overlay.visible
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.30; to: 0.90; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.90; to: 0.30; duration: 1500; easing.type: Easing.InOutSine }
                }

                // Fixed rows, so cells with and without a value line share the baseline.
                Text {
                    id: mainLabel
                    y: Math.round(band.height * 0.5 - overlay.labelSize * 0.9)
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: cell.modelData.label
                    color: "white"
                    opacity: cell.current ? 1.0 : 0.6
                    font.pixelSize: overlay.labelSize
                    font.weight: Font.Light
                    font.letterSpacing: 1
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, overlay.labelSize * 12)
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    layer.enabled: cell.current
                    layer.effect: MultiEffect {
                        autoPaddingEnabled: true
                        blurMax: 24
                        shadowEnabled: true
                        shadowColor: "white"
                        shadowBlur: 1.0
                        shadowVerticalOffset: 0
                        shadowHorizontalOffset: 0
                        shadowOpacity: cell.glowPulse
                    }
                }
                Text {
                    anchors.top: mainLabel.bottom
                    anchors.topMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: overlay.valueLabel(cell.modelData)
                    color: "white"
                    opacity: cell.current && text.length > 0 ? 0.9 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    font.pixelSize: Math.round(overlay.labelSize * 0.8)
                    font.weight: Font.Light
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: if (hovered) overlay.selectBand(cell.index)
                }
                TapHandler {
                    onTapped: overlay.trigger(cell.modelData)
                }
                WheelHandler {
                    enabled: cell.modelData.act === "bri" || cell.modelData.act === "vol"
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (event) => overlay.stepCurrent(event.angleDelta.y > 0)
                }
            }
        }

        // Drop-down column under the expanded band entry, reveal-bar style.
        ListView {
            id: subList
            visible: overlay.expanded !== ""
            x: {
                var base = band.currentItem
                    ? band.anchors.leftMargin + band.currentItem.x - band.contentX : band.anchors.leftMargin
                return Math.max(band.anchors.leftMargin,
                                Math.min(base, overlay.width - width - band.anchors.leftMargin))
            }
            anchors.top: band.bottom
            anchors.topMargin: Math.round(overlay.labelSize * 0.6)
            width: Math.round(overlay.labelSize * 14)
            height: contentHeight
            spacing: Math.round(overlay.labelSize * 0.9)
            interactive: false
            keyNavigationEnabled: false
            model: overlay.expandedItems

            delegate: Item {
                id: subRow
                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem

                width: subList.width
                height: Math.round(overlay.labelSize * 1.4)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: subRow.modelData.label
                    color: "white"
                    opacity: subRow.current ? 1.0 : 0.6
                    font.pixelSize: overlay.labelSize
                    font.weight: Font.Light
                    font.letterSpacing: 1
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: if (hovered) subList.currentIndex = subRow.index
                }
                TapHandler {
                    onTapped: overlay.trigger(subRow.modelData)
                }
            }
        }

        Keys.onLeftPressed: overlay.selectBand(band.currentIndex - 1)
        Keys.onRightPressed: overlay.selectBand(band.currentIndex + 1)
        Keys.onUpPressed: {
            if (overlay.expanded !== "") {
                var i = subList.currentIndex
                subList.decrementCurrentIndex()
                if (subList.currentIndex !== i) tick.play()
            } else {
                overlay.stepCurrent(true)
            }
        }
        Keys.onDownPressed: {
            if (overlay.expanded !== "") {
                var i = subList.currentIndex
                subList.incrementCurrentIndex()
                if (subList.currentIndex !== i) tick.play()
            } else {
                overlay.stepCurrent(false)
            }
        }
        Keys.onReturnPressed: overlay.expanded !== ""
            ? overlay.trigger(overlay.expandedItems[subList.currentIndex])
            : overlay.trigger(overlay.bandItems[band.currentIndex])
        Keys.onEnterPressed: overlay.expanded !== ""
            ? overlay.trigger(overlay.expandedItems[subList.currentIndex])
            : overlay.trigger(overlay.bandItems[band.currentIndex])
        Keys.onEscapePressed: overlay.back()
    }
}
