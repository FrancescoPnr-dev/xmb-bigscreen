// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// On-screen keyboard for gamepad text entry: the injected d-pad arrows move the
// key highlight and Enter (Cross) commits the highlighted key. Needs the session
// to run with QT_IM_MODULE=qtvirtualkeyboard.
import QtQuick
import QtQuick.VirtualKeyboard
import QtQuick.VirtualKeyboard.Settings

InputPanel {
    active: true
    Component.onCompleted: VirtualKeyboardSettings.arrowKeyNavigationEnabled = true
}
