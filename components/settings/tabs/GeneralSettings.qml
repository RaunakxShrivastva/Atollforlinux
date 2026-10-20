import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > GeneralSettings.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "General"

        FormRow {
            label: "Minimalistic UI"
            description: "Use a compact closed state with just the album art."
            FormToggle {
                checked: Settings.values.enableMinimalisticUI
                onToggled: (v) => Settings.set("enableMinimalisticUI", v)
            }
        }
        FormRow {
            label: "Settings icon in notch"
            FormToggle {
                checked: Settings.values.settingsIconInNotch
                onToggled: (v) => Settings.set("settingsIconInNotch", v)
            }
        }
        FormRow {
            label: "Menu bar icon"
            description: "A status-bar item alongside the notch."
            settingKey: "menubarIcon"
            FormToggle {
                checked: Settings.values.menubarIcon
                onToggled: (v) => Settings.set("menubarIcon", v)
            }
        }
        FormRow {
            label: "Open notch on hover"
            FormToggle {
                checked: Settings.values.openNotchOnHover
                onToggled: (v) => Settings.set("openNotchOnHover", v)
            }
        }
        FormRow {
            label: "Minimum hover duration"
            description: "How long the pointer must rest before the notch opens."
            FormSlider {
                from: 0.1
                to: 1.5
                step: 0.05
                trackWidth: 150
                value: Settings.values.minimumHoverDuration
                valueText: Number(Settings.values.minimumHoverDuration).toFixed(2) + " s"
                onMoved: (v) => Settings.set("minimumHoverDuration", v)
            }
        }
        FormRow {
            label: "Extend hover area"
            description: "Open when the pointer is near the notch, not only over it."
            divider: false
            FormToggle {
                checked: Settings.values.extendHoverArea
                onToggled: (v) => Settings.set("extendHoverArea", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Displays"

        FormRow {
            label: "Show on all displays"
            FormToggle {
                checked: Settings.values.showOnAllDisplays
                onToggled: (v) => Settings.set("showOnAllDisplays", v)
            }
        }
        FormRow {
                    settingKey: "automaticallySwitchDisplay"
            label: "Automatically switch display"
            description: "Follow the display holding the focused window."
            FormToggle {
                checked: Settings.values.automaticallySwitchDisplay
                onToggled: (v) => Settings.set("automaticallySwitchDisplay", v)
            }
        }
        FormRow {
            label: "External display style"
            description: "Menu bar sits flush with the top edge; Notch keeps rounded top corners."
            FormPicker {
                options: [
                    { value: "notch", label: "Notch" },
                    { value: "menuBar", label: "Menu bar" },
                    { value: "floating", label: "Floating pill" }
                ]
                value: Settings.values.externalDisplayStyle
                onSelected: (v) => Settings.set("externalDisplayStyle", v)
            }
        }
        FormRow {
            label: "Hide non-notch until hover"
            FormToggle {
                checked: Settings.values.hideNonNotchUntilHover
                onToggled: (v) => Settings.set("hideNonNotchUntilHover", v)
            }
        }
        FormRow {
            label: "Preferred screen"
            description: "Match string of a monitor name; empty = automatic."
            divider: false
            FormTextRow {
                fieldWidth: 150
                text: Settings.values.preferredScreen
                placeholder: "eDP-1"
                onEdited: (t) => Settings.set("preferredScreen", t)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Behaviour"

        FormRow {
            label: "Open last tab by default"
            FormToggle {
                checked: Settings.values.openLastTabByDefault
                onToggled: (v) => Settings.set("openLastTabByDefault", v)
            }
        }
        FormRow {
            label: "Reduce motion"
            description: "Follow the desktop preference, or force motion on/off."
            FormPicker {
                options: [
                    { value: "system", label: "System" },
                    { value: "on", label: "On" },
                    { value: "off", label: "Off" }
                ]
                value: Settings.values.reduceMotion
                onSelected: (v) => Settings.set("reduceMotion", v)
            }
        }
        FormRow {
            settingKey: "enableHaptics"
            label: "Haptics"
            description: "Requires a trackpad with haptic feedback."
            FormToggle {
                checked: Settings.values.enableHaptics
                onToggled: (v) => Settings.set("enableHaptics", v)
            }
        }
        FormRow {
            label: "Enable gestures"
            FormToggle {
                checked: Settings.values.enableGestures
                onToggled: (v) => Settings.set("enableGestures", v)
            }
        }
        FormRow {
            label: "Close gesture"
            FormToggle {
                enabled: Settings.values.enableGestures
                checked: Settings.values.closeGestureEnabled
                onToggled: (v) => Settings.set("closeGestureEnabled", v)
            }
        }
        FormRow {
            label: "Gesture sensitivity"
            FormSlider {
                from: 50
                to: 400
                step: 10
                trackWidth: 150
                value: Settings.values.gestureSensitivity
                valueText: String(Settings.values.gestureSensitivity)
                onMoved: (v) => Settings.set("gestureSensitivity", v)
            }
        }
        FormRow {
            label: "Horizontal music gestures"
            FormToggle {
                checked: Settings.values.enableHorizontalMusicGestures
                onToggled: (v) => Settings.set("enableHorizontalMusicGestures", v)
            }
        }
        FormRow {
            label: "Music gesture behaviour"
            FormPicker {
                options: [
                    { value: "track", label: "Change track" },
                    { value: "seek", label: "Seek" }
                ]
                value: Settings.values.musicGestureBehavior
                onSelected: (v) => Settings.set("musicGestureBehavior", v)
            }
        }
        FormRow {
            label: "Reverse swipe gestures"
            FormToggle {
                checked: Settings.values.reverseSwipeGestures
                onToggled: (v) => Settings.set("reverseSwipeGestures", v)
            }
        }
        FormRow {
            label: "Reverse scroll gestures"
            divider: false
            FormToggle {
                checked: Settings.values.reverseScrollGestures
                onToggled: (v) => Settings.set("reverseScrollGestures", v)
            }
        }
    }
}
