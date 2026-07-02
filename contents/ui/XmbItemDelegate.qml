// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// Icon + label cell shared by the category bar and the app column. It owns the XMB
// focus emphasis (selected item big and opaque, neighbours shrink and fade), animated
// here so both views feel the same. The view only sets `selected` and `neighbourDistance`.
import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Item {
    id: delegate

    property var iconSource: ""
    property string label: ""
    property int iconSize: 64
    property bool selected: false
    property int neighbourDistance: 0    // 0 = selected, 1 = adjacent, ...
    property bool labelBelow: true       // true: category style (label under icon), false: app style
    property bool interactive: true      // false: no hover cursor / no click (categories)

    signal clicked()

    // We scale (not resize) so layout spacing stays constant and dimmed neighbours leave
    // the classic XMB gaps. selectedScale is 1.0 for categories; the app column raises it.
    property real selectedScale: 1.0
    property real emphasis: selected ? selectedScale : 0.66
    opacity: selected ? 1.0 : Math.max(0.30, 0.85 - neighbourDistance * 0.18)

    Behavior on emphasis { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on opacity  { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // Slow PS3 "breathing" glow on the focused label; animates only while selected.
    property bool glowWhenSelected: false
    property real glowPulse: 0.0
    SequentialAnimation on glowPulse {
        running: delegate.glowWhenSelected && delegate.selected
        loops: Animation.Infinite
        NumberAnimation { from: 0.30; to: 0.90; duration: 1500; easing.type: Easing.InOutSine }
        NumberAnimation { from: 0.90; to: 0.30; duration: 1500; easing.type: Easing.InOutSine }
    }

    // Lift applied to apps above the selection, so they clear the category icon and
    // stack above it instead of sliding over it. Stays 0 for the category bar.
    property real extraTranslateY: 0
    Behavior on extraTranslateY { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    // App style scales around the icon centre (not the wide delegate centre), so shrunken
    // apps stay on the category's vertical line instead of drifting sideways.
    transform: [
        Scale {
            origin.x: delegate.labelBelow ? delegate.width / 2 : delegate.iconSize / 2
            origin.y: delegate.height / 2
            xScale: delegate.emphasis
            yScale: delegate.emphasis
        },
        Translate { y: delegate.extraTranslateY }
    ]

    // category style: icon with a label underneath
    Column {
        visible: delegate.labelBelow
        anchors.centerIn: parent
        spacing: Math.round(delegate.iconSize * 0.02)

        Kirigami.Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            width: delegate.iconSize
            height: delegate.iconSize
            source: delegate.iconSource
            smooth: true
        }
        Kirigami.Heading {
            anchors.horizontalCenter: parent.horizontalCenter
            level: 3
            text: delegate.label
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            width: Math.min(implicitWidth, delegate.iconSize * 2.2)
        }
    }

    // app style: icon on the left, label to the right
    Row {
        id: appRow
        visible: !delegate.labelBelow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        spacing: Math.round(delegate.iconSize * 0.35)

        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            width: delegate.iconSize
            height: delegate.iconSize
            source: delegate.iconSource
            smooth: true
        }
        Kirigami.Heading {
            anchors.verticalCenter: parent.verticalCenter
            level: 4
            text: delegate.label
            color: "white"
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 420)

            // Soft breathing halo on the selected app; MultiEffect draws the blur behind
            // the crisp text.
            layer.enabled: delegate.glowWhenSelected && delegate.selected
            layer.effect: MultiEffect {
                autoPaddingEnabled: true
                blurMax: 32
                shadowEnabled: true
                shadowColor: "white"
                shadowBlur: 1.0
                shadowVerticalOffset: 0
                shadowHorizontalOffset: 0
                shadowOpacity: delegate.glowPulse
            }
        }
    }

    MouseArea {
        // App style: cover just the icon+label so the hand cursor / click area matches the
        // app, not the full column width. Category style: fill the cell to swallow stray
        // clicks (so they don't fall through and close the dashboard).
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: delegate.labelBelow ? delegate.width : appRow.width
        height: delegate.labelBelow ? delegate.height : appRow.height
        hoverEnabled: delegate.interactive
        cursorShape: delegate.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (delegate.interactive) delegate.clicked()
    }
}
