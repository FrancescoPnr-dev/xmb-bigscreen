// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// One-shot or looping sound player for UI feedback (navigation tick, ambience).
// WAV goes through SoundEffect (low latency, clean retrigger, gapless loop);
// anything else via MediaPlayer. play() restarts from the start; empty source = silent.
import QtQuick
import QtMultimedia

Item {
    id: root

    property url source: ""
    property real volume: 0.6
    property bool looping: false
    readonly property bool isWav: root.source.toString().toLowerCase().endsWith(".wav")

    SoundEffect {
        id: effect
        source: root.isWav ? root.source : ""
        volume: root.volume
        loops: root.looping ? SoundEffect.Infinite : 1
    }

    MediaPlayer {
        id: player
        source: root.isWav ? "" : root.source
        audioOutput: AudioOutput { volume: root.volume }
        loops: root.looping ? MediaPlayer.Infinite : 1
    }

    function play() {
        if (root.source.toString() === "")
            return
        if (root.isWav) {
            effect.stop()
            effect.play()
        } else {
            player.stop()
            player.play()
        }
    }

    function stop() {
        effect.stop()
        player.stop()
    }
}
