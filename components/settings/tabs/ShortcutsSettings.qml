import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > Shortcuts.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Gestures"

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
            label: "Sensitivity"
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
            label: "Reverse swipe"
            divider: false
            FormToggle {
                checked: Settings.values.reverseSwipeGestures
                onToggled: (v) => Settings.set("reverseSwipeGestures", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Keyboard shortcuts"
        footer: "Bind these in your compositor. On Hyprland, edit ~/.config/hypr/bindings.conf."

        FormRow {
            label: "Toggle notch"
            FormLabel {
                text: "Super + Shift + N"
                monospace: true
            }
        }
        FormRow {
            label: "Toggle minimalistic UI"
            FormLabel {
                text: "Super + Shift + M"
                monospace: true
            }
        }
        FormRow {
            label: "Open settings"
            divider: false
            FormLabel {
                text: "Super + Shift + ,"
                monospace: true
            }
        }
    }
}
