// SPDX-FileCopyrightText: 2026 Francesco Panarese
// SPDX-License-Identifier: GPL-3.0-only
// Fullscreen frameless XMB overlay: a top-level Window, not a plasmoid popup.
import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtMultimedia
import org.kde.plasma.private.kicker as Kicker
import org.kde.kitemmodels as KItemModels
import "i18n-catalogs.js" as Catalogs

Window {
    id: dashboard

    // Config injected by main.qml from Plasmoid.configuration.
    property real backgroundOpacity: 0.85
    property int categoryIconSize: 112
    property int appIconSize: 56
    property real intersectionXFraction: 0.30
    property var hiddenCategories: []

    property real hotZoneFractionLeft: 0.15
    property real hotZoneFractionRight: 0.15
    property int  minScrollSpeed: 150
    property int  maxScrollSpeed: 2600
    property int  snapDuration: 220
    property real magneticStrength: 0.7
    property int  hotZoneBandHeight: 200   // px band around the category row
    property bool manageScreenEdges: false

    // XMB wave background (port of linkev/PlayStation-3-XMB); defaults mirror the demo.
    property real waveFlowSpeed: 0.25
    property real waveBandAmplitude: 0.20
    property real waveHeightScale: 0.5
    property real waveSoftClip: 0.22
    property real waveTension: 0.12
    property real waveFresnelPower: 4.0
    property real waveFresnelScale: 0.5
    property real waveOpacity: 0.7
    property real waveBrightness: 0.98
    property int  waveRowCount: 200
    property int  waveColorMonth: 0
    property int  waveColorR: 37
    property int  waveColorG: 89
    property int  waveColorB: 179
    property real waveGradientTopMul: 0.09
    property real waveGradientBotMul: 0.62
    property bool waveParticlesEnabled: true
    property int  waveParticleCount: 2000
    property real waveParticleOpacity: 0.9
    property real waveParticleFlowSpeed: 0.8

    // navSoundMode: 0 = bundled XMB-style tick, 1 = custom file, 2 = off.
    property int  navSoundMode: 0
    property string navSoundFile: ""
    property real navSoundVolume: 0.5
    // The original PS3 sound is never bundled; mode 1 loads the user's own local file.
    readonly property url navSoundSource:
        navSoundMode === 2 ? Qt.url("")
        : navSoundMode === 1
            ? (navSoundFile.length === 0 ? Qt.url("")
               : (navSoundFile.indexOf("://") !== -1 ? Qt.url(navSoundFile)
                  : Qt.url("file://" + navSoundFile)))
        : Qt.resolvedUrl("../sounds/nav-tick.wav")

    // Looping background ambience, faded in/out on open/close.
    // ambientSoundMode: 0 = bundled loop, 1 = custom file, 2 = off.
    property int ambientSoundMode: 0
    property string ambientSoundFile: ""
    property real ambientSoundVolume: 0.5
    readonly property url ambientSoundSource:
        ambientSoundMode === 2 ? Qt.url("")
        : ambientSoundMode === 1
            ? (ambientSoundFile.length === 0 ? Qt.url("")
               : (ambientSoundFile.indexOf("://") !== -1 ? Qt.url(ambientSoundFile)
                  : Qt.url("file://" + ambientSoundFile)))
        : Qt.resolvedUrl("../sounds/ambient-loop.wav")

    property int clockTimeFormat: 0
    property int clockDateFormat: 0
    property bool clockShowDate: true

    property int topBarPosition: 0

    // "" = system language; otherwise a code from the bundled catalogs.
    property string uiLanguage: ""
    onUiLanguageChanged: rebuildCategories()
    function tr(msg) {
        if (uiLanguage === "")
            return i18n(msg)
        if (uiLanguage === "en")
            return msg
        var c = Catalogs.catalogs[uiLanguage]
        return (c && c[msg]) || msg
    }
    property real ambientLevel: 0.0
    Behavior on ambientLevel { NumberAnimation { duration: 1400; easing.type: Easing.InOutSine } }

    // Committed only on a real selection, so the app list doesn't reload mid-glide.
    property int committedIndex: 0

    // Favourites are NOT the system favourites — our own list of app IDs from config.
    property var appletInterface: null
    property var favorites: []
    onFavoritesChanged: rebuildFavorites()

    property var categories: []

    // Unique title matched by the KWin "keep above" rule (install-kwin-rule.sh), so the
    // overlay stays above a revealing auto-hide panel.
    title: "XMB Dashboard"
    width: Screen.width
    height: Screen.height
    color: "transparent"
    // Frameless alone is enough; on Wayland adding StaysOnTop to a frameless parentless
    // window can stop the surface from mapping at all.
    flags: Qt.FramelessWindowHint
    transientParent: null
    visible: false

    // Auto-close on focus loss, but only once the window has been active: on Wayland
    // focus isn't synchronous after show(), so a naive !active check dismisses it mid-open.
    property bool autoCloseArmed: false
    property bool everActive: false

    // Frees Plasma's screen edges to the dashboard while open (corners stay active).
    EdgeGuard { id: edgeGuard }

    function open() {
        console.log("XMB: Dashboard.open() called")
        autoCloseArmed = false
        everActive = false
        if (dashboard.manageScreenEdges)
            edgeGuard.disableSystemEdges()
        dashboard.showFullScreen()
        dashboard.raise()
        dashboard.requestActivate()
        content.forceActiveFocus()
        armTimer.restart()
        console.log("XMB: after show -> visible=" + dashboard.visible
                    + " visibility=" + dashboard.visibility)
    }
    function close() {
        console.log("XMB: Dashboard.close() called")
        autoCloseArmed = false
        everActive = false
        edgeGuard.restoreSystemEdges()
        dashboard.visible = false
    }
    function toggle() {
        console.log("XMB: Dashboard.toggle(), currently visible=" + dashboard.visible)
        dashboard.visible ? close() : open()
    }

    onVisibleChanged: {
        console.log("XMB: Dashboard visibleChanged -> " + visible)
        if (visible) {
            if (ambientSoundSource.toString() !== "") {
                ambientStopTimer.stop()
                ambientLoop.play()
                ambientLevel = 1.0
            }
        } else {
            ambientLevel = 0.0            // fade out, then stop to free the device
            ambientStopTimer.restart()
        }
    }

    // onVisibleChanged only fires on open/close; this covers mode/file changes while
    // open (mode 2 and mode 1 with no file both resolve to an empty source).
    onAmbientSoundSourceChanged: {
        if (!visible)
            return
        if (ambientSoundSource.toString() !== "") {
            ambientStopTimer.stop()
            ambientLoop.play()
            ambientLevel = 1.0
        } else {
            ambientLevel = 0.0
            ambientStopTimer.restart()
        }
    }

    onActiveChanged: {
        if (active) {
            everActive = true
        } else if (autoCloseArmed && everActive) {
            close()
        }
    }
    Timer {
        id: armTimer
        interval: 350
        onTriggered: dashboard.autoCloseArmed = true
    }

    // Same source as Kickoff; showAllAppsCategorized makes rootModel.modelForRow(i) a category's apps.
    Kicker.RootModel {
        id: rootModel
        autoPopulate: true
        appletInterface: dashboard.appletInterface
        showAllApps: false
        showAllAppsCategorized: true
        showRecentApps: false
        showRecentDocs: false
        showRecentFolders: false
        showPowerSession: false
        showFavoritesPlaceholder: false
        showSeparators: false
        appNameFormat: 0
        onCountChanged: Qt.callLater(dashboard.rebuildCategories)
    }

    // Flat list of all installed apps: source for resolving + launching favourites.
    Kicker.RootModel {
        id: allAppsRoot
        autoPopulate: true
        appletInterface: dashboard.appletInterface
        showAllApps: true
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showRecentFolders: false
        showPowerSession: false
        showFavoritesPlaceholder: false
        showSeparators: false
        appNameFormat: 0
        onCountChanged: {
            dashboard.allAppsFlat = allAppsRoot.modelForRow(0)
            Qt.callLater(dashboard.rebuildFavorites)
        }
    }
    property var allAppsFlat: null

    // favoriteId -> source row over the flat list, mapping our config IDs to apps.
    Instantiator {
        id: appIndex
        model: dashboard.allAppsFlat
        delegate: QtObject {
            required property string favoriteId
            required property int index
        }
        onObjectAdded: Qt.callLater(dashboard.rebuildFavorites)
        onObjectRemoved: Qt.callLater(dashboard.rebuildFavorites)
    }

    KItemModels.KSortFilterProxyModel {
        id: favProxy
        sourceModel: dashboard.allAppsFlat
        filterRowCallback: function(sourceRow, sourceParent) { return false }
    }

    function rebuildFavorites() {
        var byId = {}
        for (var i = 0; i < appIndex.count; i++) {
            var o = appIndex.objectAt(i)
            if (o && o.favoriteId)
                byId[o.favoriteId] = o.index
        }
        var rows = {}
        var favs = dashboard.favorites || []
        for (var j = 0; j < favs.length; j++) {
            var r = byId[favs[j]]
            if (r !== undefined)
                rows[r] = true
        }
        // Reassigning the callback re-runs the filter.
        favProxy.filterRowCallback = function(sourceRow, sourceParent) { return rows[sourceRow] === true }
    }

    // Non-visual mirror so we can read name + icon per source row in plain JS.
    Instantiator {
        id: categorySource
        model: rootModel
        delegate: QtObject {
            required property string display
            required property var decoration
            readonly property string name: display
            readonly property var icon: decoration
            // Stable, locale-independent persistence key (freedesktop icon name), else display name.
            readonly property string key: decoration ? String(decoration) : display
        }
        onObjectAdded: Qt.callLater(dashboard.rebuildCategories)
        onObjectRemoved: Qt.callLater(dashboard.rebuildCategories)
    }

    onHiddenCategoriesChanged: rebuildCategories()

    function rebuildCategories() {
        var arr = []
        for (var i = 0; i < categorySource.count; i++) {
            var o = categorySource.objectAt(i)
            if (!o)
                continue
            if (hiddenCategories.indexOf(o.key) !== -1)
                continue
            arr.push({ name: o.name, icon: o.icon, key: o.key, sourceRow: i })
        }
        // "Favourites" is always the first category; hideable like the rest via its key.
        if (hiddenCategories.indexOf("__favorites__") === -1)
            arr.unshift({ name: tr("Favorites"), icon: "bookmarks",
                          key: "__favorites__", sourceRow: -1, favorites: true })
        categories = arr
        // CategoryBar self-clamps its position; we only clamp the committed index.
        if (committedIndex > Math.max(0, arr.length - 1))
            committedIndex = Math.max(0, arr.length - 1)
    }

    readonly property var currentCategory:
        (committedIndex >= 0 && committedIndex < categories.length)
            ? categories[committedIndex] : null
    readonly property var appsModel:
        currentCategory
            ? (currentCategory.favorites ? favProxy
                                         : rootModel.modelForRow(currentCategory.sourceRow))
            : null

    // Animated XMB wave backdrop; a Loader so we fall back to a gradient if ShaderEffect is unavailable.
    Loader {
        id: backgroundLoader
        anchors.fill: parent
        opacity: dashboard.backgroundOpacity
        Behavior on opacity { NumberAnimation { duration: 150 } }
        source: Qt.resolvedUrl("WaveBackground.qml")

        onStatusChanged: {
            if (status === Loader.Error) {
                console.warn("XMB: ShaderEffect unavailable, using gradient fallback")
                source = Qt.resolvedUrl("WaveBackgroundFallback.qml")
            }
        }
        onLoaded: {
            item.animating = Qt.binding(function() { return dashboard.visible })
            item.flowSpeed = Qt.binding(function() { return dashboard.waveFlowSpeed })
            item.bandAmplitude = Qt.binding(function() { return dashboard.waveBandAmplitude })
            item.waveHeightScale = Qt.binding(function() { return dashboard.waveHeightScale })
            item.waveSoftClip = Qt.binding(function() { return dashboard.waveSoftClip })
            item.tension = Qt.binding(function() { return dashboard.waveTension })
            item.fresnelPower = Qt.binding(function() { return dashboard.waveFresnelPower })
            item.fresnelScale = Qt.binding(function() { return dashboard.waveFresnelScale })
            item.waveOpacity = Qt.binding(function() { return dashboard.waveOpacity })
            item.brightness = Qt.binding(function() { return dashboard.waveBrightness })
            item.rowCount = Qt.binding(function() { return dashboard.waveRowCount })
            if (item.hasOwnProperty("colorMonth"))
                item.colorMonth = Qt.binding(function() { return dashboard.waveColorMonth })
            item.colorR = Qt.binding(function() { return dashboard.waveColorR })
            item.colorG = Qt.binding(function() { return dashboard.waveColorG })
            item.colorB = Qt.binding(function() { return dashboard.waveColorB })
            item.gradientTopMul = Qt.binding(function() { return dashboard.waveGradientTopMul })
            item.gradientBotMul = Qt.binding(function() { return dashboard.waveGradientBotMul })
            if (item.hasOwnProperty("particlesEnabled"))
                item.particlesEnabled = Qt.binding(function() { return dashboard.waveParticlesEnabled })
            if (item.hasOwnProperty("pDensity"))
                item.pDensity = Qt.binding(function() { return dashboard.waveParticleCount / 2000.0 })
            item.pOpacity = Qt.binding(function() { return dashboard.waveParticleOpacity })
            item.pFlowSpeed = Qt.binding(function() { return dashboard.waveParticleFlowSpeed })
        }
    }

    FocusScope {
        id: content
        anchors.fill: parent
        focus: true

        // Light blur over the cross while search/top bar is active; layer off when idle for no cost.
        readonly property bool blurWanted: searchOverlay.active || topBar.powerExpanded || topBar.contentHovered
        property real blurAmt: blurWanted ? 0.45 : 0.0
        Behavior on blurAmt { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
        layer.enabled: blurAmt > 0.001
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: content.blurAmt
            blurMax: 24
            brightness: -0.08 * (content.blurAmt / 0.45)
        }

        readonly property real interX: width * dashboard.intersectionXFraction
        // Bar sits above centre, selected app pins at centre, so apps fan out clear of the icon.
        readonly property real barCenterY: height * 0.42
        readonly property real appPinY: height * 0.54

        MouseArea {
            anchors.fill: parent
            onClicked: dashboard.close()
        }

        // Middle-click anywhere launches the highlighted app. TapHandler (not MouseArea) so it
        // doesn't override the hover cursor or steal clicks from items below.
        TapHandler {
            acceptedButtons: Qt.MiddleButton
            enabled: !searchOverlay.active
            onTapped: appColumn.launchCurrent()
        }

        // Tracks the cursor for the category bar's edge hot zones (passive).
        HoverHandler {
            id: pointerTracker
        }

        // Horizontal arm
        CategoryBar {
            id: categoryBar
            width: parent.width
            y: content.barCenterY - height / 2
            intersectionX: content.interX
            iconSize: dashboard.categoryIconSize
            model: dashboard.categories
            z: 1

            pointerX: pointerTracker.point.position.x
            pointerY: pointerTracker.point.position.y
            pointerActive: pointerTracker.hovered
            bandCenterY: content.barCenterY
            bandHeight: dashboard.hotZoneBandHeight
            hotZoneFractionLeft: dashboard.hotZoneFractionLeft
            hotZoneFractionRight: dashboard.hotZoneFractionRight
            minScrollSpeed: dashboard.minScrollSpeed
            maxScrollSpeed: dashboard.maxScrollSpeed
            snapDuration: dashboard.snapDuration
            magneticStrength: dashboard.magneticStrength

            onCommitted: (index) => dashboard.committedIndex = index
        }

        // Vertical arm
        AppColumn {
            id: appColumn
            x: content.interX - dashboard.appIconSize / 2
            y: 0
            width: 480
            height: parent.height
            intersectionY: content.appPinY
            iconSize: dashboard.appIconSize
            // Category-row geometry, so apps scrolled above the selection clear it.
            categoryCenterY: content.barCenterY
            categoryIconSize: dashboard.categoryIconSize
            model: dashboard.appsModel
            z: 2
            // Wheel adjusts the top bar's quick settings when hovering it, not the apps.
            wheelLocked: topBar.contentHovered
            // The favourites proxy has no trigger() — launch via the source model.
            launchHandler: (dashboard.currentCategory && dashboard.currentCategory.favorites)
                ? function(idx) {
                      var src = favProxy.mapToSource(favProxy.index(idx, 0))
                      if (src.valid && dashboard.allAppsFlat)
                          dashboard.allAppsFlat.trigger(src.row, "", null)
                  }
                : null
            onAppLaunched: dashboard.close()
        }

        // Navigation
        Keys.onLeftPressed:  categoryBar.goPrev()
        Keys.onRightPressed: categoryBar.goNext()
        Keys.onUpPressed:    appColumn.up()
        Keys.onDownPressed:  appColumn.down()
        Keys.onReturnPressed: appColumn.launchCurrent()
        Keys.onEnterPressed:  appColumn.launchCurrent()
        Keys.onEscapePressed: dashboard.close()

        // Type-to-search: a printable char opens the KRunner overlay seeded with it;
        // nav keys (empty text) fall through to the handlers above.
        Keys.onPressed: (event) => {
            if (!searchOverlay.active
                    && event.text.length === 1 && event.text.trim().length === 1
                    && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                searchOverlay.start(event.text)
                event.accepted = true
            }
        }

        WheelHandler {
            enabled: !searchOverlay.active && !topBar.contentHovered
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            // Step one app per full notch (120) so hi-res/touchpad deltas don't miscount.
            property real accumY: 0
            onWheel: (event) => {
                if ((accumY > 0) !== (event.angleDelta.y > 0))
                    accumY = 0
                accumY += event.angleDelta.y
                while (accumY <= -120) { appColumn.down(); accumY += 120 }
                while (accumY >=  120) { appColumn.up();   accumY -= 120 }
                if (event.angleDelta.x < 0)       categoryBar.goNext()
                else if (event.angleDelta.x > 0)  categoryBar.goPrev()
            }
        }
    }

    XmbClock {
        z: 100
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Math.round(dashboard.height * 0.06)
        anchors.rightMargin: Math.round(dashboard.width * 0.025)
        pixelSize: Math.max(20, Math.round(dashboard.height * 0.026))
        timeFormat: dashboard.clockTimeFormat
        dateFormat: dashboard.clockDateFormat
        showDate: dashboard.clockShowDate
    }

    // Top-edge reveal system bar, independent of Plasma's screen edges.
    XmbTopBar {
        id: topBar
        anchors.fill: parent
        z: 90
        atBottom: dashboard.topBarPosition === 1
        translate: dashboard.tr
        onActionTriggered: dashboard.close()
    }

    XmbSearch {
        id: searchOverlay
        anchors.fill: parent
        z: 110
        onLaunched: dashboard.close()
        onClosed: content.forceActiveFocus()
    }

    XmbSound {
        id: navSound
        source: dashboard.navSoundSource
        volume: dashboard.navSoundVolume
    }

    // Background loop (gapless for WAV); volume tracks the animated fade level.
    XmbSound {
        id: ambientLoop
        source: dashboard.ambientSoundSource
        looping: true
        volume: dashboard.ambientLevel * dashboard.ambientSoundVolume
    }
    Timer {
        id: ambientStopTimer
        interval: 1500
        onTriggered: ambientLoop.stop()
    }
    function playNavTick() {
        // Only past the open transition, so we don't tick on initial model population.
        if (!dashboard.visible || !dashboard.autoCloseArmed || dashboard.navSoundMode === 2)
            return
        navSound.play()
    }

    Connections {
        target: categoryBar
        function onCurrentIndexChanged() { dashboard.playNavTick() }
    }
    // Explicit up/down only, so category-switch model resets stay silent.
    Connections {
        target: appColumn
        function onNavigated() { dashboard.playNavTick() }
    }
}
