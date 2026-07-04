// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// Containment entry point: the XMB homescreen that fills the Bigscreen shell.
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.bigscreen as Bigscreen
import org.kde.bigscreen.controllerhandler as ControllerHandler

ContainmentItem {
    id: root

    Dashboard {
        anchors.fill: parent
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

    HomeOverlay { id: homeOverlay }

    // Home button (controller PS/Guide or remote) and the Meta key raise the app switcher; Back closes it.
    Plasmoid.onActivated: homeOverlay.toggle()
    Bigscreen.BackHandler.onActivated: homeOverlay.hideOverlay()
    Connections {
        target: ControllerHandler.ControllerHandlerStatus
        function onHomeActionRequested() { homeOverlay.toggle() }
    }

    // The inputhandler suppresses controller-as-keyboard input by default; the homescreen
    // must un-suppress it while it is the foreground surface, or the D-pad never reaches us.
    readonly property bool winActive: root.Window.active
    onWinActiveChanged: if (winActive) claimController()
    function claimController() {
        ControllerHandler.ControllerHandlerStatus.inputSuppressed = false
    }
    Component.onCompleted: claimController()
}
