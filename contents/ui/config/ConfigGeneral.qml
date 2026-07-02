// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// "General" settings page. Each control writes to cfg_<key>, mapped to main.xml.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.private.kicker as Kicker
import "../i18n-catalogs.js" as Catalogs

KCM.SimpleKCM {
    id: page

    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_categoryIconSize: categorySizeSpin.value
    property alias cfg_appIconSize: appSizeSpin.value
    property alias cfg_intersectionXFraction: intersectionSlider.value
    property alias cfg_panelIcon: iconField.text
    property alias cfg_hotZoneFractionLeft: hotZoneLeftSlider.value
    property alias cfg_hotZoneFractionRight: hotZoneRightSlider.value
    property alias cfg_minScrollSpeed: minSpeedSpin.value
    property alias cfg_maxScrollSpeed: maxSpeedSpin.value
    property alias cfg_snapDuration: snapDurationSpin.value
    property alias cfg_magneticStrength: magneticSlider.value
    property alias cfg_hotZoneBandHeight: bandHeightSpin.value
    property alias cfg_manageScreenEdges: manageScreenEdgesCheck.checked
    property alias cfg_topBarPosition: barRevealCombo.currentIndex
    property string cfg_language
    property alias cfg_clockTimeFormat: clockFormatCombo.currentIndex
    property alias cfg_clockDateFormat: clockDateFormatCombo.currentIndex
    property alias cfg_clockShowDate: clockDateCheck.checked

    // Wave background
    property alias cfg_waveFlowSpeed: waveFlowSpeedSlider.value
    property alias cfg_waveBandAmplitude: waveBandAmpSlider.value
    property alias cfg_waveHeightScale: waveHeightScaleSlider.value
    property alias cfg_waveSoftClip: waveSoftClipSlider.value
    property alias cfg_waveTension: waveTensionSlider.value
    property alias cfg_waveFresnelPower: waveFresnelPowerSlider.value
    property alias cfg_waveFresnelScale: waveFresnelScaleSlider.value
    property alias cfg_waveOpacity: waveOpacitySlider.value
    property alias cfg_waveBrightness: waveBrightnessSlider.value
    property alias cfg_waveRowCount: waveRowCountSpin.value
    property alias cfg_waveColorMonth: monthCombo.currentIndex
    property alias cfg_waveColorR: waveColorRSlider.value
    property alias cfg_waveColorG: waveColorGSlider.value
    property alias cfg_waveColorB: waveColorBSlider.value
    property alias cfg_waveGradientTopMul: waveTopMulSlider.value
    property alias cfg_waveGradientBotMul: waveBotMulSlider.value
    property alias cfg_waveParticlesEnabled: particlesEnabledCheck.checked
    property alias cfg_waveParticleCount: waveParticleCountSpin.value
    property alias cfg_waveParticleOpacity: waveParticleOpacitySlider.value
    property alias cfg_waveParticleFlowSpeed: waveParticleFlowSpeedSlider.value

    // Navigation sound
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
    property real cfg_backgroundOpacityDefault: 1.0
    property int  cfg_categoryIconSizeDefault: 112
    property int  cfg_appIconSizeDefault: 56
    property real cfg_intersectionXFractionDefault: 0.30
    property string cfg_panelIconDefault: ""
    property int  cfg_clockTimeFormatDefault: 0
    property int  cfg_clockDateFormatDefault: 0
    property bool cfg_clockShowDateDefault: true
    property int  cfg_topBarPositionDefault: 0
    property string cfg_languageDefault: ""

    property real cfg_hotZoneFractionLeftDefault: 0.15
    property real cfg_hotZoneFractionRightDefault: 0.15
    property int  cfg_hotZoneBandHeightDefault: 200
    property int  cfg_minScrollSpeedDefault: 1500
    property int  cfg_maxScrollSpeedDefault: 2600
    property int  cfg_snapDurationDefault: 220
    property real cfg_magneticStrengthDefault: 0.7

    property real cfg_waveFlowSpeedDefault: 0.45
    property real cfg_waveBandAmplitudeDefault: 0.2
    property real cfg_waveHeightScaleDefault: 0.5
    property real cfg_waveSoftClipDefault: 0.22
    property real cfg_waveTensionDefault: 0.12
    property real cfg_waveFresnelPowerDefault: 4.0
    property real cfg_waveFresnelScaleDefault: 0.5
    property real cfg_waveOpacityDefault: 0.7
    property real cfg_waveBrightnessDefault: 0.98
    property int  cfg_waveRowCountDefault: 200

    property int  cfg_waveColorMonthDefault: 13
    property int  cfg_waveColorRDefault: 37
    property int  cfg_waveColorGDefault: 89
    property int  cfg_waveColorBDefault: 179
    property real cfg_waveGradientTopMulDefault: 0.09
    property real cfg_waveGradientBotMulDefault: 0.62

    property bool cfg_waveParticlesEnabledDefault: true
    property int  cfg_waveParticleCountDefault: 2000
    property real cfg_waveParticleOpacityDefault: 1.0
    property real cfg_waveParticleFlowSpeedDefault: 0.8

    property int    cfg_navSoundModeDefault: 0
    property string cfg_navSoundFileDefault: ""
    property real   cfg_navSoundVolumeDefault: 0.5
    property int    cfg_ambientSoundModeDefault: 0
    property string cfg_ambientSoundFileDefault: ""
    property real   cfg_ambientSoundVolumeDefault: 0.5

    function resetAppearance() {
        cfg_backgroundOpacity = cfg_backgroundOpacityDefault
        cfg_categoryIconSize = cfg_categoryIconSizeDefault
        cfg_appIconSize = cfg_appIconSizeDefault
        cfg_intersectionXFraction = cfg_intersectionXFractionDefault
        cfg_panelIcon = cfg_panelIconDefault
    }
    function resetClock() {
        cfg_clockTimeFormat = cfg_clockTimeFormatDefault
        cfg_clockDateFormat = cfg_clockDateFormatDefault
        cfg_clockShowDate = cfg_clockShowDateDefault
    }
    function resetCategoryBar() {
        cfg_hotZoneFractionLeft = cfg_hotZoneFractionLeftDefault
        cfg_hotZoneFractionRight = cfg_hotZoneFractionRightDefault
        cfg_hotZoneBandHeight = cfg_hotZoneBandHeightDefault
        cfg_minScrollSpeed = cfg_minScrollSpeedDefault
        cfg_maxScrollSpeed = cfg_maxScrollSpeedDefault
        cfg_snapDuration = cfg_snapDurationDefault
        cfg_magneticStrength = cfg_magneticStrengthDefault
    }
    function resetWave() {
        cfg_waveFlowSpeed = cfg_waveFlowSpeedDefault
        cfg_waveBandAmplitude = cfg_waveBandAmplitudeDefault
        cfg_waveHeightScale = cfg_waveHeightScaleDefault
        cfg_waveSoftClip = cfg_waveSoftClipDefault
        cfg_waveTension = cfg_waveTensionDefault
        cfg_waveFresnelPower = cfg_waveFresnelPowerDefault
        cfg_waveFresnelScale = cfg_waveFresnelScaleDefault
        cfg_waveOpacity = cfg_waveOpacityDefault
        cfg_waveBrightness = cfg_waveBrightnessDefault
        cfg_waveRowCount = cfg_waveRowCountDefault
    }
    function resetWaveColour() {
        cfg_waveColorMonth = cfg_waveColorMonthDefault
        cfg_waveColorR = cfg_waveColorRDefault
        cfg_waveColorG = cfg_waveColorGDefault
        cfg_waveColorB = cfg_waveColorBDefault
        cfg_waveGradientTopMul = cfg_waveGradientTopMulDefault
        cfg_waveGradientBotMul = cfg_waveGradientBotMulDefault
    }
    function resetParticles() {
        cfg_waveParticlesEnabled = cfg_waveParticlesEnabledDefault
        cfg_waveParticleCount = cfg_waveParticleCountDefault
        cfg_waveParticleOpacity = cfg_waveParticleOpacityDefault
        cfg_waveParticleFlowSpeed = cfg_waveParticleFlowSpeedDefault
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

        QQC2.TextField {
            id: iconField
            Kirigami.FormData.label: i18n("Panel icon name:")
            placeholderText: i18n("XMB logo (default)")
            Layout.preferredWidth: page.controlWidth
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

        QQC2.CheckBox {
            id: manageScreenEdgesCheck
            Kirigami.FormData.label: i18n("Screen edges:")
            text: i18n("Disable system edges while the dashboard is open")
        }

        QQC2.ComboBox {
            id: barRevealCombo
            Kirigami.FormData.label: i18n("Bar reveal:")
            Layout.preferredWidth: page.controlWidth
            model: [i18n("Top edge"), i18n("Bottom edge")]
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Category bar (mouse)")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Left hot-zone width:")
            QQC2.Slider {
                id: hotZoneLeftSlider
                from: 0.05; to: 0.45; stepSize: 0.01
                Layout.preferredWidth: page.controlWidth
            }
            QQC2.Label {
                text: Math.round(hotZoneLeftSlider.value * 100) + "%"
                Layout.minimumWidth: valueColumnWidth
                horizontalAlignment: Text.AlignRight
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Right hot-zone width:")
            QQC2.Slider {
                id: hotZoneRightSlider
                from: 0.05; to: 0.45; stepSize: 0.01
                Layout.preferredWidth: page.controlWidth
            }
            QQC2.Label {
                text: Math.round(hotZoneRightSlider.value * 100) + "%"
                Layout.minimumWidth: valueColumnWidth
                horizontalAlignment: Text.AlignRight
            }
        }

        QQC2.SpinBox {
            id: bandHeightSpin
            Kirigami.FormData.label: i18n("Hot-zone band height (px):")
            from: 80; to: 2000; stepSize: 20
        }

        QQC2.SpinBox {
            id: minSpeedSpin
            Kirigami.FormData.label: i18n("Min scroll speed (px/s):")
            from: 20
            // Kept at least 100 px/s below the max speed.
            to: Math.max(from, maxSpeedSpin.value - 100)
            stepSize: 10
            editable: true
        }

        QQC2.SpinBox {
            id: maxSpeedSpin
            Kirigami.FormData.label: i18n("Max scroll speed (px/s):")
            from: minSpeedSpin.value + 100
            to: 8000
            stepSize: 50
            editable: true
        }

        QQC2.SpinBox {
            id: snapDurationSpin
            Kirigami.FormData.label: i18n("Snap animation (ms):")
            from: 60; to: 600; stepSize: 10
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Magnetic glue strength:")
            QQC2.Slider {
                id: magneticSlider
                from: 0.0; to: 0.95; stepSize: 0.05
                Layout.preferredWidth: page.controlWidth
            }
            QQC2.Label {
                text: Math.round(magneticSlider.value * 100) + "%"
                Layout.minimumWidth: valueColumnWidth
                horizontalAlignment: Text.AlignRight
            }
        }

        QQC2.Button {
            text: i18n("Reset section to defaults")
            icon.name: "edit-undo"
            onClicked: page.resetCategoryBar()
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Wave background")
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Flow speed:")
            QQC2.Slider { id: waveFlowSpeedSlider; from: 0.0; to: 1.2; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveFlowSpeedSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Band amplitude:")
            QQC2.Slider { id: waveBandAmpSlider; from: 0.0; to: 0.6; stepSize: 0.002; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveBandAmpSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Wave height:")
            QQC2.Slider { id: waveHeightScaleSlider; from: 0.0; to: 1.0; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveHeightScaleSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Soft clip:")
            QQC2.Slider { id: waveSoftClipSlider; from: 0.05; to: 0.5; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveSoftClipSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Tension:")
            QQC2.Slider { id: waveTensionSlider; from: 0.0; to: 0.5; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveTensionSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Fresnel power:")
            QQC2.Slider { id: waveFresnelPowerSlider; from: 0.2; to: 8.0; stepSize: 0.05; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveFresnelPowerSlider.value.toFixed(2); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Fresnel scale:")
            QQC2.Slider { id: waveFresnelScaleSlider; from: 0.0; to: 2.0; stepSize: 0.01; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveFresnelScaleSlider.value.toFixed(2); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Wave opacity:")
            QQC2.Slider { id: waveOpacitySlider; from: 0.0; to: 1.0; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveOpacitySlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Brightness:")
            QQC2.Slider { id: waveBrightnessSlider; from: 0.0; to: 2.0; stepSize: 0.01; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveBrightnessSlider.value.toFixed(2); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        QQC2.SpinBox {
            id: waveRowCountSpin
            Kirigami.FormData.label: i18n("Wave detail (rows):")
            from: 24; to: 200; stepSize: 4
        }

        QQC2.Button {
            text: i18n("Reset section to defaults")
            icon.name: "edit-undo"
            onClicked: page.resetWave()
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Wave colour")
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: monthCombo
            Kirigami.FormData.label: i18n("Colour preset:")
            // index 0 = Automatic, 1..12 = month, 13 = Custom (RGB sliders)
            model: [i18n("Automatic (current month)"),
                    i18n("January"), i18n("February"), i18n("March"), i18n("April"),
                    i18n("May"), i18n("June"), i18n("July"), i18n("August"),
                    i18n("September"), i18n("October"), i18n("November"), i18n("December"),
                    i18n("Custom colour (RGB)")]
        }

        // RGB sliders apply only in Custom mode (index 13).
        RowLayout {
            Kirigami.FormData.label: i18n("Colour R:")
            enabled: monthCombo.currentIndex === 13
            QQC2.Slider { id: waveColorRSlider; from: 0; to: 255; stepSize: 1; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: Math.round(waveColorRSlider.value); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Colour G:")
            enabled: monthCombo.currentIndex === 13
            QQC2.Slider { id: waveColorGSlider; from: 0; to: 255; stepSize: 1; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: Math.round(waveColorGSlider.value); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Colour B:")
            enabled: monthCombo.currentIndex === 13
            QQC2.Slider { id: waveColorBSlider; from: 0; to: 255; stepSize: 1; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: Math.round(waveColorBSlider.value); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Gradient top mul:")
            enabled: monthCombo.currentIndex === 13
            QQC2.Slider { id: waveTopMulSlider; from: 0.0; to: 0.3; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveTopMulSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Gradient bottom mul:")
            enabled: monthCombo.currentIndex === 13
            QQC2.Slider { id: waveBotMulSlider; from: 0.2; to: 1.2; stepSize: 0.005; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveBotMulSlider.value.toFixed(3); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }

        QQC2.Button {
            text: i18n("Reset section to defaults")
            icon.name: "edit-undo"
            onClicked: page.resetWaveColour()
        }

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Particles")
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: particlesEnabledCheck
            Kirigami.FormData.label: i18n("Particles:")
            text: i18n("Enabled")
        }
        QQC2.SpinBox {
            id: waveParticleCountSpin
            Kirigami.FormData.label: i18n("Count:")
            from: 10; to: 4000; stepSize: 10
            editable: true
            enabled: particlesEnabledCheck.checked
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Opacity:")
            enabled: particlesEnabledCheck.checked
            QQC2.Slider { id: waveParticleOpacitySlider; from: 0.0; to: 1.0; stepSize: 0.01; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveParticleOpacitySlider.value.toFixed(2); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Flow speed:")
            enabled: particlesEnabledCheck.checked
            QQC2.Slider { id: waveParticleFlowSpeedSlider; from: 0.0; to: 3.0; stepSize: 0.01; Layout.preferredWidth: page.controlWidth }
            QQC2.Label { text: waveParticleFlowSpeedSlider.value.toFixed(2); Layout.minimumWidth: valueColumnWidth; horizontalAlignment: Text.AlignRight }
        }

        QQC2.Button {
            text: i18n("Reset section to defaults")
            icon.name: "edit-undo"
            onClicked: page.resetParticles()
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
