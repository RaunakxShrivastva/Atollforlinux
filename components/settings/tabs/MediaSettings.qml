import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > Media.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Playback"

        FormRow {
            label: "Music source"
            FormPicker {
                options: [
                    { value: "auto", label: "Automatic" },
                    { value: "mpris", label: "MPRIS" },
                    { value: "playerctl", label: "playerctl" }
                ]
                value: Settings.values.musicSource
                onSelected: (v) => Settings.set("musicSource", v)
            }
        }
        FormRow {
            label: "Skip behaviour"
            FormPicker {
                options: [
                    { value: "track", label: "Next / previous track" },
                    { value: "seek", label: "Seek 10 seconds" }
                ]
                value: Settings.values.musicSkipBehavior
                onSelected: (v) => Settings.set("musicSkipBehavior", v)
            }
        }
        FormRow {
            label: "Standard media controls"
            FormToggle {
                checked: Settings.values.showStandardMediaControls
                onToggled: (v) => Settings.set("showStandardMediaControls", v)
            }
        }
        FormRow {
            label: "Auto-hide inactive player"
            FormToggle {
                checked: Settings.values.autoHideInactiveNotchMediaPlayer
                onToggled: (v) => Settings.set("autoHideInactiveNotchMediaPlayer", v)
            }
        }
        FormRow {
                    settingKey: "enableFullscreenMediaDetection"
            label: "Fullscreen media detection"
            description: "Pause the expanded player over fullscreen apps."
            divider: false
            FormToggle {
                checked: Settings.values.enableFullscreenMediaDetection
                onToggled: (v) => Settings.set("enableFullscreenMediaDetection", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Lyrics"

        FormRow {
                    settingKey: "enableLyrics"
            label: "Show lyrics"
            FormToggle {
                checked: Settings.values.enableLyrics
                onToggled: (v) => Settings.set("enableLyrics", v)
            }
        }
        FormRow {
            label: "Highlight"
            description: "How the line being sung is drawn."
            settingKey: "lyricHighlightStyle"
            FormPicker {
                options: [
                    { value: "sweep", label: "Sweep" },
                    { value: "gradient", label: "Gradient" },
                    { value: "solid", label: "Solid" }
                ]
                value: Settings.values.lyricHighlightStyle
                onSelected: (v) => Settings.set("lyricHighlightStyle", v)
            }
        }
        FormRow {
            label: "Pinned lines"
            description: "Lines kept under the closed notch while pinned."
            settingKey: "pinnedLyricContext"
            FormPicker {
                options: [
                    { value: 1, label: "Current line" },
                    { value: 3, label: "Three lines" },
                    { value: 5, label: "Five lines" }
                ]
                value: Settings.values.pinnedLyricContext
                onSelected: (v) => Settings.set("pinnedLyricContext", v)
            }
        }
        FormRow {
            label: "Panel width"
            settingKey: "lyricsPanelWidth"
            FormSlider {
                from: 180
                to: 420
                step: 10
                value: Settings.values.lyricsPanelWidth
                valueText: Math.round(value) + " px"
                onMoved: (v) => Settings.set("lyricsPanelWidth", v)
            }
        }
        FormRow {
            label: "Panel offset"
            divider: false
            settingKey: "lyricsPanelOffset"
            FormSlider {
                from: -100
                to: 100
                step: 1
                value: Settings.values.lyricsPanelOffset
                valueText: (value >= 0 ? "+" : "") + Math.round(value) + " px"
                onMoved: (v) => Settings.set("lyricsPanelOffset", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Closed notch"

        FormRow {
            label: "Show album art"
            description: "The track's artwork on the closed pill."
            settingKey: "closedShowAlbumArt"
            FormToggle {
                checked: Settings.values.closedShowAlbumArt
                onToggled: (v) => Settings.set("closedShowAlbumArt", v)
            }
        }
        FormRow {
            label: "Show track title"
            description: "Title and artist next to the art."
            settingKey: "closedShowTrackTitle"
            FormToggle {
                checked: Settings.values.closedShowTrackTitle
                onToggled: (v) => Settings.set("closedShowTrackTitle", v)
            }
        }
        FormRow {
            label: "Show visualizer"
            description: "Waveform capsule on the closed pill."
            settingKey: "closedShowVisualizer"
            FormToggle {
                checked: Settings.values.closedShowVisualizer
                onToggled: (v) => Settings.set("closedShowVisualizer", v)
            }
        }
        FormRow {
            label: "Show clock"
            description: "Idle time readout when nothing else shows."
            settingKey: "closedShowClock"
            FormToggle {
                checked: Settings.values.closedShowClock
                onToggled: (v) => Settings.set("closedShowClock", v)
            }
        }
        FormRow {
            label: "Show battery"
            description: "Idle battery level; the same switch as in Battery settings."
            settingKey: "showBatteryIndicator"
            FormToggle {
                checked: Settings.values.showBatteryIndicator
                onToggled: (v) => Settings.set("showBatteryIndicator", v)
            }
        }
        FormRow {
            label: "Timer countdown"
            description: "Live countdown takes over the pill while a timer runs."
            settingKey: "closedShowTimer"
            FormToggle {
                checked: Settings.values.closedShowTimer
                onToggled: (v) => Settings.set("closedShowTimer", v)
            }
        }
        FormRow {
            label: "Pin lyrics when closed"
            description: "Current line kept under the closed pill (from Lyrics)."
            settingKey: "pinLyricsWhenClosed"
            FormToggle {
                checked: Settings.values.pinLyricsWhenClosed
                onToggled: (v) => Settings.set("pinLyricsWhenClosed", v)
            }
        }
        FormRow {
            label: "Notifications on the pill"
            description: "Show notifications on the closed notch, morphing to fit, instead of opening it."
            divider: false
            settingKey: "closedNotchNotifications"
            FormToggle {
                checked: Settings.values.closedNotchNotifications
                onToggled: (v) => Settings.set("closedNotchNotifications", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Sneak peek"

        FormRow {
            label: "Enable sneak peek"
            description: "Briefly reveal the notch when a track changes."
            FormToggle {
                checked: Settings.values.enableSneakPeek
                onToggled: (v) => Settings.set("enableSneakPeek", v)
            }
        }
        FormRow {
            label: "Style"
            FormPicker {
                options: [
                    { value: "standard", label: "Standard" },
                    { value: "compact", label: "Compact" },
                    { value: "minimal", label: "Minimal" }
                ]
                value: Settings.values.sneakPeekStyles
                onSelected: (v) => Settings.set("sneakPeekStyles", v)
            }
        }
        FormRow {
            label: "Show on track change"
            divider: false
            FormToggle {
                checked: Settings.values.showSneakPeekOnTrackChange
                onToggled: (v) => Settings.set("showSneakPeekOnTrackChange", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Animation"

        FormRow {
            label: "Parallax intensity"
            FormSlider {
                from: 0
                to: 20
                step: 1
                trackWidth: 150
                value: Settings.values.parallaxEffectIntensity
                valueText: String(Settings.values.parallaxEffectIntensity)
                onMoved: (v) => Settings.set("parallaxEffectIntensity", v)
            }
        }
        FormRow {
            label: "Wait interval"
            description: "Idle seconds before the player collapses."
            divider: false
            FormStepper {
                value: Settings.values.waitInterval
                from: 0
                to: 30
                onChanged: (v) => Settings.set("waitInterval", v)
            }
        }
    }
}
