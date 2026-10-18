import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > DevicesSettingsView.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Audio"

        FormRow {
            label: "Media output control"
            description: "Pick the active sink from the opened player."
            FormToggle {
                checked: Settings.values.showMediaOutputControl
                onToggled: (v) => Settings.set("showMediaOutputControl", v)
            }
        }
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
            label: "Headphone detection"
            description: "Reveal the notch when headphones connect."
            divider: false
            FormToggle {
                checked: Settings.values.enableSneakPeek
                onToggled: (v) => Settings.set("enableSneakPeek", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Devices"
        footer: "Linux audio devices are managed by PipeWire/WirePlumber. Atoll lists the active sinks in the player's output menu."

        FormRow {
            label: "Active output"
            divider: false
            FormLabel { text: "Automatic (PipeWire)" }
        }
    }
}
