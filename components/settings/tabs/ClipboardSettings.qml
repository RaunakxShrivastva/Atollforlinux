import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > ClipboardSettings.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Clipboard"

        FormRow {
            label: "Enable clipboard manager"
            FormToggle {
                checked: Settings.values.enableClipboardManager
                onToggled: (v) => Settings.set("enableClipboardManager", v)
            }
        }
        FormRow {
            label: "Show icon in notch"
            FormToggle {
                enabled: Settings.values.enableClipboardManager
                checked: Settings.values.showClipboardIcon
                onToggled: (v) => Settings.set("showClipboardIcon", v)
            }
        }
        FormRow {
            label: "Display mode"
            description: "Separate tab merges the clipboard with Notes."
            FormPicker {
                enabled: Settings.values.enableClipboardManager
                options: [
                    { value: "separateTab", label: "Separate tab \u00b7 merges with Notes" },
                    { value: "notchTab", label: "Dedicated clipboard tab" }
                ]
                value: Settings.clipboardMode
                onSelected: (v) => Settings.set("clipboardDisplayMode", v)
            }
        }
        FormRow {
            label: "History size"
            description: "Number of items visible at once."
            divider: false
            FormStepper {
                enabled: Settings.values.enableClipboardManager
                value: Settings.values.clipboardHistorySize
                from: 1
                to: 10
                onChanged: (v) => Settings.set("clipboardHistorySize", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "History"
        footer: "Uses wl-clipboard to watch the Wayland clipboard."

        FormRow {
            label: "Clear history"
            divider: false
            FormButtonRow {
                text: "Clear"
                onClicked: wipeProc.running = true
            }
        }
    }

    // "Clear history" wipes the cliphist store that backs the list.
    Process {
        id: wipeProc
        command: ["bash", "-c", "command -v cliphist >/dev/null && cliphist wipe 2>/dev/null || true"]
    }
}
