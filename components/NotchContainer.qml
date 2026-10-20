import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtMultimedia
import Quickshell.Io
import "../theme"
import "../services"
import "lyrics.js" as Lyrics

// The island itself. Geometry and shape come from Atoll's own spec (theme/Atoll.qml).
//
// presentation "island" (default): floating Dynamic Island pill for displays
//   without a physical notch (radius 16 -> 24, floats Atoll.islandTopOffset below
//   the top edge).
// presentation "notch": the wide top-anchored panel that replaces a real macOS
//   notch (640x200, radii top19/bottom24).
// presentation "menuBar": the same top-anchored panel, but flush with the top
//   edge (square top corners) and closed at the menu-bar height, so it reads as
//   a dropdown from the system bar rather than a cutout below it.
Item {
    id: root

    // Active modes: "COMPACT", "EXPANDED"
    property string mode: "COMPACT"
    property string presentation: "island"
    property string activeTab: root.sanitizeTab(Settings.openLastTab ? Settings.str("lastTab", "HOME") : "HOME") // HOME, SHELF, TIMER, STATS, NOTES, CLIPBOARD, DOWNLOADS
    property bool shadowsEnabled: Settings.showShadow
    // Atoll's extras menu (the header's "…" button).
    property bool extrasOpen: false

    // Raised by the header gear capsule; the shell opens the Settings window.
    signal settingsRequested()

    // Raised by the header eyedropper in "panel" mode; the shell toggles the
    // floating colour-picker panel. "popover" mode draws in the island instead.
    signal colorPickerPanelRequested()
    property bool colorPopoverOpen: false

    // Raised by the header clipboard button in "panel" mode; the shell toggles
    // the floating clipboard panel. "popover" mode draws in the island instead.
    signal clipboardPanelRequested()
    property bool clipboardPopoverOpen: false

    // Clipboard placement: only "notchTab" gets its own tab; "separateTab" merges
    // it into the Notes tab (see Atoll's TabSelectionView).
    readonly property bool hasDedicatedClipboardTab:
        Settings.clipboardEnabled && Settings.clipboardMode === "notchTab"

    // True while something in the island needs the keyboard (the clipboard
    // popover's search field, the notes editor); shell.qml then lets the island
    // take focus on demand.
    readonly property bool wantsKeyboard:
        root.clipboardPopoverOpen || notesClipboard.wantsKeyboard

    // Tabs that no longer exist (or that live elsewhere now) fall back.
    function sanitizeTab(tab) {
        if (tab === "CALENDAR") return "HOME";
        if (tab === "CLIPBOARD" && !hasDedicatedClipboardTab) return "NOTES";
        if (tab === "TERMINAL" && !Settings.terminalEnabled) return "HOME";
        if (tab === "USAGE" && !Settings.llmUsageEnabled) return "HOME";
        return tab;
    }

    readonly property bool expanded: mode !== "COMPACT"
    readonly property bool island: presentation === "island"
    readonly property bool menuBar: presentation === "menuBar"

    // Dismiss the extras menu, the colour popover and the clipboard popover
    // whenever the island closes.
    onExpandedChanged: {
        if (!expanded) {
            extrasOpen = false;
            colorPopoverOpen = false;
            clipboardPopoverOpen = false;
        }
    }

    // "Open last tab by default" (General > Behaviour): remember every switch.
    onActiveTabChanged: {
        if (Settings.openLastTab) Settings.set("lastTab", activeTab);
    }

    // ---- Morph driver ----
    // Every geometric and content property below is derived from this single
    // spring (0 = compact pill, 1 = expanded card), so the silhouette, its
    // radii and the content all move in lockstep and retarget from the current
    // velocity when interrupted -- Atoll's feel.
    Spring {
        id: morph
        target: root.expanded ? 1 : 0
        // "Modern close animation" (Appearance): off = a quick, near-linear
        // collapse instead of the springy morph.
        // Reduce motion (Appearance): the shape stops travelling and the change
        // becomes an instant swap cross-faded by the Behaviors below, which is
        // what the HIG asks for (replace movement, keep the dissolve).
        response: Settings.reduceMotionEnabled ? 0.001
                  : (Settings.modernClose
                     ? (root.island ? Motion.morphResponseIsland : Motion.morphResponseNotch)
                     : 0.16)
        dampingFraction: Settings.reduceMotionEnabled ? 1.0
                         : (Settings.modernClose
                            ? (root.island ? Motion.morphDampingIsland : Motion.morphDampingNotch)
                            : 1.0)
    }

    readonly property real p: morph.value
    // Content is cross-faded inside the same spring: it starts once the shape
    // has begun opening and finishes just before the shape settles.
    property real contentProgress: Math.max(0, Math.min(1, (p - 0.18) / 0.68))
    property real compactProgress: Math.max(0, Math.min(1, 1 - p * 1.7))
    // With reduce motion the geometry jumps, so these carry the transition as a
    // plain fade.
    Behavior on contentProgress {
        enabled: Settings.reduceMotionEnabled
        NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic }
    }
    Behavior on compactProgress {
        enabled: Settings.reduceMotionEnabled
        NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic }
    }

    // Collapsed size. The media strip is wider than the idle pill (art +
    // title/artist + waveform), so the closed pill grows while a track is up.
    // Heights honour Appearance > "Notch size" (notch mode) / "Non-notch size".
    readonly property real compactBaseHeight: (island || menuBar)
        ? (Settings.nonNotchHeightMode === "custom" ? Settings.nonNotchHeight : Atoll.closedHeight)
        : (Settings.notchHeightMode === "custom" ? Settings.notchHeight : Atoll.closedHeight)

    // ---- Lyrics (side panel / inline line) and the camera mirror ----
    readonly property bool cameraAvailable: mediaDevices.videoInputs.length > 0
    // MusicManager's hasActiveSession gate, expressed with the MPRIS state.
    readonly property bool mediaSession: mprisService.hasMedia
    // SideLyricsLayout applies only while the calendar is not sharing the row.
    readonly property bool sideLyricsActive: Settings.lyrics && !Settings.minimalisticUI
        && !Settings.showCalendar && Settings.standardMediaControls
        && (!Settings.autoHideInactiveMedia || root.mediaSession) && root.mediaSession
    readonly property bool mirrorActive: Settings.showMirror && root.cameraAvailable && root.expanded

    // sideLyricsRequiredNotchWidth(): player floor + panel + spacing + offset +
    // optional mirror + the combined inset.
    readonly property real sideLyricsRequiredWidth: {
        if (!root.sideLyricsActive) return 0;
        var panel = Math.max(0, Settings.lyricsPanelWidth);
        var offset = Math.abs(Settings.lyricsPanelOffset);
        var mirror = (Settings.showMirror && root.cameraAvailable)
            ? Atoll.sideLyricsMinMirrorWidth + Atoll.sideLyricsSpacing : 0;
        return Atoll.sideLyricsMinPlayerWidth + panel + Atoll.sideLyricsSpacing
               + offset + mirror + Atoll.sideLyricsCombinedInset;
    }

    // ---- Pinned lyrics under the closed notch ----
    readonly property bool pinnedEligible: Settings.lyrics && Settings.pinLyricsWhenClosed
        && !root.expanded && !root.hudActive && root.mediaSession
    readonly property var pinnedSlotList: root.pinnedEligible
        ? lyricsService.pinnedSlots(Settings.pinnedLyricContext) : []
    readonly property real pinnedReserve: Lyrics.pinnedReservedHeight(
        root.pinnedEligible, lyricsService.availability, Settings.pinnedLyricContext,
        Atoll.pinnedLyricsRowHeight, Atoll.pinnedLyricsGap)
    readonly property int pinnedContext: Settings.pinnedLyricContext

    // The reserved strip collapses as the notch opens, so the shape does not
    // jump when the pin becomes ineligible.
    readonly property real pinnedShownHeight: root.pinnedReserve * root.compactProgress
    readonly property real compactHeight: root.compactBaseHeight + root.pinnedShownHeight
    // "Customise physical notch width" gates whether a notched display honours
    // the custom closed width; the floating pill always does.
    readonly property real compactBaseWidth: (island || Settings.customizePhysicalNotchWidth)
        ? Settings.closedWidth : Atoll.closedWidth
    readonly property real compactWidth: compactPill.showMedia
        ? Math.max(compactBaseWidth, Atoll.closedMediaWidth) : compactBaseWidth

    // Per-tab content heights live in the spec so the harness stays in sync.
    readonly property real contentHeight: Atoll.tabContentHeight(activeTab)

    readonly property real headerHeight: Atoll.headerButton + Atoll.headerPadding * 2
    // Atoll grows the open notch with the number of enabled tabs
    // (recommendedMinimumNotchWidth: >=6 -> 770, >=5 -> 690, else 640).
    readonly property real tabMinWidth: headerBar.visibleTabs.length >= 6 ? Atoll.notchOpenMinWidth6
                                        : headerBar.visibleTabs.length >= 5 ? Atoll.notchOpenMinWidth5
                                        : Atoll.notchOpenMinWidthFew
    // Open width: Settings > "Open width" (minimalistic mode uses Atoll's 420),
    // but never narrower than the header strip needs or the tab count asks for.
    readonly property real openWidth: Math.max(
        Math.max(Settings.minimalisticUI ? Atoll.islandOpenWidth : Settings.openWidth,
                 island ? 0 : tabMinWidth),
        headerBar.implicitWidth + Atoll.headerPadding * 2,
        root.sideLyricsRequiredWidth)
    // Atoll uses a fixed 200 in notch mode, but our widgets are taller than
    // Atoll's bespoke views, so grow to fit rather than clip.
    readonly property real openHeight: Math.max(
        island ? Atoll.islandOpenHeight : Atoll.notchOpenHeight,
        headerHeight + contentHeight + Atoll.headerPadding)

    readonly property real bodyWidth: compactWidth + (openWidth - compactWidth) * p
    readonly property real bodyHeight: compactHeight + (openHeight - compactHeight) * p

    implicitWidth: bodyWidth
    implicitHeight: bodyHeight
    width: implicitWidth
    height: implicitHeight

    // In notch mode the shape insets its side walls by topRadius, so content is
    // inset to match; the pill fills edge-to-edge.
    // The menu-bar style is flush with the top edge, so its top corners stay
    // square while the bottom keeps the notch radii.
    readonly property real closedTopRadius: root.menuBar ? 0
        : (island ? Atoll.islandClosedRadius : Atoll.notchClosedTopRadius)
    readonly property real openTopRadius: root.menuBar ? 0
        : (island ? Atoll.islandOpenRadius : Atoll.notchOpenTopRadius)
    readonly property real closedBottomRadius: island ? Atoll.islandClosedRadius : Atoll.notchClosedBottomRadius
    readonly property real openBottomRadius: island ? Atoll.islandOpenRadius : Atoll.notchOpenBottomRadius

    // "Scale corner radius" (Appearance): when off the radius stays at the
    // closed value and does not grow with the expansion.
    readonly property real topRadius: Settings.cornerRadiusScaling
        ? closedTopRadius + (openTopRadius - closedTopRadius) * p : closedTopRadius
    readonly property real bottomRadius: Settings.cornerRadiusScaling
        ? closedBottomRadius + (openBottomRadius - closedBottomRadius) * p : closedBottomRadius

    readonly property real sideInset: island ? 0 : topRadius

    // "Hide non-notch until hover" (General > Displays): the floating pill is
    // fully hidden (shape and content) while idle, like an auto-hiding bar.
    readonly property bool restHidden: Settings.hideNonNotchUntilHover && island
        && !expanded && !notchHover.hovered

    // ---- Silhouette (solid black, per Atoll) ----
    NotchShape {
        id: notchShape
        anchors.fill: parent
        visible: !root.island
        fillColor: Colors.black
        topRadius: root.topRadius
        bottomRadius: root.bottomRadius
    }

    PillShape {
        id: pillShape
        anchors.fill: parent
        visible: root.island && !root.restHidden
        fillColor: Colors.black
        radius: root.topRadius
    }

    MultiEffect {
        source: notchShape
        anchors.fill: notchShape
        visible: !root.island && root.shadowsEnabled
        shadowEnabled: root.shadowsEnabled
        shadowColor: "#000000"
        shadowOpacity: 0.5
        shadowBlur: 0.9
        shadowVerticalOffset: 8
        blurMax: 48
    }

    MultiEffect {
        source: pillShape
        anchors.fill: pillShape
        visible: root.island && root.shadowsEnabled
        shadowEnabled: root.shadowsEnabled
        shadowColor: "#000000"
        shadowOpacity: 0.5
        shadowBlur: 0.9
        shadowVerticalOffset: 8
        blurMax: 48
    }

    // ---- Services ----
    MPRISService { id: mprisService }
    MediaDevices { id: mediaDevices }
    LyricsService {
        id: lyricsService
        trackTitle: mprisService.trackTitle
        trackArtist: mprisService.trackArtist
        position: mprisService.position
        duration: mprisService.length
        isPlaying: mprisService.isPlaying
        enabled: Settings.lyrics
    }
    SystemMonitorService {
        id: sysService
        // Developer > Stats: poll interval.
        intervalMs: Settings.statsInterval * 1000
    }
    NotificationService {
        id: notifService
        onNewNotification: {
            root.mode = "EXPANDED";
            root.activeTab = "CLIPBOARD";
        }
    }
    TimerService { id: timerService }
    CalendarService {
        id: calendar
        path: Settings.calendarPath
        hideAllDay: Settings.values.hideAllDayEvents === true
        hideCompleted: Settings.values.hideCompletedReminders === true
        limit: Settings.calendarUpcomingCount
    }
    DownloadsService {
        id: downloads
        dir: Settings.str("downloadsPath", "~/Downloads")
        maxItems: Math.max(1, Settings.num("shelfMaxItems", 12))
    }
    NotesService { id: notes }
    AudioService {
        id: audio
        onInternalVolumeChange: {
            if (Settings.enableSystemHUD && Settings.enableVolumeHUD)
                root.showHud("volume", audio.muted ? 0 : audio.volume);
        }
        onExternalVolumeChange: {
            // "Custom OSD" takes over the desktop's own on-screen display by
            // reacting to changes made anywhere, not just here.
            if (Settings.enableSystemHUD && Settings.enableVolumeHUD
                && Settings.enableCustomOSD)
                root.showHud("volume", audio.muted ? 0 : audio.volume);
        }
    }
    BrightnessService {
        id: brightness
        onInternalBrightnessChange: {
            if (Settings.enableSystemHUD && Settings.enableBrightnessHUD)
                root.showHud("brightness", brightness.brightness);
        }
        onExternalBrightnessChange: {
            if (Settings.enableSystemHUD && Settings.enableBrightnessHUD
                && Settings.enableCustomOSD)
                root.showHud("brightness", brightness.brightness);
        }
        onInternalKbdChange: {
            if (Settings.enableSystemHUD && Settings.enableKeyboardBacklightHUD)
                root.showHud("keyboard", brightness.kbdBrightness);
        }
        onExternalKbdChange: {
            if (Settings.enableSystemHUD && Settings.enableKeyboardBacklightHUD
                && Settings.enableCustomOSD)
                root.showHud("keyboard", brightness.kbdBrightness);
        }
    }
    CaffeinateService {
        id: caffeinate
        keepDisplayAwake: Settings.values.caffeinateKeepsDisplayAwake === true
        duration: Settings.values.caffeinateDefaultDuration === undefined
                  ? "indefinite" : String(Settings.values.caffeinateDefaultDuration)
    }

    // ---- HUD (Controls > System HUD) ----
    property string hudKind: "volume"
    property real hudValue: 0.0
    property bool hudActive: false
    property string hudColorText: ""
    property color hudColor: Colors.white

    function showHud(kind, value, seconds) {
        root.hudKind = kind;
        root.hudValue = value;
        root.hudActive = true;
        hudTimer.interval = (seconds !== undefined && seconds > 0 ? seconds * 1000 : 1600);
        hudTimer.restart();
    }

    Timer {
        id: hudTimer
        interval: 1600
        repeat: false
        onTriggered: root.hudActive = false
    }

    // Hover catcher. "Extend hover area" grows it from the pill's own silhouette
    // to a band across the top of the screen (the shell widens the input mask the
    // same way).
    Item {
        id: hoverZone
        anchors.horizontalCenter: root.horizontalCenter
        anchors.top: root.top
        width: Settings.extendHoverArea ? Math.max(root.width, 700) : root.width
        height: Settings.extendHoverArea ? Math.max(root.height, 56) : root.height

        HoverHandler {
            id: notchHover
            onHoveredChanged: {
                if (hovered) {
                    collapseTimer.stop();
                    if (!root.expanded && Settings.openOnHover) hoverOpenTimer.restart();
                } else {
                    hoverOpenTimer.stop();
                    collapseTimer.restart();
                }
            }
        }

        // Click/tap also opens, so the island is usable with "Open notch on
        // hover" off.
        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: {
                if (root.expanded && root.mode !== "COMPACT") root.mode = "COMPACT";
                else root.expandNow();
            }
        }

        // ---- Gestures (General > Behaviour) ----
        // Scroll: horizontal seeks/skips the track, vertical opens/closes.
        WheelHandler {
            enabled: Settings.values.enableGestures === true
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => {
                var dy = event.angleDelta.y;
                var dx = event.angleDelta.x;
                if (Math.abs(dx) > Math.abs(dy) && Settings.values.enableHorizontalMusicGestures === true) {
                    var dir = dx * (Settings.values.reverseSwipeGestures === true ? -1 : 1);
                    var step = Settings.num("gestureSensitivity", 200) / 20;
                    if (Settings.musicGestureBehavior === "seek") {
                        mprisService.seekBy(dir > 0 ? step : -step);
                    } else {
                        if (dir > 0) mprisService.next(); else mprisService.previous();
                    }
                } else {
                    var v = dy * (Settings.values.reverseScrollGestures === true ? -1 : 1);
                    if (v > 0) root.expandNow();
                    else if (Settings.values.closeGestureEnabled === true) root.mode = "COMPACT";
                }
                event.accepted = true;
            }
        }

        // Horizontal drag = swipe to skip (enableGestures + horizontal gestures).
        DragHandler {
            id: swipe
            enabled: Settings.values.enableGestures === true
            target: null
            xAxis.enabled: true
            yAxis.enabled: false
            onActiveChanged: {
                if (active) swipeStart = centroid.position.x;
            }
            property real swipeStart: 0
            onCentroidChanged: {
                if (!active) return;
                var dx = centroid.position.x - swipeStart;
                var threshold = Settings.num("gestureSensitivity", 200) / 2;
                if (Math.abs(dx) > threshold) {
                    var dir = dx * (Settings.values.reverseSwipeGestures === true ? -1 : 1);
                    if (Settings.values.enableHorizontalMusicGestures === true) {
                        if (Settings.musicGestureBehavior === "seek") {
                            mprisService.seekBy(dir > 0 ? 10 : -10);
                        } else {
                            if (dir > 0) mprisService.next(); else mprisService.previous();
                        }
                    }
                    swipeStart = centroid.position.x;
                }
            }
        }
    }

    // ---- Sneak peek (Media > "Enable sneak peek") ----
    // A track change briefly pulls the island open, then lets it go.
    Connections {
        target: mprisService
        function onTrackTitleChanged() {
            if (mprisService.trackTitle === "" || mprisService.trackTitle === "No Media Playing") return;
            if (!Settings.sneakPeek || !Settings.sneakPeekOnTrackChange) return;
            if (root.hudActive) return;
            root.sneakActive = true;
            root.mode = "EXPANDED";
            root.activeTab = "HOME";
            sneakTimer.restart();
        }
    }

    property bool sneakActive: false
    Timer {
        id: sneakTimer
        interval: Settings.sneakPeekStyle === "compact" ? 2200 : 3400
        onTriggered: {
            root.sneakActive = false;
            if (!notchHover.hovered) root.mode = "COMPACT";
        }
    }

    // ---- Battery HUD (System > Battery) ----
    property int _lastBattery: -1
    property bool _lastCharging: false
    onVisibleChanged: {} // no-op; keeps the binding engine quiet on teardown

    Connections {
        target: ColorPickerService
        function onFailed(reason) {
            root.hudColorText = reason;
            root.hudColor = Colors.textTertiary;
            root.showHud("color", 1, 4);
        }
        function onPicked(value) {
            root.hudColorText = value;
            root.hudColor = /^#?[0-9a-fA-F]{6}$/.test(value)
                            ? (value[0] === "#" ? value : "#" + value) : Colors.white;
            if (Settings.values.colorPickerDisplayMode === "panel") {
                root.showHud("color", 1, 4);
            } else {
                root.showHud("color", 1, 3);
            }
        }
    }

    Connections {
        target: sysService
        function onBatteryPercentChanged() {
            var level = sysService.batteryPercent;
            var wasUnknown = root._lastBattery < 0;
            var charging = sysService.isCharging;
            var changedToCharging = charging && !root._lastCharging;

            if (!wasUnknown && Settings.values.enableSystemHUD !== false
                && Settings.values.showPowerStatusNotifications !== false) {
                if (changedToCharging && Settings.values.showChargingBatteryHUD !== false) {
                    root.showHud("battery", level / 100, Settings.num("chargingBatteryHUDDuration", 2));
                } else if (level <= 20 && root._lastBattery > 20
                           && Settings.values.showLowBatteryHUD !== false) {
                    root.showHud("battery", level / 100, Settings.num("lowBatteryHUDDuration", 6));
                } else if (level >= 100 && root._lastBattery < 100
                           && Settings.values.showFullBatteryHUD !== false) {
                    root.showHud("battery", level / 100, Settings.num("fullBatteryHUDDuration", 4));
                }
            }
            root._lastBattery = level;
            root._lastCharging = charging;
        }
    }

    // "Minimum hover duration": the pointer must rest before the notch opens.
    Timer {
        id: hoverOpenTimer
        interval: Math.max(0, Settings.minHoverDuration * 1000)
        repeat: false
        onTriggered: {
            if (notchHover.hovered && !root.expanded) root.expandNow();
        }
    }

    // Default tab when the island opens (HOME for media, STATS when idle).
    function expandNow() {
        if (root.expanded) return;
        root.mode = "EXPANDED";
        if (Settings.openLastTab) {
            root.activeTab = Settings.str("lastTab", "HOME");
        } else if (notifService.hasActiveNotification) {
            root.activeTab = "CLIPBOARD";
        } else if (mprisService.hasMedia) {
            root.activeTab = "HOME";
        } else {
            root.activeTab = "STATS";
        }
    }

    Timer {
        id: collapseTimer
        // General > Behaviour "waitInterval": how long the island lingers after
        // the pointer leaves.
        interval: Math.max(0, Settings.waitInterval * 1000)
        repeat: false
        onTriggered: {
            if (!notchHover.hovered && root.mode !== "COMPACT" && !timerService.isRunning) {
                root.mode = "COMPACT";
            }
        }
    }

    // ---- Content ----
    Item {
        anchors.fill: parent
        anchors.leftMargin: root.sideInset
        anchors.rightMargin: root.sideInset
        clip: true

        // 1. Compact pill
        CompactPill {
            id: compactPill
            visible: opacity > 0
            opacity: root.restHidden || root.hudActive ? 0 : root.compactProgress
            scale: 0.88 + 0.12 * root.compactProgress
            transformOrigin: Item.Center
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -root.pinnedShownHeight / 2
            width: Math.min(implicitWidth, parent.width - 8)
            clockTime: ""
            isMediaPlaying: mprisService.isPlaying
            title: mprisService.hasMedia ? mprisService.trackTitle : ""
            artist: mprisService.hasMedia ? mprisService.trackArtist : ""
            tintColor: mprisService.brandColor
            artUrl: mprisService.persistentArtUrl !== "" ? mprisService.persistentArtUrl : mprisService.artUrl
            batteryLevel: sysService.batteryPercent
            isCharging: sysService.isCharging
            minimalistic: Settings.minimalisticUI
            showBattery: Settings.showBattery
            minimalBattery: Settings.values.showMinimalisticBatteryIndicator === true
            percentInside: Settings.values.showBatteryPercentInside === true
            visualizer: Settings.musicVisualizer
            barCount: Settings.visualizerBarCount
            reduceMotion: Settings.reduceMotionEnabled
            idleAlive: !mprisService.hasMedia && !root.hudActive && !Settings.reduceMotionEnabled
            timerActive: timerService.isRunning
                         && Settings.values.timerDisplayMode === "liveActivity"
            timerText: timerService.formattedTime
        }

        // 2. Pinned lyrics: the current line (and its neighbours) kept under
        // the closed pill while "Pin lyrics when closed" is on.
        PinnedLyrics {
            id: pinnedLyrics
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Atoll.pinnedLyricsGap
            width: parent.width
            visible: opacity > 0.01
            opacity: (root.pinnedEligible && lyricsService.availability === "timed")
                ? root.compactProgress : 0
            slots: root.pinnedSlotList
            sweepProgress: lyricsService.sweepProgress
            highlightStyle: Settings.lyricHighlightStyle
            tint: Settings.tintArtByPlayer ? mprisService.brandColor : Colors.textSecondary
        }

        // 3. System HUD (Controls > HUD): takes the pill's place while a value
        // change is being reported.
        HudWidget {
            id: hud
            anchors.centerIn: parent
            visible: opacity > 0.01
            opacity: root.hudActive ? 1 : 0
            scale: 0.94 + 0.06 * opacity
            Behavior on opacity { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }
            kind: root.hudKind
            value: root.hudValue
            muted: audio.muted
            charging: sysService.isCharging
            colorText: root.hudColorText
            tint: root.hudKind === "color" ? root.hudColor
                  : (root.hudKind === "battery"
                     ? (sysService.isCharging ? Colors.systemGreen
                        : (root.hudValue <= 0.2 ? Colors.systemRed : Colors.white))
                     : Colors.white)
            vertical: Settings.verticalHUD
            circular: Settings.circularHUD
        }

        // Output picker, raised by the media player's output button.
        OutputMenu {
            id: audioPopup
            parent: root
            sinks: audio.sinks
            current: audio.defaultSink
            onPicked: name => audio.setDefaultSink(name)
        }

        // 2. Expanded interface
        ColumnLayout {
            visible: opacity > 0
            opacity: root.contentProgress
            scale: 0.96 + 0.04 * root.contentProgress
            transformOrigin: Item.Top
            anchors.fill: parent
            spacing: 0

            NotchHeaderBar {
                id: headerBar
                presentation: root.presentation
                closedWidth: Atoll.closedWidth
                activeTab: root.activeTab
                batteryLevel: sysService.batteryPercent
                isCharging: sysService.isCharging
                showTimer: Settings.timerFeature
                showShelf: Settings.shelf
                // The merged Notes tab carries the clipboard in "separateTab" mode.
                showClipboardTab: Settings.clipboardSplit
                showClipboardDedicatedTab: root.hasDedicatedClipboardTab
                // Atoll hides the header clipboard icon in "separateTab" mode;
                // there the clipboard is part of the Notes tab.
                showClipboardAction: Settings.clipboardHasAction
                                     && Settings.values.showClipboardIcon !== false
                showStats: true
                showNotes: Settings.notesEnabled
                showDownloads: Settings.values.enableDownloadsWidget === true
                showTerminal: Settings.terminalEnabled
                showUsage: Settings.llmUsageEnabled
                reduceMotion: Settings.reduceMotionEnabled
                showColorPicker: Settings.colorPickerIcon
                showBattery: Settings.showBattery
                showSettings: Settings.settingsIcon
                accentColor: Settings.accent
                showCaffeinate: Settings.values.enableCaffeinate === true
                                && Settings.values.showCaffeinateIcon !== false
                caffeinateActive: caffeinate.active
                extrasOpen: root.extrasOpen
                onCaffeinateToggled: caffeinate.toggle()
                onExtrasToggled: root.extrasOpen = !root.extrasOpen
                Layout.topMargin: Atoll.headerPadding
                onTabSelected: tab => {
                    root.extrasOpen = false;
                    // Both popovers float over the tab content, so switching tabs
                    // (or dismissing the extras menu) puts them away.
                    root.colorPopoverOpen = false;
                    root.clipboardPopoverOpen = false;
                    root.activeTab = tab;
                }
                onActionTriggered: action => {
                    if (action === "clipboard") {
                        // Atoll routes the header clipboard button by
                        // clipboardDisplayMode. The button is hidden in
                        // "separateTab" mode (the clipboard lives in the Notes
                        // tab), so that branch is only a fallback here.
                        if (Settings.clipboardMode === "panel") {
                            root.clipboardPanelRequested();
                            root.mode = "COMPACT";
                        } else if (Settings.clipboardMode === "popover") {
                            root.mode = "EXPANDED";
                            root.clipboardPopoverOpen = !root.clipboardPopoverOpen;
                        } else if (root.hasDedicatedClipboardTab) {
                            // notchTab: a second tap on the button leaves the tab.
                            root.mode = "EXPANDED";
                            root.activeTab = root.activeTab === "CLIPBOARD" ? "HOME" : "CLIPBOARD";
                        } else {
                            root.mode = "EXPANDED";
                            root.activeTab = root.activeTab === "NOTES" ? "HOME" : "NOTES";
                        }
                    } else if (action === "colorpicker") {
                        if (Settings.values.enableColorPickerFeature === false) return;
                        // Atoll: DynamicIslandHeader switches on colorPickerDisplayMode
                        // - .panel shows the floating panel, .popover the attached one.
                        if (Settings.values.colorPickerDisplayMode === "popover") {
                            root.colorPopoverOpen = !root.colorPopoverOpen;
                        } else {
                            root.colorPickerPanelRequested();
                            root.mode = "COMPACT";
                        }
                    } else if (action === "settings") {
                        root.settingsRequested();
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Atoll.headerPadding
                // Atoll blurs the view content while the notch is closed
                // (NotchHomeView: .blur(radius: closed ? 30 : 0)), which is what
                // makes the open/close read as a blur-replace rather than a fade.
                layer.enabled: root.p < 0.999 && root.p > 0.001 && !Settings.reduceMotionEnabled
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 30 * (1 - root.p)
                    blurMax: 40
                }

                // ---- Home: media player beside the calendar ----
                // NotchHomeView.mainContent = HStack(alignment: .top) { MusicPlayerView;
                // CalendarView }. The player carries the wider share (the
                // reference notch renders roughly 58:42), and either pane takes
                // the whole tab when the other is hidden.
                Item {
                    id: homeRow
                    anchors.fill: parent
                    visible: root.activeTab === "HOME"

                    readonly property real gap: 12
                    // Media > "Auto-hide inactive notch media player".
                    readonly property bool mediaVisible: !Settings.autoHideInactiveMedia || mprisService.hasMedia
                    readonly property bool sideLyrics: root.sideLyricsActive
                    // The side panel and the calendar never share the row.
                    readonly property bool calendarVisible: Settings.showCalendar && !homeRow.sideLyrics
                    readonly property bool mirror: Settings.showMirror && root.cameraAvailable && root.expanded

                    // Column geometry, laid out left to right (MusicPlayerView,
                    // optional side lyrics, optional calendar, optional mirror).
                    readonly property var cols: homeRow.computeColumns()

                    function computeColumns() {
                        var g = homeRow.gap;
                        var media = homeRow.mediaVisible;
                        var cal = homeRow.calendarVisible;
                        var side = homeRow.sideLyrics;
                        var mir = homeRow.mirror;
                        var out = {
                            player: { x: 0, w: 0 },
                            calendar: { x: 0, w: 0 },
                            panel: { x: 0, w: 0 },
                            mirror: { x: 0, w: 0 }
                        };
                        var n = (media ? 1 : 0) + (cal ? 1 : 0) + (side ? 1 : 0) + (mir ? 1 : 0);
                        var avail = Math.max(0, homeRow.width - Math.max(0, n - 1) * g);

                        if (side) {
                            var panel = Math.max(0, Settings.lyricsPanelWidth);
                            var off = Settings.lyricsPanelOffset;
                            var leftover = Math.max(0, avail - panel - Math.abs(off));
                            var pw = 0;
                            var mw = 0;
                            if (mir) {
                                pw = Math.max(Atoll.sideLyricsMinPlayerWidth, Math.round(leftover / 2));
                                mw = Math.max(0, leftover - pw);
                            } else {
                                pw = Math.max(Atoll.sideLyricsMinPlayerWidth, leftover);
                            }
                            out.player = { x: 0, w: media ? pw : 0 };
                            var panelX = (media ? pw + g : 0) + off;
                            out.panel = { x: panelX, w: panel };
                            out.mirror = { x: panelX + panel + g, w: mir ? mw : 0 };
                            return out;
                        }

                        if (mir) {
                            var mw2 = Math.max(Atoll.sideLyricsMinMirrorWidth, Math.round(avail * 0.22));
                            var rest = Math.max(0, avail - mw2);
                            if (cal && media) {
                                out.player.w = Math.round(rest * 0.58);
                                out.calendar.w = rest - out.player.w;
                            } else if (cal) {
                                out.calendar.w = rest;
                            } else {
                                out.player.w = media ? rest : 0;
                            }
                            out.calendar.x = out.player.w > 0 ? out.player.w + g : 0;
                            out.mirror.x = (out.player.w + out.calendar.w)
                                + ((out.player.w > 0 || out.calendar.w > 0) ? g : 0);
                            out.mirror.w = mw2;
                            return out;
                        }

                        if (cal && media) {
                            out.player.w = Math.round(avail * 0.58);
                            out.calendar.w = avail - out.player.w;
                            out.calendar.x = out.player.w + g;
                        } else if (cal) {
                            out.calendar.w = avail;
                        } else if (media) {
                            out.player.w = avail;
                        }
                        return out;
                    }

                    Item {
                        id: homeMediaHost
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        x: homeRow.cols.player.x
                        width: homeRow.cols.player.w
                        visible: homeRow.mediaVisible && width > 0

                        MediaWidget {
                            trackTitle: mprisService.trackTitle
                            trackArtist: mprisService.trackArtist
                            artUrl: mprisService.persistentArtUrl !== "" ? mprisService.persistentArtUrl : mprisService.artUrl
                            isPlaying: mprisService.isPlaying
                            hasMedia: mprisService.hasMedia
                            progress: mprisService.progress
                            positionSeconds: mprisService.position
                            lengthSeconds: mprisService.length
                            shuffleActive: mprisService.shuffleActive
                            loopActive: mprisService.looping
                            loopOne: mprisService.loopingOne
                            appIconSource: mprisService.appIconSource
                            brandColor: mprisService.brandColor
                            tintArtist: Settings.tintArtByPlayer
                            lighting: Settings.lighting
                            parallax: Settings.reduceMotionEnabled ? 0 : Settings.parallax
                            reduceMotion: Settings.reduceMotionEnabled
                            showShuffleRepeat: Settings.shuffleAndRepeat
                            showOutputControl: Settings.mediaOutputControl
                            slots: Settings.slots
                            showStandardControls: Settings.standardMediaControls
                            skipBehavior: Settings.musicSkipBehavior
                            waveformScrubber: Settings.waveformScrubber
                            showInlineLyric: Settings.lyrics && homeRow.calendarVisible
                            inlineLyric: lyricsService.currentLine
                            inlineInstrumental: lyricsService.isInstrumentalBreak
                            sliderColor: Settings.sliderColor === "player" ? mprisService.brandColor
                                       : Settings.sliderColor === "accent" ? Settings.accent
                                       : "#ffffff"
                            onPlayPauseClicked: mprisService.playPause()
                            onNextClicked: mprisService.next()
                            onPrevClicked: mprisService.previous()
                            onShuffleClicked: mprisService.toggleShuffle()
                            onRepeatClicked: mprisService.cycleLoop()
                            onArtClicked: mprisService.focusActivePlayer()
                            onSeekRequested: fraction => mprisService.seek(fraction)
                            onSeekBackClicked: mprisService.seekBy(-10)
                            onSeekForwardClicked: mprisService.seekBy(10)
                            onOutputClicked: audioPopup.opened ? audioPopup.close() : audioPopup.open()
                        }
                    }

                    Item {
                        id: homeCalendarHost
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        x: homeRow.cols.calendar.x
                        width: homeRow.cols.calendar.w
                        visible: homeRow.calendarVisible && width > 0

                        CalendarWidget {
                            events: calendar.upcoming
                        }
                    }

                    Item {
                        id: homeLyricsHost
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        x: homeRow.cols.panel.x
                        width: homeRow.cols.panel.w
                        visible: homeRow.sideLyrics && width > 0

                        LyricsPanel {
                            anchors.fill: parent
                            lines: lyricsService.lines
                            duration: lyricsService.duration
                            availability: lyricsService.availability
                            currentIndex: lyricsService.currentIndex
                            sweepProgress: lyricsService.sweepProgress
                            placeholder: lyricsService.placeholder
                            highlightStyle: Settings.lyricHighlightStyle
                            tint: Settings.tintArtByPlayer ? mprisService.brandColor : Colors.textSecondary
                            pinned: Settings.pinLyricsWhenClosed
                            onPinToggled: Settings.toggle("pinLyricsWhenClosed")
                        }
                    }

                    Item {
                        id: homeMirrorHost
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        x: homeRow.cols.mirror.x
                        width: homeRow.cols.mirror.w
                        visible: homeRow.mirror && width > 0

                        CameraMirror {
                            anchors.fill: parent
                            device: mediaDevices.videoInputs.length > 0
                                ? mediaDevices.videoInputs[0] : null
                            shape: Settings.values.mirrorShape
                            active: homeRow.mirror
                            cornerRadiusScaling: Settings.cornerRadiusScaling
                        }
                    }
                }

                SystemWidget {
                    visible: root.activeTab === "STATS"
                    cpuUsage: sysService.cpuUsage
                    ramUsage: sysService.ramUsage
                    ramUsedMb: sysService.ramUsedMb
                    ramTotalMb: sysService.ramTotalMb
                    batteryPercent: sysService.batteryPercent
                    isCharging: sysService.isCharging
                    gpuUsage: sysService.gpuUsage
                    hasGpu: sysService.hasGpu
                    netDown: sysService.netDown
                    netUp: sysService.netUp
                    diskRead: sysService.diskRead
                    diskWrite: sysService.diskWrite
                    cpuHistory: sysService.cpuHistory
                    memHistory: sysService.memHistory
                    gpuHistory: sysService.gpuHistory
                    netDownHistory: sysService.netDownHistory
                    netUpHistory: sysService.netUpHistory
                    diskReadHistory: sysService.diskReadHistory
                    diskWriteHistory: sysService.diskWriteHistory
                    showCPU: Settings.statsShowCPU
                    showMemory: Settings.statsShowMemory
                    showGPU: Settings.statsShowGPU
                    showNetwork: Settings.statsShowNetwork
                    showDisk: Settings.statsShowDisk
                }

                // ---- Usage tab (Atoll's NotchLLMUsageView) ----
                // Atoll refreshes on the view's .onAppear; a tab switch is the
                // same moment here. The service debounces to one scan a minute.
                LLMUsageView {
                    anchors.fill: parent
                    visible: root.activeTab === "USAGE"
                    service: LLMUsageService
                    providers: Settings.llmProviders.filter(
                        p => Settings.llmProviderEnabled(p.id))
                    featureEnabled: Settings.llmUsageEnabled
                    onVisibleChanged: if (visible) LLMUsageService.refreshAll(
                        Settings.llmEnabledProviders, false)
                }

                TimerWidget {
                    visible: root.activeTab === "TIMER"
                    formattedTime: timerService.formattedTime
                    isRunning: timerService.isRunning
                    presets: Settings.values.timerPresets || []
                    displayMode: Settings.str("timerDisplayMode", "tab")
                    onStartTimer: seconds => timerService.startTimer(seconds)
                    onStartStopwatch: timerService.startStopwatch()
                    onTogglePause: timerService.togglePause()
                    onResetTimer: timerService.reset()
                }

                TerminalView {
                    anchors.fill: parent
                    visible: root.activeTab === "TERMINAL"
                    service: TerminalService
                    featureEnabled: Settings.terminalEnabled
                    shellName: Settings.terminalShell
                    emulator: TerminalService.emulator
                    quickCommands: Settings.terminalCommands
                }

                DownloadsView {
                    visible: root.activeTab === "DOWNLOADS"
                    entries: downloads.entries
                    onOpenRequested: path => downloads.open(path)
                    onOpenFolder: root.exec("xdg-open " + downloads.dir)
                }

                // ---- Merged Notes tab (Atoll's NotchNotesView) ----
                // In "Separate tab" mode the clipboard is listed beside the notes,
                // split by a divider; in "notchTab" mode it gets its own tab.
                NotesClipboardView {
                    id: notesClipboard
                    anchors.fill: parent
                    visible: root.activeTab === "NOTES"
                    clipboardVisible: Settings.clipboardSplit && root.activeTab !== "CLIPBOARD"
                    notesVisible: Settings.notesEnabled
                    entries: ClipboardService.entries
                    notes: notes.notes
                    imageDir: notes.imageDir
                    notePinning: Settings.notePinning
                    noteSearch: Settings.noteSearch
                    noteColorFiltering: Settings.noteColorFiltering
                    noteFromClipboard: Settings.noteFromClipboard
                    noteCharCount: Settings.noteCharCount
                    hasNotification: notifService.hasActiveNotification
                    appName: notifService.appName
                    summary: notifService.summary
                    body: notifService.body
                    appIcon: notifService.appIcon
                    onPickRequested: id => {
                        ClipboardService.pick(id);
                        root.mode = "COMPACT";
                    }
                    onRemoveRequested: id => ClipboardService.remove(id)
                    onClearRequested: ClipboardService.clear()
                    onDismissClicked: {
                        notifService.dismiss();
                        root.mode = "COMPACT";
                    }
                    onNoteAdded: (title, body, colorIndex, image) => notes.add(title, body, colorIndex, image)
                    onNoteUpdated: (id, title, body, colorIndex, image) => notes.update(id, title, body, colorIndex, image)
                    onNoteRemoved: id => notes.remove(id)
                    onNotePinned: id => notes.togglePin(id)
                    onAllCleared: notes.clearAll()
                    onNoteCopyRequested: text => root.copyToClipboard(text)
                    onNotePasteRequested: intoEditor => root.readClipboardForNotes(intoEditor)
                    onNoteImageDiscarded: path => notes.removeFile(path)
                }

                // Dedicated clipboard tab (clipboardDisplayMode == "notchTab").
                Item {
                    anchors.fill: parent
                    visible: root.activeTab === "CLIPBOARD"

                    ClipboardView {
                        anchors.fill: parent
                        columns: 2
                        entries: ClipboardService.entries
                        hasNotification: notifService.hasActiveNotification
                        appName: notifService.appName
                        summary: notifService.summary
                        body: notifService.body
                        appIcon: notifService.appIcon
                        onPickRequested: id => {
                            ClipboardService.pick(id);
                            root.mode = "COMPACT";
                        }
                        onRemoveRequested: id => ClipboardService.remove(id)
                        onClearRequested: ClipboardService.clear()
                        onDismissClicked: {
                            notifService.dismiss();
                            root.mode = "COMPACT";
                        }
                    }
                }
                QuickActionLauncher {
                    visible: root.activeTab === "SHELF"
                    showLabels: Settings.values.tileShowLabels === true
                    showEmoji: Settings.values.showEmojis === true
                    onLaunchColorPicker: {
                        if (Settings.values.enableColorPickerFeature !== false) ColorPickerService.pick();
                        root.mode = "COMPACT";
                    }
                    onLaunchScreenshot: {
                        root.exec("hyprshot -m region || grim -g \"$(slurp)\" - | wl-copy || spectacle -r -b -n -o /tmp/atoll_shot.png || gnome-screenshot -a")
                        root.mode = "COMPACT"
                    }
                    onLaunchTerminal: {
                        TerminalService.launch();
                        root.mode = "COMPACT";
                    }
                    onLaunchEmoji: {
                        root.exec("command -v wtype >/dev/null && wtype \"\ud83d\ude00\" || wl-copy <<< \"\ud83d\ude00\"");
                        root.mode = "COMPACT";
                    }
                }

                // ---- Extras menu (header "…") ----
                // Dims the tab content behind a row of large tiles, like Atoll's
                // DynamicIslandExtrasMenu.
                Rectangle {
                    anchors.fill: parent
                    visible: root.extrasOpen
                    radius: Metrics.r12
                    color: Qt.rgba(0, 0, 0, 0.55)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.extrasOpen = false
                    }

                    ExtrasMenu {
                        anchors.centerIn: parent
                        onHideRequested: {
                            root.extrasOpen = false;
                            root.mode = "COMPACT";
                        }
                        onSettingsRequested: {
                            root.extrasOpen = false;
                            root.settingsRequested();
                        }
                        onExitRequested: {
                            root.extrasOpen = false;
                            root.exec("\"" + Quickshell.shellDir.toString().replace(/^file:\/\//, "")
                                      + "/bin/atoll\" stop");
                        }
                    }
                }

                // ---- Colour popover (header eyedropper, "Popover" mode) ----
                // Atoll attaches a SwiftUI .popover to the eyedropper button; here
                // it hangs under the header's trailing action row.
                ColorPickerPopover {
                    id: colorPopover
                    service: ColorPickerService
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.rightMargin: 34
                    visible: root.colorPopoverOpen
                    onPickRequested: {
                        root.colorPopoverOpen = false;
                        ColorPickerService.pick();
                    }
                    onShowHistoryRequested: {
                        root.colorPopoverOpen = false;
                        root.colorPickerPanelRequested();
                    }
                    onCloseRequested: root.colorPopoverOpen = false
                }

                // ---- Clipboard popover (header clipboard, "Popover" mode) ----
                // Atoll attaches a SwiftUI .popover to the clipboard button; here
                // the card is docked under the header's trailing action row.
                ClipboardPopover {
                    id: clipboardPopover
                    service: ClipboardService
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.rightMargin: 34
                    visible: root.clipboardPopoverOpen
                    onCloseRequested: root.clipboardPopoverOpen = false
                }
            }
        }
    }

    property Process toolProcess: Process {}

    function exec(cmd) {
        toolProcess.command = ["bash", "-c", cmd];
        toolProcess.running = true;
    }

    // ---- Notes: clipboard copy/paste ----
    // NotesView keeps out of Quickshell.Io so the dev harness can load it, so
    // the two clipboard operations live here.
    function copyToClipboard(text) {
        var value = String(text || "");
        if (value === "") return;
        noteCopyProc.pending = value;
        noteCopyProc.running = true;
    }

    property Process noteCopyProc: Process {
        property string pending: ""
        command: ["wl-copy", noteCopyProc.pending]
    }

    // Read the clipboard for the notes pane: an image type wins (written under
    // NotesService's image dir, path reported back), otherwise text.
    function readClipboardForNotes(intoEditor) {
        notePasteProc.intoEditor = intoEditor;
        notePasteProc.running = true;
    }

    property Process notePasteProc: Process {
        property bool intoEditor: false
        command: ["bash", "-c",
            "t=$(wl-paste --list-types 2>/dev/null | grep -Eo 'image/(png|jpeg|gif|webp)' | head -1); " +
            "if [ -n \"$t\" ]; then " +
            "ext=${t#image/}; [ \"$ext\" = jpeg ] && ext=jpg; " +
            "mkdir -p '" + notes.imageDir + "'; " +
            "f='" + notes.imageDir + "/note_'$(date +%s%N)'.'\"$ext\"; " +
            "wl-paste --type \"$t\" > \"$f\" 2>/dev/null && printf 'IMG:%s' \"$f\"; " +
            "elif wl-paste --list-types 2>/dev/null | grep -qi text; then " +
            "wl-paste --no-newline 2>/dev/null | head -c 4096; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = this.text;
                var imagePath = "";
                var text = out;
                if (out.indexOf("IMG:") === 0) {
                    imagePath = out.substring(4).trim();
                    text = "";
                    if (imagePath === "") return;
                }
                notesClipboard.applyClipboard(text, imagePath, notePasteProc.intoEditor);
            }
        }
    }
}
