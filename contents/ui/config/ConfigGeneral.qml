// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// "General" settings for the XMB shell containment. Curated for a TV/10-foot
// setup: the deep wave-shader and mouse-physics knobs from the desktop plasmoid
// stay in main.xml with their defaults but are not exposed here.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.private.kicker as Kicker
import org.kde.plasma.plasma5support as P5Support
import "../i18n-catalogs.js" as Catalogs

KCM.SimpleKCM {
    id: page

    property string cfg_iconTheme
    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_categoryIconSize: categorySizeSpin.value
    property alias cfg_appIconSize: appSizeSpin.value
    property alias cfg_intersectionXFraction: intersectionSlider.value
    property alias cfg_topBarPosition: barRevealCombo.currentIndex
    property string cfg_language
    property alias cfg_clockTimeFormat: clockFormatCombo.currentIndex
    property alias cfg_clockDateFormat: clockDateFormatCombo.currentIndex
    property alias cfg_clockShowDate: clockDateCheck.checked

    property alias cfg_navSoundMode: navSoundCombo.currentIndex
    property alias cfg_navSoundFile: navSoundFileField.text
    property alias cfg_navSoundVolume: navSoundVolumeSlider.value
    property alias cfg_ambientSoundMode: ambientSoundCombo.currentIndex
    property alias cfg_ambientSoundFile: ambientSoundFileField.text
    property alias cfg_ambientSoundVolume: ambientSoundVolumeSlider.value

    // Must be an alias, not `property var`, or the config system stops generating
    // cfg_<key>Default for every key. Hence the helper store below.
    property alias cfg_hiddenCategories: hiddenCategoriesStore.value
    QtObject {
        id: hiddenCategoriesStore
        property var value: []
    }
    property var hiddenSet: cfg_hiddenCategories

    function toggleCategory(name, hide) {
        var arr = hiddenSet.slice()
        var idx = arr.indexOf(name)
        if (hide && idx === -1) arr.push(name)
        else if (!hide && idx !== -1) arr.splice(idx, 1)
        cfg_hiddenCategories = arr
        hiddenSet = arr
    }

    // Each cfg_<key>Default must be declared explicitly (the loader won't auto-create
    // them), otherwise reset reads undefined and does nothing. Keep in sync with main.xml.
    property string cfg_iconThemeDefault: ""
    property real cfg_backgroundOpacityDefault: 1.0
    property int  cfg_categoryIconSizeDefault: 112
    property int  cfg_appIconSizeDefault: 56
    property real cfg_intersectionXFractionDefault: 0.30
    property int  cfg_topBarPositionDefault: 0
    property string cfg_languageDefault: ""
    property int  cfg_clockTimeFormatDefault: 0
    property int  cfg_clockDateFormatDefault: 0
    property bool cfg_clockShowDateDefault: true

    property int    cfg_navSoundModeDefault: 0
    property string cfg_navSoundFileDefault: ""
    property real   cfg_navSoundVolumeDefault: 0.5
    property int    cfg_ambientSoundModeDefault: 0
    property string cfg_ambientSoundFileDefault: ""
    property real   cfg_ambientSoundVolumeDefault: 0.5

    function resetAppearance() {
        cfg_iconTheme = cfg_iconThemeDefault
        cfg_backgroundOpacity = cfg_backgroundOpacityDefault
        cfg_categoryIconSize = cfg_categoryIconSizeDefault
        cfg_appIconSize = cfg_appIconSizeDefault
        cfg_intersectionXFraction = cfg_intersectionXFractionDefault
    }
    function resetClock() {
        cfg_clockTimeFormat = cfg_clockTimeFormatDefault
        cfg_clockDateFormat = cfg_clockDateFormatDefault
        cfg_clockShowDate = cfg_clockShowDateDefault
    }
    function resetSounds() {
        cfg_navSoundMode = cfg_navSoundModeDefault
        cfg_navSoundFile = cfg_navSoundFileDefault
        cfg_navSoundVolume = cfg_navSoundVolumeDefault
        cfg_ambientSoundMode = cfg_ambientSoundModeDefault
        cfg_ambientSoundFile = cfg_ambientSoundFileDefault
        cfg_ambientSoundVolume = cfg_ambientSoundVolumeDefault
    }

    Kirigami.FormLayout {
        id: form

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Appearance")
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: iconThemeCombo
            Kirigami.FormData.label: i18n("Icon theme:")
            Layout.preferredWidth: page.controlWidth
            property var themes: [""]
            model: themes.map(t => t === "" ? i18n("System") : t)
            currentIndex: Math.max(0, themes.indexOf(page.cfg_iconTheme))
            onActivated: page.cfg_iconTheme = themes[currentIndex]

            // Icon themes = dirs with an index.theme plus at least one icon context dir
            // (this skips cursor-only themes).
            P5Support.DataSource {
                engine: "executable"
                connectedSources: ["for d in \"$HOME\"/.local/share/icons/*/ /usr/share/icons/*/; do "
                                   + "[ -f \"$d/index.theme\" ] || continue; "
                                   + "{ [ -d \"$d/apps\" ] || [ -d \"$d/places\" ] || [ -d \"$d/actions\" ] || [ -d \"$d/categories\" ]; } "
                                   + "&& basename \"$d\"; done | sort -u"]
                onNewData: (src, data) => {
                    disconnectSource(src)
                    var names = ((data["stdout"] || "") + "").split("\n").filter(s => s.trim() !== "")
                    iconThemeCombo.themes = [""].concat(names)
                    iconThemeCombo.currentIndex = Math.max(0, iconThemeCombo.themes.indexOf(page.cfg_iconTheme))
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Background opacity:")
            QQC2.Slider {
                id: opacitySlider
                from: 0.2; to: 1.0; stepSize: 0.05
                Layout.preferredWidth: page.controlWidth
            }
            QQC2.Label {
                text: Math.round(opacitySlider.value * 100) + "%"
                Layout.minimumWidth: valueColumnWidth
                horizontalAlignment: Text.AlignRight
            }
        }

        QQC2.SpinBox {
            id: categorySizeSpin
            Kirigami.FormData.label: i18n("Category icon size (px):")
            from: 48; to: 256; stepSize: 8
        }

        QQC2.SpinBox {
            id: appSizeSpin
            Kirigami.FormData.label: i18n("App icon size (px):")
            from: 24; to: 160; stepSize: 4
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Cross position (from left):")
            QQC2.Slider {
                id: intersectionSlider
                from: 0.1; to: 0.5; stepSize: 0.01
                Layout.preferredWidth: page.controlWidth
            }
            QQC2.Label {
                text: Math.round(intersectionSlider.value * 100) + "%"
                Layout.minimumWidth: valueColumnWidth
                horizontalAlignment: Text.AlignRight
            }
        }

        QQC2.Button {
            text: i18n("Reset section to defaults")
            icon.name: "edit-undo"
            onClicked: page.resetAppearance()
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Language")
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: languageCombo
            Kirigami.FormData.label: i18n("Language:")
            Layout.preferredWidth: page.controlWidth
            readonly property var codes: [""].concat(Catalogs.languages)
            model: codes.map(c => c === "" ? i18n("System")
                : c === "en" ? "English"
                : (Qt.locale(c).nativeLanguageName.charAt(0).toUpperCase()
                   + Qt.locale(c).nativeLanguageName.slice(1)) || c)
            currentIndex: Math.max(0, codes.indexOf(page.cfg_language))
            onActivated: page.cfg_language = codes[currentIndex]
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Clock")
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: clockFormatCombo
            Kirigami.FormData.label: i18n("Time format:")
            Layout.preferredWidth: page.controlWidth
            model: [i18n("System"), i18n("12-hour"), i18n("24-hour")]
        }

        QQC2.ComboBox {
            id: clockDateFormatCombo
            Kirigami.FormData.label: i18n("Date format:")
            Layout.preferredWidth: page.controlWidth
            model: [i18n("System"), i18n("Day/month"), i18n("Month/day")]
        }

        QQC2.CheckBox {
            id: clockDateCheck
            Kirigami.FormData.label: i18n("Show date:")
        }

        QQC2.Button {
            text: i18n("Reset section to defaults")
            icon.name: "edit-undo"
            onClicked: page.resetClock()
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Behaviour")
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: barRevealCombo
            Kirigami.FormData.label: i18n("Bar reveal:")
            Layout.preferredWidth: page.controlWidth
            model: [i18n("Top edge"), i18n("Bottom edge")]
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Sounds")
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: navSoundCombo
            Kirigami.FormData.label: i18n("Navigation tick:")
            // index maps to navSoundMode (0/1/2)
            model: [ i18n("XMB (default)"), i18n("Custom file…"), i18n("Off") ]
        }

        QQC2.TextField {
            id: navSoundFileField
            Kirigami.FormData.label: i18n("Custom sound file:")
            Layout.preferredWidth: page.controlWidth
            enabled: navSoundCombo.currentIndex === 1
            placeholderText: i18n("/path/to/sound.wav or .mp3")
        }
        QQC2.Label {
            Layout.preferredWidth: page.controlWidth
            visible: navSoundCombo.currentIndex === 1
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: i18n("The original PS3 sound is not bundled (Sony copyright). Point this at your own local copy. WAV gives the lowest latency.")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Volume:")
            enabled: navSoundCombo.currentIndex !== 2
            QQC2.Slider { id: navSoundVolumeSlider; from: 0.0; to: 1.0; stepSize: 0.01; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: Math.round(navSoundVolumeSlider.value * 100) + "%"; Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }

        Item { implicitHeight: Kirigami.Units.largeSpacing }

        QQC2.ComboBox {
            id: ambientSoundCombo
            Kirigami.FormData.label: i18n("Background ambience:")
            // index maps to ambientSoundMode (0/1/2)
            model: [ i18n("XMB (default)"), i18n("Custom file…"), i18n("Off") ]
        }

        QQC2.TextField {
            id: ambientSoundFileField
            Kirigami.FormData.label: i18n("Custom ambience file:")
            Layout.preferredWidth: page.controlWidth
            enabled: ambientSoundCombo.currentIndex === 1
            placeholderText: i18n("/path/to/loop.wav or .mp3")
        }
        QQC2.Label {
            Layout.preferredWidth: page.controlWidth
            visible: ambientSoundCombo.currentIndex === 1
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: i18n("The file loops while the dashboard is open. WAV loops gaplessly; mp3/ogg may have a small seam at the loop point.")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Volume:")
            enabled: ambientSoundCombo.currentIndex !== 2
            QQC2.Slider { id: ambientSoundVolumeSlider; from: 0.0; to: 1.0; stepSize: 0.01; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: Math.round(ambientSoundVolumeSlider.value * 100) + "%"; Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }

        QQC2.Button {
            text: i18n("Reset section to defaults")
            icon.name: "edit-undo"
            onClicked: page.resetSounds()
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Visible categories")
            Kirigami.FormData.isSection: true
        }

        Kicker.RootModel {
            id: categoriesModel
            autoPopulate: true
            showAllApps: false
            showAllAppsCategorized: true
            showRecentApps: false
            showRecentDocs: false
            showRecentFolders: false
            showPowerSession: false
            showFavoritesPlaceholder: false
            showSeparators: false
        }

        Repeater {
            model: categoriesModel
            // Don't expose the model's "display" role directly: AbstractButton already
            // has a FINAL "display" property and the page would fail to load. Use `model`.
            QQC2.CheckBox {
                required property var model
                required property int index
                // Persist the locale-independent icon key, show the translated label.
                readonly property string catKey: model.decoration ? String(model.decoration) : model.display
                text: model.display
                checked: page.hiddenSet.indexOf(catKey) === -1
                onToggled: page.toggleCategory(catKey, !checked)
            }
        }

        QQC2.Button {
            text: i18n("Show all categories")
            icon.name: "edit-undo"
            onClicked: { page.cfg_hiddenCategories = []; page.hiddenSet = [] }
        }
    }

    readonly property int valueColumnWidth: Kirigami.Units.gridUnit * 2.5

    // Bounded (not fillWidth) so the form stays centred instead of stretching edge to edge.
    readonly property int controlWidth: Kirigami.Units.gridUnit * 14
}
