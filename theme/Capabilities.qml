pragma Singleton
import QtQuick

// Platform capability notes for the settings UI.
//
// Atoll is a macOS app: a handful of its settings have no honest equivalent on
// Linux. Rather than leave them looking live while doing nothing, the settings
// window shows them dimmed with the reason below, so the panel never lies about
// what it can do.
QtObject {
    id: root

    readonly property var notes: ({
        // Window-manager level; layer-shell surfaces cannot opt out of capture.
        "hideDynamicIslandFromScreenCapture":
            "Not available under Wayland: the compositor does not let a layer surface exclude itself from screen capture.",
        "enableFullscreenMediaDetection":
            "Needs a compositor query this session does not expose; the island stays visible over fullscreen windows.",
        // macOS-specific integrations.
        "enableHaptics":
            "No haptic hardware is exposed by this machine; there is nothing to drive.",
        "menubarIcon":
            "macOS status-bar item; Wayland has no equivalent menu bar owned by a shell.",
        "enableExtensions":
            "The extension host is a macOS JavaScript runtime; not ported.",
        "enableLockScreenMediaWidget":
            "kscreenlocker does not allow a third-party shell to inject lock-screen widgets.",
        "enableLockScreenWeatherWidget":
            "kscreenlocker does not allow a third-party shell to inject lock-screen widgets.",
        "enableLockScreenFocusWidget":
            "kscreenlocker does not allow a third-party shell to inject lock-screen widgets.",
        "enableLockScreenReminderWidget":
            "kscreenlocker does not allow a third-party shell to inject lock-screen widgets.",
        "enableLockScreenTimerWidget":
            "kscreenlocker does not allow a third-party shell to inject lock-screen widgets.",
        "lockScreenGlassStyle":
            "Governs the macOS lock-screen panel, which cannot be replaced here.",
        "lockScreenPanelShowsBorder":
            "Governs the macOS lock-screen panel, which cannot be replaced here.",
        "lockScreenPanelUsesBlur":
            "Governs the macOS lock-screen panel, which cannot be replaced here.",
        "lockScreenShowAppIcon":
            "Governs the macOS lock-screen panel, which cannot be replaced here.",
        "lockScreenWidgetAppearance":
            "Governs the macOS lock-screen panel, which cannot be replaced here.",
        "lockScreenWeatherShowsAQI":
            "Governs the macOS lock-screen weather widget, which cannot be replaced here.",
        "lockScreenWeatherShowsLocation":
            "Governs the macOS lock-screen weather widget, which cannot be replaced here.",
        "lockScreenWeatherShowsSunrise":
            "Governs the macOS lock-screen weather widget, which cannot be replaced here.",
        "lockScreenWeatherTemperatureUnit":
            "Governs the macOS lock-screen weather widget, which cannot be replaced here.",
        // Partial: works only in some sessions.
        "automaticallySwitchDisplay":
            "Follows the pointer across outputs; needs a compositor IPC this session does not expose."
    })

    function note(key) {
        return root.notes[key] !== undefined ? root.notes[key] : "";
    }

    function unsupported(key) {
        return root.note(key) !== "";
    }
}
