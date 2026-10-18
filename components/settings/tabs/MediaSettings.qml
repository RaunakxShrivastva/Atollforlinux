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
                    settingKey: "pinLyricsWhenClosed"
            label: "Pin lyrics when closed"
            divider: false
            FormToggle {
                checked: Settings.values.pinLyricsWhenClosed
                onToggled: (v) => Settings.set("pinLyricsWhenClosed", v)
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
