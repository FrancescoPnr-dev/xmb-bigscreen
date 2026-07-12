// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// PS3-style on-screen keyboard: a passive grid the caller drives with move()
// and activate() from its own key handlers (d-pad arrows and Enter from the
// pad), so it needs no input-method plumbing and works on any text it is
// wired to. Keys are also mouse-tappable.
import QtQuick

Item {
    id: osk

    signal keyPressed(string text)
    signal backspacePressed()
    signal accepted()
    signal dismissed()

    property bool showHideKey: false
    property int page: 0
    property bool shift: false
    property int row: 1
    property int col: 0

    // The optional hide key squeezes into the bottom row, plasma-keyboard style.
    function bottomRow(pageLabel, punct) {
        return showHideKey
            ? [{k:"page",label:pageLabel,w:2},{k:"space",label:"",w:4.5},{t:punct},{k:"hide",label:"⌨︎",w:1.5},{k:"enter",label:"⏎",w:2}]
            : [{k:"page",label:pageLabel,w:2.5},{k:"space",label:"",w:5},{t:punct},{k:"enter",label:"⏎",w:2.5}]
    }
    readonly property var pages: [
        [
            [{t:"1"},{t:"2"},{t:"3"},{t:"4"},{t:"5"},{t:"6"},{t:"7"},{t:"8"},{t:"9"},{t:"0"}],
            [{t:"q"},{t:"w"},{t:"e"},{t:"r"},{t:"t"},{t:"y"},{t:"u"},{t:"i"},{t:"o"},{t:"p"}],
            [{t:"a"},{t:"s"},{t:"d"},{t:"f"},{t:"g"},{t:"h"},{t:"j"},{t:"k"},{t:"l"},{t:"'"}],
            [{k:"shift",label:"⇧",w:1.5},{t:"z"},{t:"x"},{t:"c"},{t:"v"},{t:"b"},{t:"n"},{t:"m"},{k:"back",label:"⌫",w:1.5}],
            bottomRow("&123", ".")
        ],
        [
            [{t:"1"},{t:"2"},{t:"3"},{t:"4"},{t:"5"},{t:"6"},{t:"7"},{t:"8"},{t:"9"},{t:"0"}],
            [{t:"!"},{t:"\""},{t:"£"},{t:"$"},{t:"%"},{t:"&"},{t:"/"},{t:"("},{t:")"},{t:"="}],
            [{t:"+"},{t:"-"},{t:"*"},{t:"_"},{t:":"},{t:";"},{t:"@"},{t:"#"},{t:"?"},{t:"^"}],
            [{t:"à"},{t:"è"},{t:"é"},{t:"ì"},{t:"ò"},{t:"ù"},{t:"ç"},{t:"€"},{k:"back",label:"⌫",w:1.5}],
            bottomRow("abc", ",")
        ]
    ]
    readonly property var rows: pages[page]

    readonly property real unit: width / 12
    readonly property real keyH: Math.round(unit * 0.75)
    readonly property real gap: Math.max(2, Math.round(unit * 0.1))

    implicitHeight: 5 * keyH + 8 * gap

    function reset() { page = 0; shift = false; row = 1; col = 0 }
    onVisibleChanged: if (visible) reset()
    onPageChanged: {
        row = Math.min(row, rows.length - 1)
        col = Math.min(col, rows[row].length - 1)
    }

    function keyUnits(key) { return key.w || 1 }
    function centerOf(r, c) {
        var before = 0, total = 0
        for (var i = 0; i < rows[r].length; i++) {
            var u = keyUnits(rows[r][i])
            if (i < c) before += u
            total += u
        }
        return before + keyUnits(rows[r][c]) / 2 - total / 2
    }

    // Horizontal steps clamp inside the row; vertical steps land on the key
    // whose centre is nearest, so uneven rows still navigate naturally.
    function move(dx, dy) {
        if (dx !== 0)
            col = Math.max(0, Math.min(rows[row].length - 1, col + dx))
        if (dy !== 0) {
            var nr = Math.max(0, Math.min(rows.length - 1, row + dy))
            if (nr !== row) {
                var target = centerOf(row, col), best = 0, bestDist = 1e9
                for (var i = 0; i < rows[nr].length; i++) {
                    var d = Math.abs(centerOf(nr, i) - target)
                    if (d < bestDist) { bestDist = d; best = i }
                }
                row = nr
                col = best
            }
        }
    }

    function activate() {
        var key = rows[row][col]
        if (key.k === "shift")      shift = !shift
        else if (key.k === "page")  page = page === 0 ? 1 : 0
        else if (key.k === "back")  backspacePressed()
        else if (key.k === "hide")  dismissed()
        else if (key.k === "enter") accepted()
        else if (key.k === "space") keyPressed(" ")
        else {
            keyPressed(shift ? key.t.toUpperCase() : key.t)
            shift = false
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: osk.unit * 0.25
        color: Qt.rgba(0.02, 0.04, 0.10, 0.55)
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1
    }

    Column {
        anchors.centerIn: parent
        spacing: osk.gap
        Repeater {
            model: osk.rows.length
            Row {
                id: keyRow
                required property int index
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: osk.gap
                Repeater {
                    model: osk.rows[keyRow.index]
                    Rectangle {
                        id: keyRect
                        required property var modelData
                        required property int index
                        readonly property bool selected: osk.row === keyRow.index && osk.col === index
                        readonly property bool latched: modelData.k === "shift" && osk.shift
                        width: Math.round(osk.keyUnits(modelData) * osk.unit) - osk.gap
                        height: osk.keyH
                        radius: height * 0.18
                        color: selected ? Qt.rgba(1, 1, 1, 0.26)
                             : latched  ? Qt.rgba(1, 1, 1, 0.14)
                                        : Qt.rgba(0, 0, 0, 0.35)
                        border.color: selected ? "white" : Qt.rgba(1, 1, 1, 0.14)
                        border.width: selected ? 2 : 1
                        Text {
                            anchors.centerIn: parent
                            text: keyRect.modelData.label !== undefined ? keyRect.modelData.label
                                : (osk.shift ? keyRect.modelData.t.toUpperCase() : keyRect.modelData.t)
                            color: "white"
                            opacity: keyRect.selected ? 1.0 : 0.78
                            font.pixelSize: Math.round(osk.keyH * 0.44)
                        }
                        TapHandler {
                            onTapped: {
                                osk.row = keyRow.index
                                osk.col = keyRect.index
                                osk.activate()
                            }
                        }
                    }
                }
            }
        }
    }
}
