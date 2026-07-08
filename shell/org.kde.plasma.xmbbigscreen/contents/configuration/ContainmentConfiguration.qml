// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// The XMB paints its own background, so the dialog drops the wallpaper/mouse
// pages and shows only the applet's own configuration.
import org.kde.plasma.configuration

AppletConfiguration {
    globalConfigModel: ConfigModel {}
}
