// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
/*
 * Declares the pages shown in the widget's configuration dialog.
 * Each ConfigCategory points at a QML file under contents/ui/config/.
 */
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "applications-all"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Favorites")
        icon: "bookmarks"
        source: "config/ConfigFavorites.qml"
    }
}
