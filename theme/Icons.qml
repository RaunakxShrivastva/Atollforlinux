pragma Singleton
import QtQuick

// Icon names are the *SF Symbol names used by Atoll's Swift source*, mapped to
// their closest Material Symbols Rounded ligature. Views should use the SF name
// (e.g. "house.fill") so a 1:1 diff against Atoll stays possible. A few legacy
// short aliases are kept at the bottom for views not yet migrated.
QtObject {
    readonly property var map: ({
        // ---- Tabs (TabSelectionView) ----
        "house.fill": "home",
        "tray.fill": "inbox",
        "timer": "timer",
        "chart.xyaxis.line": "show_chart",
        "chart.bar.doc.horizontal": "bar_chart",
        "note.text": "sticky_note_2",
        "doc.on.clipboard": "content_paste",
        "apple.terminal": "terminal",
        "puzzlepiece.extension": "extension",

        // ---- Clipboard item types (ClipboardItemType.icon) ----
        "doc.text": "description",
        "doc": "insert_drive_file",
        "photo": "image",
        "doc.richtext": "article",
        "questionmark.circle": "help",

        // ---- Usage tab (NotchLLMUsageView: ProgressView spinner) ----
        "progress_activity": "progress_activity",

        // ---- Header extras ("…" overflow) ----
        "ellipsis": "more_horiz",
        "arrow.down.forward.and.arrow.up.backward": "unfold_more",

        // ---- Settings sidebar tabs (SettingsTab.systemImage) ----
        "waveform.path.ecg": "monitor_heart",
        "paintpalette": "palette",
        "lock.laptopcomputer": "screen_lock_portrait",
        "play.laptopcomputer": "smart_display",
        "headphones": "headphones",
        "dial.medium.fill": "tune",
        "battery.100.bolt": "battery_charging_full",
        "brain.head.profile": "psychology",
        "square.and.arrow.down": "download",
        "books.vertical": "library_books",
        "keyboard": "keyboard",
        "info.circle.fill": "info",

        // ---- Settings controls / misc ----
        "arrow.clockwise": "refresh",
        "wand.and.stars": "auto_awesome",
        "square.grid.2x2": "grid_view",
        "rectangle.on.rectangle": "picture_in_picture_alt",
        "circle.lefthalf.filled": "contrast",
        "moon.fill": "dark_mode",
        "lock.fill": "lock",
        "lock.open.fill": "lock_open",
        "bell.badge": "notifications_active",
        "clock.arrow.circlepath": "history",
        "gauge": "speed",
        "waveform": "graphic_eq",
        "megaphone": "campaign",
        "paintbrush.fill": "brush",
        "textformat": "text_fields",
        "minus": "remove",
        "arrow.up.arrow.down": "swap_vert",
        "arrow.left.arrow.right": "swap_horiz",
        "rectangle.portrait.and.arrow.right": "logout",
        "checkmark.circle": "check_circle",
        "exclamationmark.triangle.fill": "warning",

        // ---- Header actions (DynamicIslandHeader) ----
        "web.camera": "photo_camera",
        "list.clipboard": "list_alt",
        "eyedropper": "colorize",
        "eyedropper.halffull": "colorize",
        "gearshape": "settings",
        "gearshape.fill": "settings",
        "slider.vertical.3": "tune",
        "cup.and.saucer": "coffee",
        "cup.and.saucer.fill": "coffee",
        "gear": "settings",

        // ---- Generic glyphs ----
        "xmark": "close",
        "xmark.circle.fill": "cancel",
        "stop.fill": "stop",
        "checkmark": "check",
        "checkmark.circle.fill": "check_circle",
        "play.fill": "play_arrow",
        "pause.fill": "pause",
        "arrow.counterclockwise": "refresh",
        "plus": "add",
        "plus.circle.fill": "add_circle",
        "trash": "delete",
        "magnifyingglass": "search",
        "heart.fill": "favorite",
        "heart": "favorite_border",
        "doc.on.doc": "content_copy",
        "hand.point.up.left": "touch_app",
        "rectangle.grid.2x2": "grid_view",
        "clipboard": "content_paste",
        "push_pin": "push_pin",
        "pin": "push_pin",
        "pin.fill": "push_pin",
        "pin.slash.fill": "push_pin",
        "link": "link",
        "info.circle": "info",
        "clock": "schedule",
        "mappin.and.ellipse": "location_on",

        // ---- Chevrons ----
        "chevron.left": "chevron_left",
        "chevron.right": "chevron_right",
        "chevron.up": "keyboard_arrow_up",
        "chevron.down": "keyboard_arrow_down",

        // ---- Media (NotchHomeView / MusicControlOverlay) ----
        "backward.fill": "skip_previous",
        "forward.fill": "skip_next",
        "gobackward.10": "replay_10",
        "goforward.10": "forward_10",
        "shuffle": "shuffle",
        "repeat": "repeat",
        "repeat.1": "repeat_one",
        "airplayaudio": "airplay",
        "music.note": "music_note",
        "music.note.slash": "music_off",
        "speaker.slash.fill": "volume_off",
        "speaker.wave.1.fill": "volume_down",
        "speaker.wave.2.fill": "volume_up",
        "speaker.wave.3.fill": "volume_up",

        // ---- Stats (NotchStatsView) ----
        "cpu": "developer_board",
        "memorychip": "memory",
        "display": "monitor",
        "network": "lan",
        "internaldrive": "storage",
        "externaldrive": "storage",
        "chart.line.uptrend.xyaxis": "trending_up",
        "wifi": "wifi",
        "cable.connector": "cable",

        // ---- Calendar / reminders ----
        "calendar.badge.checkmark": "event_available",
        "calendar.badge.clock": "event",
        "calendar.badge.exclamationmark": "event_busy",
        "video.fill": "videocam",

        // ---- Shelf ----
        "tray.and.arrow.down": "download",
        "square.and.arrow.up": "ios_share",
        "switch.2": "tune",
        "hand.raised.fill": "front_hand",

        // ---- Misc ----
        "arrow.triangle.2.circlepath": "sync",
        "sun.min.fill": "brightness_low",
        "sun.min": "brightness_low",
        "light.min": "brightness_low",
        "sun.max.fill": "brightness_high",
        "sun.max": "brightness_6",
        "light.max": "brightness_high",
        "hifispeaker": "speaker",
        "hifispeaker.fill": "speaker",
        "speaker": "volume_up",
        "mountain.2.fill": "landscape",
        "apple.logo": "laptop_mac",
        "app": "apps",

        // ---- Legacy short aliases (views not yet migrated to SF names) ----
        "play": "play_arrow",
        "pause": "pause",
        "next": "skip_next",
        "prev": "skip_previous",
        "forward": "fast_forward",
        "back": "fast_rewind",
        "music": "music_note",
        "equalizer": "graphic_eq",
        "home": "home",
        "calendar": "calendar_month",
        "stats": "monitoring",
        "chart": "bar_chart",
        "clipboardAlt": "content_paste",
        "bell": "notifications",
        "notification": "notifications",
        "settings": "settings",
        "tools": "handyman",
        "close": "close",
        "chevronLeft": "chevron_left",
        "chevronRight": "chevron_right",
        "chevronUp": "keyboard_arrow_up",
        "chevronDown": "keyboard_arrow_down",
        "ram": "memory",
        "memory": "memory",
        "battery": "battery_full",
        "charging": "battery_charging_full",
        "bolt": "bolt",
        "signal": "signal_cellular_alt",
        "brightness": "brightness_6",
        "language": "language",
        "power": "power_settings_new",
        "volume": "volume_up",
        "volumeMute": "volume_off",
        "device": "airplay",
        "screenshot": "screenshot_monitor",
        "smiley": "mood",
        "arrow.down.circle": "download",
        "battery.100": "battery_full",
        "battery.100.bolt": "battery_charging_full",
        "battery.75": "battery_6_bar",
        "battery.50": "battery_4_bar",
        "battery.25": "battery_2_bar",
        "battery.0": "battery_0_bar",
        "note": "sticky_note_2",
        "colorPicker": "colorize",
        "palette": "palette",
        "terminal": "terminal",
        "folder": "folder_open",
        "apps": "apps",
        "grid": "grid_view",
        "image": "image",
        "pdf": "picture_as_pdf",
        "bookmarks": "bookmarks",
        "check": "check",
        "checkCircle": "check_circle",
        "radio": "radio_button_checked",
        "circle": "circle",
        "tune": "tune",
        "build": "build",
        "rocket": "rocket_launch",
        "download": "download",
        "cloud": "cloud_download",
        "spotify": "library_music"
    })

    // Custom vector assets that replace the Material glyph for an SF name.
    // Paths are relative to the repository root. Assets must be monochrome
    // white-on-transparent; SvgIcon tints them with the requested colour (a
    // black SVG cannot be re-coloured by MultiEffect's colorization).
    readonly property var assetMap: ({
        "house.fill": "assets/icons/house.svg",
        "tray.fill": "assets/icons/inbox.svg",
        "chart.xyaxis.line": "assets/icons/stats.svg",
        "timer": "assets/icons/timer.svg",
        "gearshape": "assets/icons/gear.svg",
        "gearshape.fill": "assets/icons/gear.svg",
        "list.clipboard": "assets/icons/clipboard.svg",
        "doc.on.clipboard": "assets/icons/clipboard.svg",
        "eyedropper": "assets/icons/dropper.svg",
        "cup.and.saucer": "assets/icons/coffee.svg",
        "cup.and.saucer.fill": "assets/icons/coffee.svg",
        "apple.terminal": "assets/icons/terminal.svg",
        "terminal": "assets/icons/terminal.svg",
        "note.text": "assets/icons/notes.svg",
        "play.fill": "assets/icons/play.svg",
        "pause.fill": "assets/icons/pause.svg",
        "forward.fill": "assets/icons/track-next.svg",
        "backward.fill": "assets/icons/track-previous.svg",
        "shuffle": "assets/icons/shuffle.svg",
        "repeat": "assets/icons/repeat.svg",
        "repeat.1": "assets/icons/repeat-one.svg"
    })

    function glyph(name) {
        var lig = map[name];
        return lig === undefined ? "" : lig;
    }

    // Repo-relative asset path for an SF name, or "" when it uses the font.
    function asset(name) {
        var a = assetMap[name];
        return a === undefined ? "" : a;
    }

    // Where the Material Symbols variable font should use FILL=1 to match the
    // SF Symbol's solid variant. Everything ending in ".fill" in SF is solid;
    // a few SF symbols are solid without the suffix (checked against
    // Atoll's .swift sources and the sample screenshots).
    readonly property var solidNames: ({
        "apple.terminal": true,
        "gearshape": true,
        "battery.100.bolt": true,
        "music.note": true,
        "cpu": true,
        "memorychip": true,
        "internaldrive": true,
        "externaldrive": true
    })

    function filled(name) {
        return solidNames[name] === true || name.slice(-5) === ".fill";
    }

    // Alias so callers can read "icon name" as an SF symbol name.
    function symbol(name) { return glyph(name); }
}
