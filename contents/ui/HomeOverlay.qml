// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// System overlay: a top band with the system controls and drop-downs, plus a
// centred alt-tab row of live app previews. Up/down switches between the two.
import QtQuick
import QtQuick.Effects
import org.kde.taskmanager as TaskManager
import org.kde.layershell as LayerShell
import org.kde.bigscreen as Bigscreen
import org.kde.pipewire as PipeWire
import org.kde.kirigami as Kirigami

Window {
    id: overlay

    visible: false
    // Single fade driver for the backdrop dim and the content on show.
    property real dim: visible ? 0.6 : 0.0
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

    // Focus zone: the top band or the app cards. Up/down only ever moves zones;
    // steppers adjust with left/right after Enter (engaged).
    property string zone: "band"
    property bool engaged: false
    property bool closePrompt: false

    function showOverlay() {
        visible = true
        overlay.requestActivate()
        expanded = ""
        engaged = false
        closePrompt = false
        band.currentIndex = 0
        cards.currentIndex = 0
        zone = taskItems.length > 0 ? "cards" : "band"
        content.forceActiveFocus()
    }
    function hideOverlay() {
        expanded = ""
        engaged = false
        closePrompt = false
        confirmLogout = false
        visible = false
    }
    function toggle() { visible ? hideOverlay() : showOverlay() }
    // Back unwinds one step at a time: adjustment, close prompt, drop-down, overlay.
    function back() {
        if (engaged)
            engaged = false
        else if (confirmLogout)
            confirmLogout = false
        else if (closePrompt)
            closePrompt = false
        else if (expanded !== "")
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
        // Match the native Bigscreen switcher (unfiltered): filterHidden would drop
        // minimized windows, so "Back to XMB" apps vanish from the cards.
        filterHidden: false

        function minimizeAllTasks() {
            for (var i = 0; i < tasksModel.count; i++) {
                var idx = tasksModel.makeModelIndex(i)
                if (!tasksModel.data(idx, TaskManager.AbstractTasksModel.IsMinimized))
                    tasksModel.requestToggleMinimized(idx)
            }
        }
    }

    // Non-visual mirror of the open tasks; the uuid feeds the live preview stream.
    property var taskItems: []
    onTaskItemsChanged: {
        if (taskItems.length === 0 && zone === "cards") {
            closePrompt = false
            zone = "band"
        }
    }
    Instantiator {
        id: taskSource
        model: tasksModel
        delegate: QtObject {
            required property var model
        }
        onObjectAdded: Qt.callLater(overlay.rebuildTaskItems)
        onObjectRemoved: Qt.callLater(overlay.rebuildTaskItems)
    }
    function rebuildTaskItems() {
        var arr = []
        for (var i = 0; i < taskSource.count; i++) {
            var o = taskSource.objectAt(i)
            if (!o)
                continue
            var ids = o.model.WinIdList
            arr.push({ row: o.model.index, label: o.model.display || "",
                       icon: o.model.decoration,
                       uuid: ids && ids.length > 0 ? String(ids[0]) : "" })
        }
        taskItems = arr
    }
    function closeTask(row) {
        closePrompt = false
        tasksModel.requestClose(tasksModel.makeModelIndex(row))
    }
    function activateTask(row) {
        tasksModel.requestActivate(tasksModel.makeModelIndex(row))
        hideOverlay()
    }

    readonly property bool briAvailable: briPct >= 0
    readonly property bool volAvailable: volPct >= 0
    readonly property var bandItems: [
        { act: "power",    label: i18n("Power"),      expand: true },
        { act: "bri",      label: i18n("Brightness"), stepper: true, on: briAvailable },
        { act: "vol",      label: i18n("Volume"),     stepper: true, on: volAvailable },
        { act: "network",  label: i18n("Network") },
        { act: "settings", label: i18n("Settings"),   expand: true },
        { act: "home",     label: i18n("Back to XMB") }
    ].filter(i => i.on !== false)

    // No Lock or Switch user: they land on password screens a pad cannot drive.
    readonly property var powerItems: [
        { act: "suspend",    label: i18n("Sleep"),       on: session ? session.canSuspend : false },
        { act: "reboot",     label: i18n("Restart"),     on: session ? session.canReboot : false },
        { act: "shutdown",   label: i18n("Shut down"),   on: session ? session.canShutdown : false },
        { act: "logout",     label: i18n("Log out"),     on: session ? session.canLogout : false },
        { act: "swapsession", label: i18n("Exit to desktop"), on: Bigscreen.Global.launchReason === "swap" }
    ].filter(a => a.on !== false)
    readonly property var settingsItems: [
        { act: "allsettings", label: i18n("System settings") },
        { act: "config",      label: i18n("XMB settings") }
    ]

    // "" or the act of the open drop-down ("power"/"settings").
    property string expanded: ""
    // Log out is armed on the first press and fires on the second, with a warning
    // in between: the login screen is unreachable by pad, only a reboot comes back.
    property bool confirmLogout: false
    onExpandedChanged: confirmLogout = false
    readonly property var expandedItems:
        expanded === "power" ? powerItems : expanded === "settings" ? settingsItems : []

    function valueLabel(item) {
        if (item.act === "bri")
            return engaged && bandCurrentAct() === "bri" ? "◂ " + briPct + "% ▸" : briPct + "%"
        if (item.act === "vol")
            return engaged && bandCurrentAct() === "vol" ? "◂ " + volPct + "% ▸" : volPct + "%"
        if (item.expand || item.act === "network") return i18n("Open")
        return ""
    }
    function bandCurrentAct() {
        var item = bandItems[band.currentIndex]
        return item ? item.act : ""
    }

    function trigger(item) {
        if (!item)
            return
        switch (item.act) {
        case "power":
        case "settings":
            if (expanded === item.act) { expanded = "" } else { expanded = item.act; subList.currentIndex = 0 }
            tick.play(); return
        case "bri":
        case "vol":
            engaged = !engaged; tick.play(); return
        case "network":    system.openSettings("kcm_mediacenter_wifi"); hideOverlay(); return
        case "home":       goHome(); return
        case "suspend":    session.suspend(); hideOverlay(); return
        case "reboot":     session.requestReboot(); hideOverlay(); return
        case "shutdown":   session.requestShutdown(); hideOverlay(); return
        case "logout":
            if (!confirmLogout) { confirmLogout = true; tick.play(); return }
            session.requestLogout(); hideOverlay(); return
        case "swapsession": Bigscreen.Global.swapSession(); hideOverlay(); return
        case "allsettings": system.openSettings(""); hideOverlay(); return
        case "config":     configRequested(); hideOverlay(); return
        }
    }

    function stepEngaged(up) {
        var act = bandCurrentAct()
        if (act === "bri") { system.brightnessStep(up); tick.play() }
        else if (act === "vol") { system.volumeStep(up); tick.play() }
    }

    function selectBand(index) {
        index = Math.max(0, Math.min(bandItems.length - 1, index))
        if (index === band.currentIndex)
            return
        expanded = ""
        engaged = false
        band.currentIndex = index
        tick.play()
    }
    function selectCard(index) {
        index = Math.max(0, Math.min(taskItems.length - 1, index))
        closePrompt = false
        if (index === cards.currentIndex)
            return
        cards.currentIndex = index
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
        opacity: overlay.dim / 0.6

        // Click on the dim backdrop closes; band and cards handle their own taps.
        TapHandler {
            onTapped: (eventPoint) => {
                var inCards = taskItems.length > 0
                    && Math.abs(eventPoint.position.y - cards.y - cards.height / 2) < cards.height / 2
                var inBand = eventPoint.position.y < band.height * (overlay.expanded !== "" ? 4 : 2)
                if (!inCards && !inBand)
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
            // Centred while the items fit; a translate keeps the full-width viewport,
            // so delegates instantiate and contentWidth stays accurate.
            readonly property real centerOffset: Math.max(0, (width - contentWidth) / 2)
            transform: Translate { x: band.centerOffset }
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
                readonly property bool focused: current && overlay.zone === "band"

                width: Math.min(mainLabel.implicitWidth, overlay.labelSize * 12)
                height: band.height

                property real glowPulse: 0.0
                SequentialAnimation on glowPulse {
                    running: cell.focused && overlay.visible
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
                    opacity: cell.focused ? 1.0 : cell.current ? 0.8 : 0.6
                    font.pixelSize: overlay.labelSize
                    font.weight: Font.Light
                    font.letterSpacing: 1
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, overlay.labelSize * 12)
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    layer.enabled: cell.focused
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
                    opacity: cell.focused && text.length > 0 ? 0.9 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    font.pixelSize: Math.round(overlay.labelSize * 0.8)
                    font.weight: Font.Light
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: if (hovered) { overlay.zone = "band"; overlay.selectBand(cell.index) }
                }
                TapHandler {
                    onTapped: overlay.trigger(cell.modelData)
                }
                WheelHandler {
                    enabled: cell.modelData.stepper === true
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (event) => {
                        if (cell.modelData.act === "bri") overlay.system.brightnessStep(event.angleDelta.y > 0)
                        else overlay.system.volumeStep(event.angleDelta.y > 0)
                    }
                }
            }
        }

        // Drop-down column under the expanded band entry.
        ListView {
            id: subList
            visible: overlay.expanded !== ""
            x: {
                var base = band.currentItem
                    ? band.x + band.centerOffset + band.currentItem.x - band.contentX
                    : band.x + band.centerOffset
                return Math.max(band.x, Math.min(base, overlay.width - width - band.x))
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

        Text {
            visible: overlay.confirmLogout
            x: subList.x
            anchors.top: subList.bottom
            anchors.topMargin: Math.round(overlay.labelSize * 0.9)
            width: Math.round(overlay.labelSize * 18)
            wrapMode: Text.WordWrap
            text: i18n("The login screen needs a mouse and keyboard; without them, restart the machine to come back. Press again to log out.")
            color: "white"
            opacity: 0.85
            font.pixelSize: Math.round(overlay.labelSize * 0.72)
            font.weight: Font.Light
        }

        Text {
            anchors.centerIn: parent
            visible: overlay.taskItems.length === 0
            text: i18n("No open apps")
            color: "white"
            opacity: 0.5
            font.pixelSize: Math.round(overlay.labelSize * 1.3)
            font.weight: Font.Light
            font.letterSpacing: 1
        }

        // Centred row of open apps with live window previews.
        ListView {
            id: cards
            orientation: ListView.Horizontal
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: Math.round(overlay.height * 0.03)
            anchors.leftMargin: Math.round(overlay.width * 0.03)
            anchors.rightMargin: Math.round(overlay.width * 0.03)
            readonly property int cardH: Math.round(overlay.height * 0.28)
            readonly property int cardW: Math.round(cardH * 16 / 9)
            readonly property real centerOffset: Math.max(0, (width - contentWidth) / 2)
            transform: Translate { x: cards.centerOffset }
            height: cardH + Math.round(overlay.labelSize * 4.4)
            spacing: Math.round(overlay.labelSize * 1.6)
            interactive: false
            keyNavigationEnabled: false
            model: overlay.taskItems
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Item {
                id: card
                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem
                readonly property bool focused: current && overlay.zone === "cards"

                width: cards.cardW
                height: cards.height

                scale: focused ? 1.0 : 0.92
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                property real glowPulse: 0.0
                SequentialAnimation on glowPulse {
                    running: card.focused && overlay.visible
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.35; to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.0; to: 0.35; duration: 1500; easing.type: Easing.InOutSine }
                }

                Rectangle {
                    id: frame
                    width: cards.cardW
                    height: cards.cardH
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: card.focused ? 2 : 1
                    border.color: card.focused ? Qt.rgba(1, 1, 1, 0.45 + 0.55 * card.glowPulse)
                                               : Qt.rgba(1, 1, 1, 0.25)
                    clip: true

                    // Live preview stream, only while the overlay is up; icon fallback.
                    Loader {
                        anchors.fill: parent
                        anchors.margins: frame.border.width
                        active: overlay.visible && card.modelData.uuid.length > 0
                        sourceComponent: Item {
                            TaskManager.ScreencastingRequest {
                                id: castRequest
                                uuid: card.modelData.uuid
                            }
                            PipeWire.PipeWireSourceItem {
                                anchors.fill: parent
                                nodeId: castRequest.nodeId
                                visible: castRequest.nodeId > 0
                            }
                        }
                    }
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Math.round(cards.cardH * 0.4)
                        height: width
                        source: card.modelData.icon
                        opacity: 0.9
                    }
                }

                Text {
                    anchors.top: frame.bottom
                    anchors.topMargin: Math.round(overlay.labelSize * 0.7)
                    anchors.horizontalCenter: frame.horizontalCenter
                    text: card.modelData.label
                    color: "white"
                    opacity: card.focused ? 1.0 : 0.55
                    font.pixelSize: overlay.labelSize
                    font.weight: Font.Light
                    font.letterSpacing: 1
                    elide: Text.ElideMiddle
                    width: Math.min(implicitWidth, cards.cardW)
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                // Always shown under the card; breathes when armed (down on the
                // focused card), like the dashboard's selected-item glow.
                Text {
                    id: closeLabel
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: frame.horizontalCenter
                    readonly property bool armed: card.focused && overlay.closePrompt
                    text: i18n("Close")
                    color: "white"
                    font.pixelSize: Math.round(overlay.labelSize * 0.9)
                    font.weight: Font.Light
                    font.letterSpacing: 1

                    property real pulse: 0.35
                    SequentialAnimation on pulse {
                        running: closeLabel.armed && overlay.visible
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.35; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.0; to: 0.35; duration: 800; easing.type: Easing.InOutSine }
                    }
                    opacity: armed ? (0.55 + 0.45 * pulse) : (card.focused ? 0.6 : 0.28)
                    Behavior on opacity { enabled: !closeLabel.armed; NumberAnimation { duration: 140 } }

                    layer.enabled: armed
                    layer.effect: MultiEffect {
                        autoPaddingEnabled: true
                        blurMax: 24
                        shadowEnabled: true
                        shadowColor: "white"
                        shadowBlur: 1.0
                        shadowVerticalOffset: 0
                        shadowHorizontalOffset: 0
                        shadowOpacity: closeLabel.pulse
                    }

                    TapHandler {
                        onTapped: overlay.closeTask(card.modelData.row)
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: if (hovered) { overlay.zone = "cards"; overlay.selectCard(card.index) }
                }
                TapHandler {
                    onTapped: {
                        if (overlay.closePrompt && card.current)
                            overlay.closePrompt = false
                        else
                            overlay.activateTask(card.modelData.row)
                    }
                }
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: overlay.closeTask(card.modelData.row)
                }
            }
        }

        Keys.onLeftPressed: {
            if (overlay.engaged)
                overlay.stepEngaged(false)
            else if (overlay.zone === "cards")
                overlay.selectCard(cards.currentIndex - 1)
            else
                overlay.selectBand(band.currentIndex - 1)
        }
        Keys.onRightPressed: {
            if (overlay.engaged)
                overlay.stepEngaged(true)
            else if (overlay.zone === "cards")
                overlay.selectCard(cards.currentIndex + 1)
            else
                overlay.selectBand(band.currentIndex + 1)
        }
        Keys.onUpPressed: {
            if (overlay.engaged) {
                overlay.engaged = false
            } else if (overlay.expanded !== "") {
                overlay.confirmLogout = false
                var i = subList.currentIndex
                subList.decrementCurrentIndex()
                if (subList.currentIndex !== i) tick.play()
            } else if (overlay.closePrompt) {
                overlay.closePrompt = false
            } else if (overlay.zone === "cards") {
                overlay.zone = "band"
                tick.play()
            }
        }
        Keys.onDownPressed: {
            if (overlay.engaged) {
                overlay.engaged = false
            } else if (overlay.expanded !== "") {
                overlay.confirmLogout = false
                var i = subList.currentIndex
                subList.incrementCurrentIndex()
                if (subList.currentIndex !== i) tick.play()
            } else if (overlay.zone === "band") {
                if (overlay.taskItems.length > 0) {
                    overlay.zone = "cards"
                    tick.play()
                }
            } else if (!overlay.closePrompt) {
                overlay.closePrompt = true
                tick.play()
            }
        }
        Keys.onReturnPressed: content.activate()
        Keys.onEnterPressed: content.activate()
        Keys.onEscapePressed: overlay.back()

        function activate() {
            if (overlay.engaged) {
                overlay.engaged = false
            } else if (overlay.expanded !== "") {
                overlay.trigger(overlay.expandedItems[subList.currentIndex])
            } else if (overlay.zone === "cards") {
                var task = overlay.taskItems[cards.currentIndex]
                if (!task)
                    return
                if (overlay.closePrompt)
                    overlay.closeTask(task.row)
                else
                    overlay.activateTask(task.row)
            } else {
                overlay.trigger(overlay.bandItems[band.currentIndex])
            }
        }
    }
}
