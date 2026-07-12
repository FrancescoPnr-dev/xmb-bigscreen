// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// The XMB settings window, styled after Plasma Bigscreen's own TV settings: a
// left sidebar of sections and a right pane of native Bigscreen delegates.
// Writes straight into the plasmoid configuration, so the wave/RGB preview is
// live behind the semi-transparent window.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.bigscreen as Bigscreen
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.kicker as Kicker
import org.kde.kitemmodels as KItemModels
import org.kde.layershell as LayerShell
import "i18n-catalogs.js" as Catalogs

Window {
    id: win

    // Injected by main.qml: the live plasmoid configuration object.
    property var config: null
    property var translate: (s) => s
    signal iconThemeWriteRequested(string theme)

    visible: false
    property real dim: visible ? 0.62 : 0.0
    Behavior on dim { NumberAnimation { duration: 180; easing.type: Easing.OutQuad } }
    color: Qt.rgba(0, 0, 0, dim)
    flags: Qt.FramelessWindowHint

    LayerShell.Window.scope: "overlay"
    LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom
                             | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
    LayerShell.Window.layer: LayerShell.Window.LayerOverlay
    LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityOnDemand
    LayerShell.Window.exclusionZone: -1

    Kirigami.Theme.colorSet: Kirigami.Theme.View
    Kirigami.Theme.inherit: false

    property var engagedRow: null

    function show() {
        visible = true
        win.requestActivate()
        engagedRow = null
        sidebar.forceActiveFocus()
        iconThemeQuery.refresh()
        stickSwapQuery.refresh()
    }
    function hide() {
        engagedRow = null
        visible = false
    }
    function toggle() { visible ? hide() : show() }
    function back() {
        if (engagedRow) { engagedRow = null; return }
        if (win.activeFocusItem && win.activeFocusItem !== sidebar && !isDescendant(win.activeFocusItem, sidebar)) {
            sidebar.forceActiveFocus()
            return
        }
        hide()
    }
    function focusSidebar() { engagedRow = null; sidebar.forceActiveFocus() }
    function isDescendant(item, ancestor) {
        while (item) { if (item === ancestor) return true; item = item.parent }
        return false
    }

    // ---- configuration defaults (kept in sync with contents/config/main.xml) ----
    readonly property var defaults: ({
        backgroundOpacity: 1.0, categoryIconSize: 112, appIconSize: 56, intersectionXFraction: 0.30,
        waveColorR: 37, waveColorG: 89, waveColorB: 179,
        clockTimeFormat: 0, clockDateFormat: 0, clockShowDate: true,
        navSoundMode: 0, navSoundVolume: 0.5, ambientSoundMode: 0, ambientSoundVolume: 0.5,
        language: "", iconTheme: ""
    })
    function getCfg(key) { return config ? config[key] : defaults[key] }
    function setCfg(key, value) { if (config) config[key] = value }
    function resetKeys(keys) { for (var i = 0; i < keys.length; i++) setCfg(keys[i], defaults[keys[i]]) }

    // ---- icon theme enumeration + persistence ----
    property var iconThemes: [{ id: "", name: win.translate("System default") }]
    P5Support.DataSource {
        id: iconThemeQuery
        engine: "executable"
        function refresh() {
            connectSource("sh -c 'for base in /usr/share/icons \"$HOME/.local/share/icons\"; do "
                + "[ -d \"$base\" ] || continue; for d in \"$base\"/*/; do t=\"${d%/}\"; f=\"$t/index.theme\"; "
                + "[ -f \"$f\" ] || continue; grep -q \"^Directories=.\" \"$f\" || continue; "
                + "grep -q \"^Hidden=true\" \"$f\" && continue; "
                + "n=$(grep -m1 \"^Name=\" \"$f\" | cut -d= -f2-); "
                + "printf \"%s\\t%s\\n\" \"$(basename \"$t\")\" \"${n:-$(basename \"$t\")}\"; done; done | sort -u'")
        }
        onNewData: (src, data) => {
            var arr = [{ id: "", name: win.translate("System default") }]
            var out = ((data["stdout"] || "") + "").trim()
            if (out.length > 0) {
                var lines = out.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var p = lines[i].split("\t")
                    if (p[0]) arr.push({ id: p[0], name: p[1] || p[0] })
                }
            }
            win.iconThemes = arr
            disconnectSource(src)
        }
    }
    P5Support.DataSource {
        id: iconThemeWriter
        engine: "executable"
        onNewData: (src) => disconnectSource(src)
    }
    function applyIconTheme(themeId) {
        var safe = /^[A-Za-z0-9_.+-]*$/.test(themeId) ? themeId : ""
        setCfg("iconTheme", safe)
        var dir = "\"${XDG_CONFIG_HOME:-$HOME/.config}/xmb-bigscreen\""
        if (safe.length === 0)
            iconThemeWriter.connectSource("sh -c 'rm -f " + dir + "/icontheme'")
        else
            iconThemeWriter.connectSource("sh -c 'mkdir -p " + dir + " && printf \"%s\\n\" \"" + safe + "\" > " + dir + "/icontheme'")
    }

    // ---- stick-swap preference (flag file read by the session script) ----
    property bool stickSwap: false
    P5Support.DataSource {
        id: stickSwapQuery
        engine: "executable"
        function refresh() {
            connectSource("sh -c 'test -e \"${XDG_CONFIG_HOME:-$HOME/.config}/xmb-bigscreen/stickswap\" && echo 1 || echo 0'")
        }
        onNewData: (src, data) => {
            win.stickSwap = ((data["stdout"] || "") + "").trim() === "1"
            disconnectSource(src)
        }
    }
    function setStickSwap(enabled) {
        stickSwap = enabled
        iconThemeWriter.connectSource("xmb-bigscreen-stick-swap " + (enabled ? "--on" : "--off"))
    }

    // ---- sections ----
    readonly property var sections: [
        { id: "appearance", label: win.translate("Appearance"),        icon: "preferences-desktop-theme" },
        { id: "background", label: win.translate("Background"),         icon: "preferences-desktop-wallpaper" },
        { id: "clock",      label: win.translate("Clock"),             icon: "clock" },
        { id: "sounds",     label: win.translate("Sounds"),            icon: "preferences-desktop-sound" },
        { id: "categories", label: win.translate("Visible categories"), icon: "view-list-symbolic" },
        { id: "favorites",  label: win.translate("Favorites"),         icon: "bookmarks" },
        { id: "language",   label: win.translate("Language"),          icon: "preferences-desktop-locale" },
        { id: "icons",      label: win.translate("Icons"),             icon: "preferences-desktop-icons" },
        { id: "controller", label: win.translate("Controller"),        icon: "input-gamepad" }
    ]

    // A label that scrolls horizontally when focused and too long to fit,
    // otherwise elides — so long section labels never overlap the controls.
    component MarqueeLabel: Item {
        id: ml
        property string text: ""
        property bool active: false
        implicitHeight: mlText.implicitHeight
        implicitWidth: mlText.implicitWidth
        clip: true
        readonly property real overflow: Math.max(0, mlText.implicitWidth - width)
        readonly property bool scrolling: active && overflow > 0
        onActiveChanged: if (!active) mlText.x = 0
        Text {
            id: mlText
            text: ml.text
            color: Kirigami.Theme.textColor
            font.pixelSize: Bigscreen.Units.defaultFontPixelSize
            elide: ml.scrolling ? Text.ElideNone : Text.ElideRight
            width: ml.scrolling ? implicitWidth : ml.width
            SequentialAnimation on x {
                running: ml.scrolling
                loops: Animation.Infinite
                PauseAnimation { duration: 900 }
                NumberAnimation { from: 0; to: -ml.overflow; duration: Math.max(600, ml.overflow * 16); easing.type: Easing.InOutSine }
                PauseAnimation { duration: 900 }
                NumberAnimation { from: -ml.overflow; to: 0; duration: Math.max(600, ml.overflow * 16); easing.type: Easing.InOutSine }
            }
        }
    }

    // A native-styled slider row (label + slider + value), engaged with Enter,
    // adjusted with left/right — matching the Bigscreen ScaleDialog interaction.
    component SliderRow: FocusScope {
        id: sr
        property string label: ""
        property real from: 0
        property real to: 100
        property real step: 1
        property real value: 0
        property string suffix: ""
        property bool percent: false
        signal moved(real v)
        readonly property bool engaged: win.engagedRow === sr
        readonly property bool hovered: srHover.hovered

        Layout.fillWidth: true
        implicitHeight: srRow.implicitHeight + Kirigami.Units.gridUnit * 2
        activeFocusOnTab: true

        Bigscreen.DelegateBackground {
            anchors.fill: parent
            control: sr
            borderHighlighted: sr.engaged || sr.activeFocus
            alternateBackgroundColor: true
        }
        HoverHandler { id: srHover }

        RowLayout {
            id: srRow
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.gridUnit
            anchors.rightMargin: Kirigami.Units.gridUnit
            spacing: Kirigami.Units.largeSpacing
            MarqueeLabel {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: sr.label
                active: sr.activeFocus || sr.engaged
            }
            QQC2.Slider {
                id: slider
                Layout.preferredWidth: Kirigami.Units.gridUnit * 11
                from: sr.from; to: sr.to; stepSize: sr.step
                value: sr.value
                onMoved: { sr.value = value; sr.moved(value) }
            }
            QQC2.Label {
                text: sr.percent ? Math.round(sr.value * 100) + "%" : (Math.round(sr.value) + sr.suffix)
                font.pixelSize: Bigscreen.Units.defaultFontPixelSize
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                opacity: sr.engaged ? 1.0 : 0.8
            }
        }

        Keys.onReturnPressed: win.engagedRow = sr.engaged ? null : sr
        Keys.onEnterPressed: win.engagedRow = sr.engaged ? null : sr
        Keys.onLeftPressed: (e) => {
            if (sr.engaged) { slider.decrease(); sr.value = slider.value; sr.moved(slider.value) }
            else win.focusSidebar()
        }
        Keys.onRightPressed: (e) => {
            if (sr.engaged) { slider.increase(); sr.value = slider.value; sr.moved(slider.value) }
        }
        TapHandler { onTapped: win.engagedRow = sr.engaged ? null : sr }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (ev) => {
                if (ev.angleDelta.y > 0) slider.increase(); else slider.decrease()
                sr.value = slider.value; sr.moved(slider.value)
            }
        }
    }

    // A native-styled select row: Enter engages, left/right cycle the options,
    // applied live. No Overlay/Dialog dependency (works in a layer-shell window).
    component ComboRow: FocusScope {
        id: cr
        property string label: ""
        property var options: []
        property int currentIndex: 0
        signal activated(int index)
        readonly property bool engaged: win.engagedRow === cr
        readonly property bool hovered: crHover.hovered

        Layout.fillWidth: true
        implicitHeight: crRow.implicitHeight + Kirigami.Units.gridUnit * 2
        activeFocusOnTab: true

        Bigscreen.DelegateBackground {
            anchors.fill: parent
            control: cr
            borderHighlighted: cr.engaged || cr.activeFocus
            alternateBackgroundColor: true
        }
        HoverHandler { id: crHover }

        RowLayout {
            id: crRow
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.gridUnit
            anchors.rightMargin: Kirigami.Units.gridUnit
            spacing: Kirigami.Units.largeSpacing
            MarqueeLabel {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: cr.label
                active: cr.activeFocus || cr.engaged
            }
            QQC2.Label {
                readonly property string opt: (cr.currentIndex >= 0 && cr.currentIndex < cr.options.length)
                    ? cr.options[cr.currentIndex] : ""
                text: cr.engaged ? "◂ " + opt + " ▸" : opt
                font.pixelSize: Bigscreen.Units.defaultFontPixelSize
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                Layout.maximumWidth: Kirigami.Units.gridUnit * 13
                opacity: cr.engaged ? 1.0 : 0.85
            }
        }

        function step(d) {
            var n = options.length
            if (n === 0) return
            currentIndex = ((currentIndex + d) % n + n) % n
            activated(currentIndex)
        }
        Keys.onReturnPressed: win.engagedRow = cr.engaged ? null : cr
        Keys.onEnterPressed: win.engagedRow = cr.engaged ? null : cr
        Keys.onLeftPressed: { if (cr.engaged) step(-1); else win.focusSidebar() }
        Keys.onRightPressed: { if (cr.engaged) step(1) }
        TapHandler { onTapped: { if (cr.engaged) cr.step(1); else win.engagedRow = cr } }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (ev) => cr.step(ev.angleDelta.y > 0 ? -1 : 1)
        }
    }

    Item {
        id: content
        anchors.fill: parent
        focus: true
        opacity: win.dim / 0.62

        // Click on the dim area closes.
        TapHandler {
            onTapped: (eventPoint) => {
                if (eventPoint.position.x > sidebarRect.width + pageArea.width)
                    win.hide()
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ---- Sidebar ----
            Rectangle {
                id: sidebarRect
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g,
                               Kirigami.Theme.backgroundColor.b, 0.85)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing
                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Heading {
                        text: win.translate("XMB settings")
                        level: 1
                        font.weight: Font.Light
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                        Layout.topMargin: Kirigami.Units.largeSpacing
                    }

                    ListView {
                        id: sidebar
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: win.sections
                        spacing: Kirigami.Units.smallSpacing
                        keyNavigationEnabled: true
                        activeFocusOnTab: true

                        delegate: Bigscreen.ButtonDelegate {
                            required property var modelData
                            required property int index
                            width: ListView.view.width
                            text: modelData.label
                            icon.name: modelData.icon
                            onClicked: { sidebar.currentIndex = index; pageArea.enterPage() }
                            Keys.onRightPressed: { sidebar.currentIndex = index; pageArea.enterPage() }
                            onActiveFocusChanged: if (activeFocus) sidebar.currentIndex = index
                        }

                        Keys.onEscapePressed: win.hide()
                    }
                }
            }

            // ---- Page area ----
            Item {
                id: pageArea
                Layout.fillHeight: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 30

                function enterPage() {
                    var item = pageStack.children[sidebar.currentIndex]
                    if (item && item.focusFirst)
                        item.focusFirst()
                }

                Kirigami.Heading {
                    id: pageTitle
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: Kirigami.Units.largeSpacing
                    text: win.sections[sidebar.currentIndex].label
                    font.pixelSize: 32
                    font.weight: Font.Light
                }

                StackLayout {
                    id: pageStack
                    anchors.top: pageTitle.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Kirigami.Units.largeSpacing
                    currentIndex: sidebar.currentIndex

                    // 0 — Appearance
                    SettingsFlick {
                        id: appearancePage
                        ColumnLayout {
                            width: appearancePage.width
                            spacing: Kirigami.Units.smallSpacing
                            SliderRow {
                                id: ap0; focus: true
                                label: win.translate("Background opacity"); percent: true
                                from: 0.2; to: 1.0; step: 0.05
                                value: win.getCfg("backgroundOpacity")
                                onMoved: (v) => win.setCfg("backgroundOpacity", v)
                                KeyNavigation.down: ap1                            }
                            SliderRow {
                                id: ap1
                                label: win.translate("Category icon size"); suffix: " px"
                                from: 48; to: 256; step: 8
                                value: win.getCfg("categoryIconSize")
                                onMoved: (v) => win.setCfg("categoryIconSize", Math.round(v))
                                KeyNavigation.up: ap0; KeyNavigation.down: ap2                            }
                            SliderRow {
                                id: ap2
                                label: win.translate("App icon size"); suffix: " px"
                                from: 24; to: 160; step: 4
                                value: win.getCfg("appIconSize")
                                onMoved: (v) => win.setCfg("appIconSize", Math.round(v))
                                KeyNavigation.up: ap1; KeyNavigation.down: ap3                            }
                            SliderRow {
                                id: ap3
                                label: win.translate("Cross position"); percent: true
                                from: 0.1; to: 0.5; step: 0.01
                                value: win.getCfg("intersectionXFraction")
                                onMoved: (v) => win.setCfg("intersectionXFraction", v)
                                KeyNavigation.up: ap2; KeyNavigation.down: apReset                            }
                            Bigscreen.Button {
                                id: apReset
                                text: win.translate("Reset section")
                                icon.name: "edit-undo"
                                KeyNavigation.up: ap3
                                Keys.onLeftPressed: sidebar.forceActiveFocus()
                                onClicked: {
                                    win.resetKeys(["backgroundOpacity","categoryIconSize","appIconSize","intersectionXFraction"])
                                    ap0.value = win.getCfg("backgroundOpacity"); ap1.value = win.getCfg("categoryIconSize")
                                    ap2.value = win.getCfg("appIconSize"); ap3.value = win.getCfg("intersectionXFraction")
                                }
                            }
                        }
                        function focusFirst() { ap0.forceActiveFocus() }
                    }

                    // 1 — Background (wave RGB, live preview)
                    SettingsFlick {
                        id: backgroundPage
                        ColumnLayout {
                            width: backgroundPage.width
                            spacing: Kirigami.Units.smallSpacing
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.bottomMargin: Kirigami.Units.smallSpacing
                                wrapMode: Text.WordWrap
                                opacity: 0.8
                                text: win.translate("Adjust the wave colour behind the cross. Changes preview live.")
                            }
                            SliderRow {
                                id: bgR; focus: true
                                label: win.translate("Red"); from: 0; to: 255; step: 1
                                value: win.getCfg("waveColorR")
                                onMoved: (v) => win.setCfg("waveColorR", Math.round(v))
                                KeyNavigation.down: bgG                            }
                            SliderRow {
                                id: bgG
                                label: win.translate("Green"); from: 0; to: 255; step: 1
                                value: win.getCfg("waveColorG")
                                onMoved: (v) => win.setCfg("waveColorG", Math.round(v))
                                KeyNavigation.up: bgR; KeyNavigation.down: bgB                            }
                            SliderRow {
                                id: bgB
                                label: win.translate("Blue"); from: 0; to: 255; step: 1
                                value: win.getCfg("waveColorB")
                                onMoved: (v) => win.setCfg("waveColorB", Math.round(v))
                                KeyNavigation.up: bgG; KeyNavigation.down: bgReset                            }
                            Bigscreen.Button {
                                id: bgReset
                                text: win.translate("Reset section")
                                icon.name: "edit-undo"
                                KeyNavigation.up: bgB
                                Keys.onLeftPressed: sidebar.forceActiveFocus()
                                onClicked: {
                                    win.resetKeys(["waveColorR","waveColorG","waveColorB"])
                                    bgR.value = win.getCfg("waveColorR"); bgG.value = win.getCfg("waveColorG"); bgB.value = win.getCfg("waveColorB")
                                }
                            }
                        }
                        function focusFirst() { bgR.forceActiveFocus() }
                    }

                    // 2 — Clock
                    SettingsFlick {
                        id: clockPage
                        ColumnLayout {
                            width: clockPage.width
                            spacing: Kirigami.Units.smallSpacing
                            ComboRow {
                                id: clk0; focus: true
                                label: win.translate("Time format")
                                options: [win.translate("System"), win.translate("12-hour"), win.translate("24-hour")]
                                currentIndex: win.getCfg("clockTimeFormat")
                                onActivated: (i) => win.setCfg("clockTimeFormat", i)
                                KeyNavigation.down: clk1
                            }
                            ComboRow {
                                id: clk1
                                label: win.translate("Date format")
                                options: [win.translate("System"), win.translate("Day/month"), win.translate("Month/day")]
                                currentIndex: win.getCfg("clockDateFormat")
                                onActivated: (i) => win.setCfg("clockDateFormat", i)
                                KeyNavigation.up: clk0; KeyNavigation.down: clk2
                            }
                            Bigscreen.SwitchDelegate {
                                id: clk2
                                Layout.fillWidth: true
                                text: win.translate("Show date")
                                checked: win.getCfg("clockShowDate")
                                onToggled: win.setCfg("clockShowDate", checked)
                                KeyNavigation.up: clk1
                                Keys.onLeftPressed: sidebar.forceActiveFocus()
                            }
                        }
                        function focusFirst() { clk0.forceActiveFocus() }
                    }

                    // 3 — Sounds
                    SettingsFlick {
                        id: soundsPage
                        ColumnLayout {
                            width: soundsPage.width
                            spacing: Kirigami.Units.smallSpacing
                            ComboRow {
                                id: sn0; focus: true
                                label: win.translate("Navigation tick")
                                options: [win.translate("XMB (default)"), win.translate("Custom file"), win.translate("Off")]
                                currentIndex: win.getCfg("navSoundMode")
                                onActivated: (i) => win.setCfg("navSoundMode", i)
                                KeyNavigation.down: sn1
                            }
                            SliderRow {
                                id: sn1
                                label: win.translate("Tick volume"); percent: true
                                from: 0.0; to: 1.0; step: 0.05
                                value: win.getCfg("navSoundVolume")
                                onMoved: (v) => win.setCfg("navSoundVolume", v)
                                KeyNavigation.up: sn0; KeyNavigation.down: sn2                            }
                            ComboRow {
                                id: sn2
                                label: win.translate("Background ambience")
                                options: [win.translate("XMB (default)"), win.translate("Custom file"), win.translate("Off")]
                                currentIndex: win.getCfg("ambientSoundMode")
                                onActivated: (i) => win.setCfg("ambientSoundMode", i)
                                KeyNavigation.up: sn1; KeyNavigation.down: sn3
                            }
                            SliderRow {
                                id: sn3
                                label: win.translate("Ambience volume"); percent: true
                                from: 0.0; to: 1.0; step: 0.05
                                value: win.getCfg("ambientSoundVolume")
                                onMoved: (v) => win.setCfg("ambientSoundVolume", v)
                                KeyNavigation.up: sn2                            }
                        }
                        function focusFirst() { sn0.forceActiveFocus() }
                    }

                    // 4 — Visible categories
                    SettingsFlick {
                        id: categoriesPage
                        Kicker.RootModel {
                            id: catModel
                            autoPopulate: true
                            showAllApps: false; showAllAppsCategorized: true
                            showRecentApps: false; showRecentDocs: false; showRecentFolders: false
                            showPowerSession: false; showFavoritesPlaceholder: false; showSeparators: false
                        }
                        ColumnLayout {
                            width: categoriesPage.width
                            spacing: Kirigami.Units.smallSpacing
                            Repeater {
                                id: catRepeater
                                model: catModel
                                Bigscreen.SwitchDelegate {
                                    required property var model
                                    required property int index
                                    readonly property string catKey: model.decoration ? String(model.decoration) : model.display
                                    Layout.fillWidth: true
                                    text: model.display
                                    icon.name: model.decoration ? String(model.decoration) : ""
                                    checked: (win.getCfg("hiddenCategories") || []).indexOf(catKey) === -1
                                    onToggled: {
                                        var arr = (win.getCfg("hiddenCategories") || []).slice()
                                        var i = arr.indexOf(catKey)
                                        if (checked && i !== -1) arr.splice(i, 1)
                                        else if (!checked && i === -1) arr.push(catKey)
                                        win.setCfg("hiddenCategories", arr)
                                    }
                                    KeyNavigation.up: index > 0 ? catRepeater.itemAt(index - 1) : null
                                    KeyNavigation.down: index < catRepeater.count - 1 ? catRepeater.itemAt(index + 1) : null
                                    Keys.onLeftPressed: sidebar.forceActiveFocus()
                                }
                            }
                        }
                        function focusFirst() { if (catRepeater.count > 0) catRepeater.itemAt(0).forceActiveFocus() }
                    }

                    // 5 — Favorites
                    Item {
                        id: favoritesPage
                        Kicker.RootModel {
                            id: favAllApps
                            autoPopulate: true
                            showAllApps: true; showAllAppsCategorized: false
                            showRecentApps: false; showRecentDocs: false; showRecentFolders: false
                            showPowerSession: false; showFavoritesPlaceholder: false; showSeparators: false
                            appNameFormat: 0
                            onCountChanged: favoritesPage.appsFlat = favAllApps.modelForRow(0)
                        }
                        property var appsFlat: null
                        KItemModels.KSortFilterProxyModel {
                            id: favFiltered
                            sourceModel: favoritesPage.appsFlat
                            filterRoleName: "display"; filterString: favSearch.text
                            filterCaseSensitivity: Qt.CaseInsensitive
                            sortRoleName: "display"; sortOrder: Qt.AscendingOrder
                        }
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Kirigami.Units.smallSpacing
                            Bigscreen.TextField {
                                id: favSearch
                                Layout.fillWidth: true
                                placeholderText: win.translate("Search applications")
                                // Read-only with manual insertion, like the search overlay:
                                // arrows drive the on-screen keyboard, whose Enter key moves
                                // to the list; Square (KEY_GAMES) or Backspace deletes.
                                readOnly: true
                                Keys.onReturnPressed: settingsOsk.activate()
                                Keys.onEnterPressed: settingsOsk.activate()
                                Keys.onUpPressed: settingsOsk.move(0, -1)
                                Keys.onDownPressed: settingsOsk.move(0, 1)
                                Keys.onLeftPressed: settingsOsk.move(-1, 0)
                                Keys.onRightPressed: settingsOsk.move(1, 0)
                                Keys.onPressed: (event) => {
                                    if (event.key === Qt.Key_Backspace
                                            || event.nativeScanCode === 417 || event.nativeScanCode === 425) {
                                        text = text.slice(0, -1)
                                        event.accepted = true
                                    } else if (event.text.length === 1
                                               && (event.text.trim().length === 1 || event.key === Qt.Key_Space)
                                               && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                                        text += event.text
                                        event.accepted = true
                                    }
                                }
                            }
                            ListView {
                                id: favList
                                Layout.fillWidth: true; Layout.fillHeight: true
                                clip: true; model: favFiltered
                                spacing: Kirigami.Units.smallSpacing
                                keyNavigationEnabled: true
                                KeyNavigation.up: favSearch
                                delegate: Bigscreen.SwitchDelegate {
                                    required property var model
                                    width: ListView.view.width
                                    text: model.display
                                    icon.name: model.decoration ? String(model.decoration) : ""
                                    checked: (win.getCfg("favorites") || []).indexOf(model.favoriteId) !== -1
                                    onToggled: {
                                        var arr = (win.getCfg("favorites") || []).slice()
                                        var i = arr.indexOf(model.favoriteId)
                                        if (checked && i === -1) arr.push(model.favoriteId)
                                        else if (!checked && i !== -1) arr.splice(i, 1)
                                        win.setCfg("favorites", arr)
                                    }
                                    Keys.onLeftPressed: sidebar.forceActiveFocus()
                                }
                            }
                        }
                        function focusFirst() { favSearch.forceActiveFocus() }
                    }

                    // 6 — Language
                    SettingsFlick {
                        id: languagePage
                        readonly property var codes: [""].concat(Catalogs.languages)
                        function focusFirst() { lng0.forceActiveFocus() }
                        ColumnLayout {
                            width: languagePage.width
                            spacing: Kirigami.Units.smallSpacing
                            ComboRow {
                                id: lng0; focus: true
                                label: win.translate("Language")
                                options: languagePage.codes.map(c => c === "" ? win.translate("System")
                                    : c === "en" ? "English"
                                    : (Qt.locale(c).nativeLanguageName.charAt(0).toUpperCase() + Qt.locale(c).nativeLanguageName.slice(1)) || c)
                                currentIndex: Math.max(0, languagePage.codes.indexOf(win.getCfg("language")))
                                onActivated: (i) => win.setCfg("language", languagePage.codes[i])
                            }
                        }
                    }

                    // 7 — Icons
                    SettingsFlick {
                        id: iconsPage
                        ColumnLayout {
                            width: iconsPage.width
                            spacing: Kirigami.Units.smallSpacing
                            ComboRow {
                                id: ic0; focus: true
                                label: win.translate("Icon theme")
                                options: win.iconThemes.map(t => t.name)
                                currentIndex: {
                                    var cur = win.getCfg("iconTheme")
                                    for (var i = 0; i < win.iconThemes.length; i++)
                                        if (win.iconThemes[i].id === cur) return i
                                    return 0
                                }
                                onActivated: (i) => win.applyIconTheme(win.iconThemes[i].id)
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.topMargin: Kirigami.Units.smallSpacing
                                wrapMode: Text.WordWrap
                                opacity: 0.8
                                text: win.translate("The icon theme applies to the XMB session only, from the next login. Your desktop session is not affected.")
                            }
                        }
                        function focusFirst() { ic0.forceActiveFocus() }
                    }

                    // 8 — Controller
                    SettingsFlick {
                        id: controllerPage
                        ColumnLayout {
                            width: controllerPage.width
                            spacing: Kirigami.Units.smallSpacing
                            Bigscreen.SwitchDelegate {
                                id: ct0; focus: true
                                Layout.fillWidth: true
                                text: win.translate("Pointer on the left stick")
                                checked: win.stickSwap
                                onToggled: win.setStickSwap(checked)
                                Keys.onLeftPressed: sidebar.forceActiveFocus()
                            }
                            QQC2.Label {
                                Layout.fillWidth: true
                                Layout.topMargin: Kirigami.Units.smallSpacing
                                wrapMode: Text.WordWrap
                                opacity: 0.8
                                text: win.translate("Moves the mouse pointer with the left stick and scrolls lists with the right, with L3 as click. Games always see the physical layout. Applies from the next login.")
                            }
                        }
                        function focusFirst() { ct0.forceActiveFocus() }
                    }
                }
            }

            // Right gutter: the live wave shows through here.
            Item { Layout.fillWidth: true; Layout.fillHeight: true }
        }
    }

    // Gamepad on-screen keyboard, shown while the favorites filter has focus.
    XmbOsk {
        id: settingsOsk
        visible: favSearch.activeFocus
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Kirigami.Units.largeSpacing
        width: Math.min(win.width, Math.round(win.height * 1.1))
        onKeyPressed: (text) => favSearch.text += text
        onBackspacePressed: favSearch.text = favSearch.text.slice(0, -1)
        onAccepted: favList.forceActiveFocus()
    }

    // A scrollable page body that keeps the focused row in view.
    component SettingsFlick: Flickable {
        contentWidth: width
        contentHeight: contentItem.childrenRect.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
    }
}
