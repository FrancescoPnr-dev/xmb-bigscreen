// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// Containment entry point: the XMB homescreen that fills the Bigscreen shell.
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as P5Support
import org.kde.bigscreen as Bigscreen
import org.kde.bigscreen.controllerhandler as ControllerHandler

ContainmentItem {
    id: root

    Dashboard {
        id: dashboard
        anchors.fill: parent
        appletInterface: root
        favorites: Plasmoid.configuration.favorites
        iconTheme: Plasmoid.configuration.iconTheme
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

    HomeOverlay {
        id: homeOverlay
        navTickSource: dashboard.navSoundSource
        navTickVolume: dashboard.navSoundVolume
        onConfigRequested: Plasmoid.internalAction("configure").trigger()
    }

    // Home button (controller PS/Guide or remote) and the Meta key raise the app switcher; Back closes it.
    Plasmoid.onActivated: homeOverlay.toggle()
    Bigscreen.BackHandler.onActivated: homeOverlay.hideOverlay()
    Connections {
        target: ControllerHandler.ControllerHandlerStatus
        function onHomeActionRequested() { homeOverlay.toggle() }
        function onSdlControllerAdded(name) { root.showOsd("input-gamepad-symbolic", i18n("Controller connected: %1", name)) }
        function onSdlControllerRemoved(name) { root.showOsd("input-gamepad-symbolic", i18n("Controller disconnected: %1", name)) }
        function onCecControllerAdded(name) { root.showOsd("input-tvremote-symbolic", i18n("Remote connected: %1", name)) }
        function onCecControllerRemoved(name) { root.showOsd("input-tvremote-symbolic", i18n("Remote disconnected: %1", name)) }
        function onInputSuppressedChanged(suppressed, automatic) {
            if (!automatic) return
            root.showOsd("input-gamepad-symbolic",
                         suppressed ? i18n("An application is using the controller") : i18n("Controller back to the system"))
        }
    }

    // System OSD (shows over everything) for controller/remote feedback, via the real
    // Plasma osdService — Plasmoid.showOSD isn't available outside the native shell.
    P5Support.DataSource {
        id: osdExec
        engine: "executable"
        onNewData: (s) => osdExec.disconnectSource(s)
    }
    function showOsd(icon, text) {
        var safe = String(text).replace(/"/g, "'")
        osdExec.connectSource("qdbus6 org.kde.plasmashell /org/kde/osdService org.kde.osdService.showText \""
                              + icon + "\" \"" + safe + "\"")
    }
}
