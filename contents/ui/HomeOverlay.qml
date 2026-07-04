// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// Home overlay: a layer-shell window over the running app showing open apps to
// switch between, plus "back to XMB" (minimise everything).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
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

    function showOverlay() {
        visible = true
        overlay.requestActivate()
        list.forceActiveFocus()
    }
    function hideOverlay() { visible = false }
    function toggle() { visible ? hideOverlay() : showOverlay() }
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

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.8, 1400)
        spacing: Kirigami.Units.gridUnit

        QQC2.Label {
            Layout.leftMargin: Kirigami.Units.gridUnit
            text: tasksModel.count > 0 ? i18n("Open apps") : i18n("No open apps")
            color: "white"
            font.pixelSize: 34
            font.weight: Font.Light
        }

        ListView {
            id: list
            visible: tasksModel.count > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 10
            orientation: ListView.Horizontal
            spacing: Kirigami.Units.largeSpacing
            clip: true
            model: tasksModel
            keyNavigationWraps: true
            KeyNavigation.down: homeButton

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
                    color: tile.current ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.06)
                    border.width: tile.current ? 2 : 0
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
                    onTapped: { list.currentIndex = tile.index; overlay.activateCurrent() }
                }
            }

            Keys.onReturnPressed: overlay.activateCurrent()
            Keys.onEnterPressed: overlay.activateCurrent()
        }

        QQC2.Button {
            id: homeButton
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Back to XMB")
            icon.name: "go-home"
            focus: tasksModel.count === 0
            KeyNavigation.up: list
            onClicked: overlay.goHome()
        }
    }

    function activateCurrent() {
        if (list.currentIndex < 0)
            return
        tasksModel.requestActivate(tasksModel.makeModelIndex(list.currentIndex))
        hideOverlay()
    }

    // If the last app closes while open, there's nothing to switch to: reveal the XMB.
    Connections {
        target: tasksModel
        function onCountChanged() {
            if (overlay.visible && tasksModel.count === 0)
                overlay.hideOverlay()
        }
    }

    Keys.onEscapePressed: hideOverlay()
}
