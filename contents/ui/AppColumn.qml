// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// Vertical arm of the cross: the current app pins at the intersection and the list
// glides around it; category changes swap the model, reset to the top and cross-fade.
import QtQuick

Item {
    id: column

    property int iconSize: 56
    property real intersectionY: height * 0.5    // fixed pin point (y of the cross)
    property alias model: list.model
    property alias currentIndex: list.currentIndex
    property alias count: list.count
    property bool wheelLocked: false

    signal appLaunched()
    signal navigated()

    readonly property int cellHeight: Math.round(iconSize * 1.45)
    readonly property real listSpacing: Math.round(iconSize * 0.30)

    // Category-row geometry, so apps scrolled above the selection can clear the icon.
    property real categoryCenterY: 0
    property int  categoryIconSize: 112

    readonly property real selectedAppScale: 1.15

    // Lift for apps above the selection, so the first one sits just above the category
    // icon (the rest stack above it) — the PS3 "gap" where above-apps jump over it.
    readonly property real aboveGap: {
        var naturalAboveCenter = intersectionY - (cellHeight + listSpacing)
        var categoryTop = categoryCenterY - categoryIconSize / 2
        var desiredAboveCenter = categoryTop - cellHeight / 2 - Math.round(iconSize * 0.25)
        return Math.max(0, naturalAboveCenter - desiredAboveCenter)
    }

    // Set for Favourites, whose ListModel has no trigger(); called with the current row.
    property var launchHandler: null


    function up()   { var i = list.currentIndex; list.decrementCurrentIndex(); if (list.currentIndex !== i) navigated() }
    function down() { var i = list.currentIndex; list.incrementCurrentIndex(); if (list.currentIndex !== i) navigated() }
    function launchCurrent() {
        if (list.currentIndex < 0)
            return
        if (column.launchHandler) {
            column.launchHandler(list.currentIndex)
            column.appLaunched()
        } else if (list.model) {
            list.model.trigger(list.currentIndex, "", null)
            column.appLaunched()
        }
    }

    // On category change, land on the first app pinned at the cross. positionViewAtIndex
    // (not positionViewAtBeginning) so index 0 snaps to the highlight, not the view top.
    onModelChanged: {
        list.currentIndex = 0
        list.positionViewAtIndex(0, ListView.SnapPosition)
        fade.restart()
    }

    ListView {
        id: list
        anchors.fill: parent
        spacing: column.listSpacing
        currentIndex: 0
        keyNavigationEnabled: false
        // Non-interactive on purpose: inertial flicks would overshoot; Dashboard's
        // WheelHandler steps it one app per notch instead.
        interactive: false

        // Pin the current app to the intersection; glide the rest around it.
        preferredHighlightBegin: column.intersectionY - column.cellHeight / 2
        preferredHighlightEnd: column.intersectionY - column.cellHeight / 2
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 240
        highlightMoveVelocity: -1
        boundsBehavior: Flickable.StopAtBounds

        delegate: XmbItemDelegate {
            required property string display
            required property var decoration
            required property int index

            width: list.width
            height: column.cellHeight
            labelBelow: false
            iconSize: column.iconSize
            iconSource: decoration
            label: display
            selected: ListView.isCurrentItem
            // Only the centred app is clickable; the rest are reached via the wheel.
            interactive: ListView.isCurrentItem
            neighbourDistance: Math.abs(index - list.currentIndex)
            extraTranslateY: index < list.currentIndex ? -column.aboveGap : 0
            selectedScale: column.selectedAppScale
            glowWhenSelected: true

            onClicked: column.launchCurrent()
        }

        NumberAnimation {
            id: fade
            target: list
            property: "opacity"
            from: 0.0; to: 1.0
            duration: 260
            easing.type: Easing.OutCubic
        }
    }
}
