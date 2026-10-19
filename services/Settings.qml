pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Persisted settings store for Atoll for Linux.
//
// Mirrors Atoll's Defaults keys (DynamicIsland/models/Constants.swift) so the
// Settings window can expose the same controls. Stored as JSON at
// $XDG_CONFIG_HOME/atoll/settings.json (falls back to ~/.config/atoll).
//
// `values` is reassigned on every write so bindings such as `Settings.values.foo`
// re-evaluate; named read-only aliases below give the island clean bindings.
QtObject {
    id: root

    readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/atoll"
    readonly property string path: configDir + "/settings.json"

    signal changed(string key)
    readonly property bool ready: file.loaded

    property var values: root.defaults()

    function defaults() {
        return {
            // ---- General ----
            enableMinimalisticUI: false,
            showMinimalisticBatteryIndicator: false,
            showBatteryPercentInside: true,
            showBatteryIndicator: true,
            menubarIcon: true,
            launchAtLogin: false,
            reduceMotion: "system",
            showOnAllDisplays: false,
            automaticallySwitchDisplay: true,
            hideDynamicIslandFromScreenCapture: false,
            preferredScreen: "",
            settingsIconInNotch: true,
            enableCaffeinate: false,
            showCaffeinateIcon: true,
            caffeinateDefaultDuration: "indefinite",
            caffeinateKeepsDisplayAwake: false,
            extendHoverArea: false,
            enableHaptics: true,
            openNotchOnHover: true,
            minimumHoverDuration: 0.3,
            openLastTabByDefault: false,
            externalDisplayStyle: "notch",
            hideNonNotchUntilHover: false,
            enableGestures: true,
            closeGestureEnabled: true,
            gestureSensitivity: 200,
            enableHorizontalMusicGestures: true,
            musicGestureBehavior: "track",
            reverseSwipeGestures: false,
            reverseScrollGestures: false,
            notchHeightMode: "matchRealNotchSize",
            notchHeight: 32,
            nonNotchHeightMode: "matchMenuBar",
            nonNotchHeight: 32,
            openNotchWidth: 640,
            closedNotchWidth: 150,
            customizePhysicalNotchWidth: false,

            // ---- Appearance ----
            accentColor: "#0a84ff",
            enableShadow: true,
            cornerRadiusScaling: true,
            useModernCloseAnimation: true,
            lightingEffect: true,
            playerColorTinting: true,
            sliderColor: "white",
            useMusicVisualizer: true,
            visualizerBarCount: 4,
            enableWaveformScrubber: true,
            colorExtractionMode: "vibrant",
            showShuffleAndRepeat: true,
            showMediaOutputControl: true,
            musicControlSlots: ["shuffle", "trackBackward", "playPause", "trackForward", "repeatMode"],
            showEmojis: false,
            showMirror: false,
            mirrorShape: "rectangle",
            tileShowLabels: false,

            // ---- Media ----
            enableLyrics: false,
            pinLyricsWhenClosed: false,
            musicSource: "auto",
            musicSkipBehavior: "track",
            showStandardMediaControls: true,
            autoHideInactiveNotchMediaPlayer: true,
            enableSneakPeek: false,
            sneakPeekStyles: "standard",
            showSneakPeekOnTrackChange: true,
            enableFullscreenMediaDetection: true,
            parallaxEffectIntensity: 6.0,
            waitInterval: 3,

            // ---- Live Activities ----
            enableHUD: true,
            showCalendar: true,
            hideCompletedReminders: true,
            hideAllDayEvents: false,
            calendarPath: "~/.local/share/atoll/calendar.ics",

            // ---- Lock Screen ----
            enableLockScreenMediaWidget: true,
            enableLockScreenWeatherWidget: true,
            enableLockScreenFocusWidget: true,
            enableLockScreenReminderWidget: true,
            enableLockScreenTimerWidget: true,
            lockScreenWeatherShowsLocation: true,
            lockScreenWeatherShowsSunrise: true,
            lockScreenWeatherShowsAQI: true,
            lockScreenWeatherTemperatureUnit: "matchingSystem",
            lockScreenWidgetAppearance: "dark",
            lockScreenGlassStyle: "liquid",
            lockScreenShowAppIcon: false,
            lockScreenPanelShowsBorder: false,
            lockScreenPanelUsesBlur: true,

            // ---- System: Controls (HUD & OSD) ----
            enableSystemHUD: true,
            enableVolumeHUD: true,
            enableBrightnessHUD: true,
            enableKeyboardBacklightHUD: true,
            enableCustomOSD: true,
            enableVerticalHUD: false,
            enableCircularHUD: false,

            // ---- System: Battery ----
            showPowerStatusNotifications: true,
            showChargingBatteryHUD: true,
            showLowBatteryHUD: true,
            showFullBatteryHUD: true,
            chargingBatteryHUDDuration: 2,
            lowBatteryHUDDuration: 6,
            fullBatteryHUDDuration: 4,

            // ---- Productivity: Timer / Calendar / Notes ----
            enableTimerFeature: true,
            timerDisplayMode: "tab",
            timerPresets: [
                { name: "Focus", duration: 1500, color: "#ff9f0a" },
                { name: "Break", duration: 300, color: "#30d158" },
                { name: "Deep Work", duration: 2700, color: "#bf5af2" }
            ],
            enableNotes: false,
            enableNotePinning: true,
            enableNoteSearch: false,
            enableNoteColorFiltering: false,
            enableCreateFromClipboard: true,
            enableNoteCharCount: true,

            // ---- Utilities ----
            enableClipboardManager: true,
            showClipboardIcon: true,
            // Atoll's default display mode is the floating panel.
            clipboardDisplayMode: "panel",
            clipboardHistorySize: 3,
            persistClipboardHistory: true,
            enableColorPickerFeature: true,
            colorPickerDisplayMode: "panel",
            colorPickerFormat: "hex",
            colorHistorySize: 10,
            showColorFormats: true,
            showColorPickerIcon: true,
            enableShelf: true,
            shelfMaxItems: 12,
            enableDownloadsWidget: false,
            downloadsPath: "~/Downloads",

            // ---- Developer ----
            statsInterval: 1.0,
            statsShowCPU: true,
            statsShowMemory: true,
            statsShowGPU: true,
            statsShowNetwork: true,
            statsShowDisk: true,
            terminalShell: "bash",
            // Developer > Terminal. Atoll defaults this off.
            enableTerminalFeature: false,
            terminalEmulator: "auto",
            terminalQuickCommands: "htop, ls -la ~, df -h, sensors",
            // Stats > LLM Usage Monitor (Constants.swift). Off by default; adds
            // the "Usage" tab.
            enableLLMUsageFeature: false,
            enableClaudeProvider: true,
            enableCodexProvider: true,
            enableCursorProvider: true,
            enableAntigravityProvider: true,
            enableNewAPIProvider: false,

            // ---- Integrations ----
            enableExtensions: false,

            // ---- State ----
            lastTab: "HOME"
        };
    }

    function get(key) { return values[key]; }
    function has(key) { return values[key] !== undefined; }

    // Coercing readers. Each reads `values`, so any component binding that calls
    // one of these re-evaluates when the store is reassigned by `set()`.
    function num(key, fallback) {
        var v = Number(values[key]);
        return isFinite(v) ? v : fallback;
    }
    function str(key, fallback) {
        var v = values[key];
        return (typeof v === "string" && v.length > 0) ? v : fallback;
    }
    function any(key, fallback) {
        var v = values[key];
        return v === undefined || v === null ? fallback : v;
    }

    function set(key, value) {
        if (values[key] === value) return;
        var next = {};
        for (var k in values) next[k] = values[k];
        next[key] = value;
        values = next;
        changed(key);
        saveTimer.restart();
    }

    function toggle(key) { set(key, !values[key]); }

    function reset() {
        values = defaults();
        changed("*");
        saveTimer.restart();
    }

    function save() {
        file.setText(JSON.stringify(values, null, 2) + "\n");
    }

    // Accepts "#rrggbb" or a serialized QColor object ({r,g,b,a}) and returns a
    // hex string, so an older settings.json that stored a colour object still
    // loads (and is repaired to a string on the next save).
    function coerceColor(v) {
        if (typeof v === "string" && v.length > 0) return v;
        if (v && typeof v === "object" && v.r !== undefined) {
            function chan(x) {
                var n = Math.round(Math.max(0, Math.min(1, Number(x))) * 255);
                var s = n.toString(16);
                return s.length < 2 ? "0" + s : s;
            }
            return "#" + chan(v.r) + chan(v.g) + chan(v.b);
        }
        return "#0a84ff";
    }

    // Convenience bindings for the island.
    readonly property bool minimalisticUI: values.enableMinimalisticUI === true
    readonly property bool showBattery: values.showBatteryIndicator === true
    readonly property bool batteryPercentInside: values.showBatteryPercentInside === true
    readonly property bool showShadow: values.enableShadow === true
    readonly property bool lighting: values.lightingEffect === true
    readonly property bool tintArtByPlayer: values.playerColorTinting === true
    readonly property bool showCalendar: values.showCalendar === true
    readonly property string calendarPath: root.str("calendarPath", "~/.local/share/atoll/calendar.ics")
    readonly property int calendarUpcomingCount: root.num("calendarUpcomingCount", 5)
    readonly property bool timerFeature: values.enableTimerFeature === true
    readonly property bool clipboardEnabled: values.enableClipboardManager === true
    // Clipboard placement (Utilities > Clipboard > "Display mode"), matching
    // Atoll's ClipboardDisplayMode:
    //   .popover      - dropdown attached to the header clipboard button
    //   .panel        - floating 380x480 panel window
    //   .separateTab  - merged into the Notes tab as a second pane
    //   .notchTab     - dedicated tab inside the notch
    // The legacy "tab" value falls back to the dedicated tab so an older
    // settings.json keeps working.
    readonly property string clipboardMode: {
        var raw = root.str("clipboardDisplayMode", "panel");
        if (raw === "popover" || raw === "panel" || raw === "notchTab") return raw;
        if (raw === "tab") return "notchTab";
        return "separateTab";
    }
    readonly property bool clipboardSplit: clipboardEnabled && clipboardMode === "separateTab"
    // True when the header shows a clipboard button of its own (every mode but
    // the merged Notes tab - Atoll does the same in DynamicIslandHeader).
    readonly property bool clipboardHasAction: clipboardEnabled && clipboardMode !== "separateTab"
    // Atoll's persistClipboardHistory: off keeps the history for the session
    // only. cliphist always writes its store, so "off" means the store is wiped
    // when the shell starts (nothing survives a restart).
    readonly property bool persistClipboard: values.persistClipboardHistory !== false
    readonly property bool notesEnabled: values.enableNotes === true
    // Notes sub-features (Atoll's enableNotePinning / Search / ColorFiltering /
    // CreateFromClipboard / NoteCharCount). They only matter with notes on.
    readonly property bool notePinning: notesEnabled && values.enableNotePinning !== false
    readonly property bool noteSearch: notesEnabled && values.enableNoteSearch === true
    readonly property bool noteColorFiltering: notesEnabled && values.enableNoteColorFiltering === true
    readonly property bool noteFromClipboard: notesEnabled && values.enableCreateFromClipboard !== false
    readonly property bool noteCharCount: notesEnabled && values.enableNoteCharCount !== false
    readonly property bool colorPickerEnabled: values.enableColorPickerFeature === true
    readonly property bool colorPickerIcon: colorPickerEnabled && values.showColorPickerIcon !== false
    readonly property bool colorFormats: values.showColorFormats !== false
    readonly property bool settingsIcon: values.settingsIconInNotch === true
    readonly property bool showMirror: values.showMirror === true
    readonly property bool lyrics: values.enableLyrics === true
    readonly property bool shelf: values.enableShelf === true
    readonly property string accent: root.coerceColor(values.accentColor)
    readonly property var slots: values.musicControlSlots || []

    // ---- Live geometry (General + Appearance > "Notch size") ----
    readonly property string displayStyle: root.str("externalDisplayStyle", "notch")
    readonly property bool hideNonNotchUntilHover: values.hideNonNotchUntilHover === true
    readonly property bool openOnHover: values.openNotchOnHover !== false
    readonly property real minHoverDuration: root.num("minimumHoverDuration", 0.3)
    readonly property real waitInterval: root.num("waitInterval", 3)
    readonly property bool openLastTab: values.openLastTabByDefault === true
    readonly property bool cornerRadiusScaling: values.cornerRadiusScaling !== false
    readonly property bool modernClose: values.useModernCloseAnimation !== false

    // ---- Reduce motion (Appearance > Reduce motion) ----
    // "system" follows the desktop preference (KDE AnimationDurationFactor /
    // GNOME enable-animations); "on"/"off" force it. When on, the island stops
    // moving spatially and dissolves instead (HIG: replace movement, keep fade).
    property bool systemReducedMotion: false
    readonly property bool reduceMotionEnabled: root.str("reduceMotion", "system") === "on"
        ? true
        : (root.str("reduceMotion", "system") === "off" ? false : root.systemReducedMotion)

    property Process reduceMotionProbe: Process {
        command: ["bash", "-c",
            "f=\$(kreadconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 2>/dev/null); " +
            "if [ -n \"\$f\" ]; then [ \"\$f\" = \"0\" ] && echo reduce || echo animate; " +
            "else a=\$(gsettings get org.gnome.desktop.interface enable-animations 2>/dev/null); " +
            "[ \"\$a\" = \"false\" ] && echo reduce || echo animate; fi"]
        stdout: SplitParser {
            onRead: line => {
                if (line.trim() === "reduce") root.systemReducedMotion = true;
                else if (line.trim() === "animate") root.systemReducedMotion = false;
            }
        }
        Component.onCompleted: running = true
    }
    readonly property bool extendHoverArea: values.extendHoverArea === true
    readonly property bool showOnAllDisplays: values.showOnAllDisplays === true
    readonly property bool autoSwitchDisplay: values.automaticallySwitchDisplay !== false
    readonly property string preferredScreen: root.str("preferredScreen", "")
    readonly property bool customizePhysicalNotchWidth: values.customizePhysicalNotchWidth === true
    readonly property real closedWidth: root.num("closedNotchWidth", 150)
    readonly property real openWidth: root.num("openNotchWidth", 640)
    readonly property string notchHeightMode: root.str("notchHeightMode", "matchRealNotchSize")
    readonly property real notchHeight: root.num("notchHeight", 32)
    readonly property string nonNotchHeightMode: root.str("nonNotchHeightMode", "matchMenuBar")
    readonly property real nonNotchHeight: root.num("nonNotchHeight", 32)

    // ---- Live media/appearance ----
    readonly property string sliderColor: root.str("sliderColor", "white")
    readonly property string colorExtractionMode: root.str("colorExtractionMode", "vibrant")
    readonly property bool musicVisualizer: values.useMusicVisualizer !== false
    readonly property int visualizerBarCount: Math.max(2, Math.min(8, root.num("visualizerBarCount", 4)))
    readonly property bool waveformScrubber: values.enableWaveformScrubber !== false
    readonly property bool shuffleAndRepeat: values.showShuffleAndRepeat !== false
    readonly property bool mediaOutputControl: values.showMediaOutputControl !== false
    readonly property bool standardMediaControls: values.showStandardMediaControls !== false
    readonly property bool autoHideInactiveMedia: values.autoHideInactiveNotchMediaPlayer !== false
    readonly property string musicSkipBehavior: root.str("musicSkipBehavior", "track")
    readonly property string musicSource: root.str("musicSource", "auto")
    readonly property real parallax: root.num("parallaxEffectIntensity", 6.0)
    readonly property bool sneakPeek: values.enableSneakPeek === true
    readonly property string sneakPeekStyle: root.str("sneakPeekStyles", "standard")
    readonly property bool sneakPeekOnTrackChange: values.showSneakPeekOnTrackChange !== false

    // ---- Live HUD / OSD (Controls) ----
    readonly property bool enableSystemHUD: values.enableSystemHUD !== false && values.enableHUD !== false
    readonly property bool enableVolumeHUD: values.enableVolumeHUD !== false
    readonly property bool enableBrightnessHUD: values.enableBrightnessHUD !== false
    readonly property bool enableKeyboardBacklightHUD: values.enableKeyboardBacklightHUD !== false
    readonly property bool enableCustomOSD: values.enableCustomOSD !== false
    readonly property bool verticalHUD: values.enableVerticalHUD === true
    readonly property bool circularHUD: values.enableCircularHUD === true

    // ---- Live stats/terminal ----
    readonly property real statsInterval: Math.max(0.25, root.num("statsInterval", 1.0))
    readonly property bool statsShowCPU: values.statsShowCPU !== false
    readonly property bool statsShowMemory: values.statsShowMemory !== false
    readonly property bool statsShowGPU: values.statsShowGPU !== false
    readonly property bool statsShowNetwork: values.statsShowNetwork !== false
    readonly property bool statsShowDisk: values.statsShowDisk !== false
    readonly property string terminalShell: root.str("terminalShell", "bash")
    readonly property bool terminalEnabled: values.enableTerminalFeature === true
    readonly property var terminalCommands: root.str("terminalQuickCommands", "")
        .split(",").map(function (c) { return c.trim(); })
        .filter(function (c) { return c !== ""; })

    // ---- LLM usage (Usage tab; Stats > LLM Usage Monitor) ----
    readonly property bool llmUsageEnabled: values.enableLLMUsageFeature === true
    // ProviderID order (UsageProvider.swift). `key` is the Defaults key suffix.
    readonly property var llmProviders: [
        { id: "claude",      name: "Claude",      key: "enableClaudeProvider" },
        { id: "codex",       name: "Codex",       key: "enableCodexProvider" },
        { id: "cursor",      name: "Cursor",      key: "enableCursorProvider" },
        { id: "antigravity", name: "Antigravity", key: "enableAntigravityProvider" },
        { id: "newAPI",      name: "New API",     key: "enableNewAPIProvider" }
    ]
    function llmProviderEnabled(id) {
        var list = root.llmProviders;
        for (var i = 0; i < list.length; i++)
            if (list[i].id === id) return values[list[i].key] === true;
        return false;
    }
    readonly property var llmEnabledProviders: root.llmProviders
        .filter(function (p) { return root.llmProviderEnabled(p.id); })
        .map(function (p) { return p.id; })

    property FileView file: FileView {
        path: root.path
        atomicWrites: true
        watchChanges: false
        onLoaded: {
            try {
                var parsed = JSON.parse(root.file.text());
                if (parsed && typeof parsed === "object") {
                    var merged = root.defaults();
                    for (var k in parsed) if (merged[k] !== undefined || parsed[k] !== null) merged[k] = parsed[k];
                    root.values = merged;
                }
            } catch (e) {
                // Corrupt file: keep defaults, don't clobber the user's file.
            }
        }
        onLoadFailed: function (error) {
            // Missing file is normal on first run; defaults stand.
        }
    }

    property Timer saveTimer: Timer {
        interval: 250
        onTriggered: root.save()
    }

    property Process mkdir: Process {
        command: ["mkdir", "-p", root.configDir]
    }

    Component.onCompleted: mkdir.running = true
}
