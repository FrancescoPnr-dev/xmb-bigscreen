// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// Type-to-search over KRunner (Milou) results, shown at the top of the dashboard.
// Enter or middle-click runs the selection; Esc or emptying the query exits.
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.milou as Milou

FocusScope {
    id: search

    property bool active: false
    signal launched()    // a result was run -> dashboard should close
    signal closed()      // search dismissed -> return focus to the dashboard

    function start(ch) {
        input.text = ch
        active = true
        input.forceActiveFocus()
        input.cursorPosition = input.text.length
    }
    function stop() {
        if (!active) return
        active = false
        input.text = ""
        list.currentIndex = 0
        search.closed()
    }
    function runCurrent() {
        if (list.count > 0 && list.currentIndex >= 0
                && rmodel.run(rmodel.index(list.currentIndex, 0)))
            search.launched()
        search.stop()
    }

    visible: active
    opacity: active ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Milou.ResultsModel { id: rmodel; queryString: input.text; limit: 10 }

    // same font as the dashboard labels (category = level 3, app = level 4)
    Kirigami.Heading { id: queryFont; level: 3; visible: false }

    // Left click outside the query/results dismisses the search (not the dashboard).
    // Middle (wheel) click anywhere runs the highlighted result.
    MouseArea {
        anchors.fill: parent
        enabled: search.active
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) search.runCurrent()
            else search.stop()
        }
    }

    // While searching, the wheel moves the selection and is consumed here so it never
    // reaches the app column underneath.
    WheelHandler {
        enabled: search.active
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            if (event.angleDelta.y > 0) list.decrementCurrentIndex()
            else if (event.angleDelta.y < 0) list.incrementCurrentIndex()
        }
    }

    Column {
        anchors.top: parent.top
        anchors.topMargin: Math.round(search.height * 0.06)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.round(search.width * 0.5)
        spacing: Math.round(search.height * 0.012)

        TextInput {
            id: input
            width: parent.width
            horizontalAlignment: TextInput.AlignHCenter
            color: "white"
            font: queryFont.font
            selectByMouse: true
            onTextEdited: if (text.length === 0) search.stop()
            Keys.onEscapePressed: search.stop()
            Keys.onReturnPressed: search.runCurrent()
            Keys.onEnterPressed: search.runCurrent()
            Keys.onUpPressed: list.decrementCurrentIndex()
            Keys.onDownPressed: list.incrementCurrentIndex()

            Rectangle {   // subtle underline
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -Math.round(search.height * 0.006)
                width: parent.width
                height: 1
                color: Qt.rgba(1, 1, 1, 0.22)
            }
        }

        ListView {
            id: list
            property int rowHeight: Math.round(search.height * 0.05)
            width: parent.width
            // compact, grows with the results, anchored right below the search bar
            height: Math.min(list.count, 9) * list.rowHeight
            clip: true
            model: rmodel
            currentIndex: 0
            interactive: false              // wheel/keys drive the selection, no drag-flick
            keyNavigationEnabled: false

            // Selection pinned near the top; the rest glide under it (XMB feel).
            preferredHighlightBegin: 0
            preferredHighlightEnd: 0
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: 220
            highlightMoveVelocity: -1
            boundsBehavior: Flickable.StopAtBounds

            delegate: Kirigami.Heading {
                id: d
                required property var model
                required property int index
                level: 4
                width: ListView.view ? ListView.view.width : 0
                height: list.rowHeight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: d.model.display
                elide: Text.ElideRight
                color: "white"
                // centred item bright, neighbours fade out (XMB)
                opacity: 1.0 - Math.min(0.72, Math.abs(d.index - list.currentIndex) * 0.26)
                Behavior on opacity { NumberAnimation { duration: 120 } }

                TapHandler {
                    onTapped: { list.currentIndex = d.index; search.runCurrent() }
                }
            }
        }
    }
}
