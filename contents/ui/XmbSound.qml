// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// UI sound player: WAV via SoundEffect (low latency, gapless loop), anything else
// via MediaPlayer. play() restarts from the start; empty source = silent.
import QtQuick
import QtMultimedia

Item {
    id: root

    property url source: ""
    property real volume: 0.6
    property bool looping: false
    readonly property bool isWav: root.source.toString().toLowerCase().endsWith(".wav")
    readonly property bool playing: effectLoader.item ? effectLoader.item.playing
                                                      : playerLoader.item ? playerLoader.item.playing : false
    property bool active: false

    // QtMultimedia never rebinds a player to a new sink and setting audioDevice live
    // is inert: rebuild the players whenever the default output changes.
    MediaDevices { id: mediaDevices }
    readonly property string outputId: mediaDevices.defaultAudioOutput.description
    onOutputIdChanged: {
        const resume = root.active && root.looping
        effectLoader.reload()
        playerLoader.reload()
        if (resume)
            root.play()
    }

    Loader {
        id: effectLoader
        function reload() { active = false; active = true }
        sourceComponent: SoundEffect {
            source: root.isWav ? root.source : ""
            volume: root.volume
            loops: root.looping ? SoundEffect.Infinite : 1
        }
    }

    Loader {
        id: playerLoader
        function reload() { active = false; active = true }
        sourceComponent: MediaPlayer {
            source: root.isWav ? "" : root.source
            audioOutput: AudioOutput { volume: root.volume }
            loops: root.looping ? MediaPlayer.Infinite : 1
        }
    }

    function play() {
        if (root.source.toString() === "")
            return
        root.active = true
        const target = root.isWav ? effectLoader.item : playerLoader.item
        if (target) {
            target.stop()
            target.play()
        }
    }

    function stop() {
        root.active = false
        if (effectLoader.item)
            effectLoader.item.stop()
        if (playerLoader.item)
            playerLoader.item.stop()
    }
}
