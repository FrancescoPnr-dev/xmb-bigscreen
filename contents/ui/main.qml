// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// Plasmoid entry point: a panel button that toggles the fullscreen Dashboard.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // We show the button inline and never use a Plasma popup.
    preferredRepresentation: fullRepresentation
    fullRepresentation: buttonComponent

    Plasmoid.icon: Plasmoid.configuration.panelIcon || "applications-all"

    Component.onCompleted: {
        // Without this Plasma eats the click to toggle a popup and our handlers never fire.
        if (Plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            Plasmoid.activationTogglesExpanded = false
        }
    }

    Dashboard {
        id: dashboard
        appletInterface: root
        favorites: Plasmoid.configuration.favorites
        backgroundOpacity: Plasmoid.configuration.backgroundOpacity
        categoryIconSize: Plasmoid.configuration.categoryIconSize
        appIconSize: Plasmoid.configuration.appIconSize
        intersectionXFraction: Plasmoid.configuration.intersectionXFraction
        hiddenCategories: Plasmoid.configuration.hiddenCategories
        hotZoneFractionLeft: Plasmoid.configuration.hotZoneFractionLeft
        hotZoneFractionRight: Plasmoid.configuration.hotZoneFractionRight
        minScrollSpeed: Plasmoid.configuration.minScrollSpeed
        maxScrollSpeed: Plasmoid.configuration.maxScrollSpeed
        snapDuration: Plasmoid.configuration.snapDuration
        magneticStrength: Plasmoid.configuration.magneticStrength
        hotZoneBandHeight: Plasmoid.configuration.hotZoneBandHeight
        manageScreenEdges: Plasmoid.configuration.manageScreenEdges

        // XMB wave background (port of linkev/PlayStation-3-XMB)
        waveFlowSpeed: Plasmoid.configuration.waveFlowSpeed
        waveBandAmplitude: Plasmoid.configuration.waveBandAmplitude
        waveHeightScale: Plasmoid.configuration.waveHeightScale
        waveSoftClip: Plasmoid.configuration.waveSoftClip
        waveTension: Plasmoid.configuration.waveTension
        waveFresnelPower: Plasmoid.configuration.waveFresnelPower
        waveFresnelScale: Plasmoid.configuration.waveFresnelScale
        waveOpacity: Plasmoid.configuration.waveOpacity
        waveBrightness: Plasmoid.configuration.waveBrightness
        waveRowCount: Plasmoid.configuration.waveRowCount
        waveColorMonth: Plasmoid.configuration.waveColorMonth
        waveColorR: Plasmoid.configuration.waveColorR
        waveColorG: Plasmoid.configuration.waveColorG
        waveColorB: Plasmoid.configuration.waveColorB
        waveGradientTopMul: Plasmoid.configuration.waveGradientTopMul
        waveGradientBotMul: Plasmoid.configuration.waveGradientBotMul
        waveParticlesEnabled: Plasmoid.configuration.waveParticlesEnabled
        waveParticleCount: Plasmoid.configuration.waveParticleCount
        waveParticleOpacity: Plasmoid.configuration.waveParticleOpacity
        waveParticleFlowSpeed: Plasmoid.configuration.waveParticleFlowSpeed

        // Navigation sound
        navSoundMode: Plasmoid.configuration.navSoundMode
        navSoundFile: Plasmoid.configuration.navSoundFile
        navSoundVolume: Plasmoid.configuration.navSoundVolume

        // Background ambience
        ambientSoundMode: Plasmoid.configuration.ambientSoundMode
        ambientSoundFile: Plasmoid.configuration.ambientSoundFile
        ambientSoundVolume: Plasmoid.configuration.ambientSoundVolume

        // Clock
        clockTimeFormat: Plasmoid.configuration.clockTimeFormat
        clockDateFormat: Plasmoid.configuration.clockDateFormat
        clockShowDate: Plasmoid.configuration.clockShowDate

        topBarPosition: Plasmoid.configuration.topBarPosition
        uiLanguage: Plasmoid.configuration.language
    }

    // Keyboard / global-shortcut activation.
    Connections {
        target: Plasmoid
        function onActivated() {
            console.log("XMB: Plasmoid.activated()")
            dashboard.toggle()
        }
    }

    // The panel button: icon + a fill MouseArea to catch clicks.
    Component {
        id: buttonComponent

        Item {
            id: button

            Layout.minimumWidth: Kirigami.Units.iconSizes.small
            Layout.minimumHeight: Kirigami.Units.iconSizes.small
            Layout.maximumWidth: Kirigami.Units.iconSizes.enormous
            Layout.maximumHeight: Kirigami.Units.iconSizes.enormous

            Kirigami.Icon {
                id: buttonIcon
                anchors.fill: parent
                // Bundled monochrome XMB icon by default; a custom panelIcon overrides it.
                source: Plasmoid.configuration.panelIcon === "" || Plasmoid.configuration.panelIcon === "applications-all"
                    ? Qt.resolvedUrl("../icons/xmb-dashboard.svg") : Plasmoid.icon
                active: mouseArea.containsMouse
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                activeFocusOnTab: true

                Accessible.name: Plasmoid.title
                Accessible.role: Accessible.Button

                Keys.onReturnPressed: Plasmoid.activated()
                Keys.onEnterPressed: Plasmoid.activated()
                Keys.onSpacePressed: Plasmoid.activated()

                onClicked: {
                    console.log("XMB: panel icon clicked")
                    dashboard.toggle()
                }
            }
        }
    }
}
