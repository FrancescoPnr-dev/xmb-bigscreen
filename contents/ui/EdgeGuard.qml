// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import org.kde.plasma.plasma5support as P5Support

Item {
    id: guard

    property bool active: false

    P5Support.DataSource {
        id: exec
        engine: "executable"
        onNewData: (sourceName, data) => exec.disconnectSource(sourceName)
    }
    function run(cmd) { exec.connectSource(cmd) }

    // Parks the user's ElectricBorders value in kwinrc (crash-safe) before forcing 0; never overwrites an existing backup.
    function disableSystemEdges() {
        if (active) return
        active = true
        run("b=$(kreadconfig6 --file kwinrc --group XmbDashboard --key SavedElectricBorders); " +
            "if [ -z \"$b\" ]; then " +
              "v=$(kreadconfig6 --file kwinrc --group Windows --key ElectricBorders); " +
              "kwriteconfig6 --file kwinrc --group XmbDashboard --key SavedElectricBorders \"${v:-unset}\"; " +
            "fi; " +
            "kwriteconfig6 --file kwinrc --group Windows --key ElectricBorders 0; " +
            "qdbus6 org.kde.KWin /KWin reconfigure")
    }

    // Puts back exactly what was parked ("unset" deletes the key); no-op without a backup.
    function restoreSystemEdges() {
        active = false
        run("b=$(kreadconfig6 --file kwinrc --group XmbDashboard --key SavedElectricBorders); " +
            "if [ -n \"$b\" ]; then " +
              "if [ \"$b\" = unset ]; then " +
                "kwriteconfig6 --file kwinrc --group Windows --key ElectricBorders --delete; " +
              "else " +
                "kwriteconfig6 --file kwinrc --group Windows --key ElectricBorders \"$b\"; " +
              "fi; " +
              "kwriteconfig6 --file kwinrc --group XmbDashboard --key SavedElectricBorders --delete; " +
              "qdbus6 org.kde.KWin /KWin reconfigure; " +
            "fi")
    }

    Component.onCompleted: restoreSystemEdges()
    Component.onDestruction: restoreSystemEdges()
}
