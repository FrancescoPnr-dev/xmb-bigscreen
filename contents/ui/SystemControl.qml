// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// Single gateway to the session backends shared by the dashboard, top bar and
// home overlay: volume (plasma-pa), display brightness (powerdevil), the shell
// OSD, power/session actions, the Bigscreen settings app and sleep inhibition.
import QtQuick
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.sessions as Sessions
import org.kde.plasma.private.volume
import org.kde.plasma.private.brightnesscontrolplugin
import org.kde.plasma.private.batterymonitor
import org.kde.plasma.workspace.dbus as DBus
import org.kde.bigscreen.shell as BigscreenShell

Item {
    id: control

    visible: false

    readonly property alias session: session
    Sessions.SessionManagement { id: session }

    // Volume: same backend as the native Bigscreen volume indicator, reactive.
    readonly property var sink: PreferredDevice.sink
    readonly property bool volumeAvailable: sink !== null && sink.name !== "auto_null"
    readonly property int volumePercent: volumeAvailable
        ? Math.round(sink.volume / PulseAudio.NormalVolume * 100) : -1
    function volumeStep(up) {
        if (!volumeAvailable)
            return
        var step = Math.round(PulseAudio.NormalVolume * 0.05)
        sink.volume = Math.max(0, Math.min(PulseAudio.NormalVolume,
                                           sink.volume + (up ? step : -step)))
    }

    // Brightness: powerdevil's per-display control; the first display drives the UI.
    ScreenBrightnessControl {
        id: screenBrightness
        isSilent: true
    }
    Instantiator {
        id: displayMirror
        model: screenBrightness.displays
        delegate: QtObject { required property var model }
    }
    readonly property var _display0: displayMirror.count > 0 ? displayMirror.objectAt(0) : null
    readonly property bool brightnessAvailable: screenBrightness.isBrightnessAvailable
        && _display0 !== null && (_display0.model.maxBrightness || 0) > 0
    readonly property int brightnessPercent: brightnessAvailable
        ? Math.round(_display0.model.brightness * 100 / _display0.model.maxBrightness) : -1
    function brightnessStep(up) {
        for (var i = 0; i < displayMirror.count; i++) {
            var m = displayMirror.objectAt(i).model
            var max = m.maxBrightness || 0
            if (max <= 0)
                continue
            var step = Math.max(1, Math.round(max * 0.05))
            screenBrightness.setBrightness(m.displayName,
                Math.max(0, Math.min(max, m.brightness + (up ? step : -step))))
        }
    }

    // System OSD via the plasmashell osdService, shown over everything.
    function showOsd(icon, text) {
        DBus.SessionBus.asyncCall({
            service: "org.kde.plasmashell",
            path: "/org/kde/osdService",
            iface: "org.kde.osdService",
            member: "showText",
            arguments: [icon, String(text)]
        })
    }

    // A controller plugged in mid-session may be new to the mapping file: regenerate
    // it and, only when it actually changed, restart the input handler so SDL reloads
    // it (mappings are read once at daemon start). The change guard prevents loops,
    // since the restarted daemon announces the pad again.
    function refreshPadMapping() {
        launcher.connectSource("sh -c '"
            + "f=\"${XDG_CONFIG_HOME:-$HOME/.config}/xmb-bigscreen/gamecontroller-swap.txt\"; "
            + "old=$(md5sum \"$f\" 2>/dev/null); xmb-bigscreen-stick-swap >/dev/null 2>&1; "
            + "[ \"$old\" != \"$(md5sum \"$f\" 2>/dev/null)\" ] && "
            + "systemctl --user restart \"app-org.kde.plasma.bigscreen.inputhandler@*.service\"'")
    }

    // Bigscreen's own TV settings app; a kcmId deep-links a mediacenter module.
    function openSettings(kcmId) {
        launcher.connectSource(kcmId && kcmId.length > 0
            ? "plasma-bigscreen-settings -m " + kcmId
            : "plasma-bigscreen-settings")
    }
    P5Support.DataSource {
        id: launcher
        engine: "executable"
        onNewData: (src) => launcher.disconnectSource(src)
    }

    // Honour the sleep-inhibition toggle from Bigscreen's System settings, as the
    // native homescreen does.
    InhibitionControl {
        id: inhibition
        isSilent: false
    }
    // The initial binding already fires the change handler when the setting is on.
    readonly property bool pmInhibit: BigscreenShell.Settings.pmInhibitionEnabled
    onPmInhibitChanged: {
        if (pmInhibit)
            inhibition.inhibit(i18n("XMB BigScreen is preventing the system from sleeping"))
        else
            inhibition.uninhibit()
    }
}
