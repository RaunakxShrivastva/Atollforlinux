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
            description: Settings.clipboardMode === "popover"
                ? "Shows clipboard as a dropdown attached to the clipboard button"
                : (Settings.clipboardMode === "panel"
                    ? "Shows clipboard in a floating panel near the notch"
                    : (Settings.clipboardMode === "notchTab"
                        ? "Shows copied items in a dedicated clipboard tab inside the notch"
                        : "Shows clipboard in a pane beside Notes"))
            FormPicker {
                enabled: Settings.values.enableClipboardManager
                options: [
                    { value: "popover", label: "Popover" },
                    { value: "panel", label: "Panel" },
                    { value: "separateTab", label: "Separate Tab" },
                    { value: "notchTab", label: "Notch Tab" }
                ]
                value: Settings.clipboardMode
                onSelected: (v) => Settings.set("clipboardDisplayMode", v)
            }
        }
        FormRow {
            label: "History size"
            description: "Number of items visible at once."
            FormStepper {
                enabled: Settings.values.enableClipboardManager
                value: Settings.values.clipboardHistorySize
                from: 1
                to: 10
                onChanged: (v) => Settings.set("clipboardHistorySize", v)
            }
        }
        FormRow {
            label: "Persist history"
            description: "Keep the clipboard across restarts. Off starts each session empty."
            divider: false
            FormToggle {
                enabled: Settings.values.enableClipboardManager
                checked: Settings.values.persistClipboardHistory
                onToggled: (v) => Settings.set("persistClipboardHistory", v)
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

    FormSection {
        Layout.fillWidth: true
        title: "Favorites"
        footer: "Pinned items are kept as copies under ~/.local/share/atoll/clip-favorites."

        FormRow {
            label: "Favorites"
            description: ClipboardService.favorites.length === 1
                ? "1 item pinned" : (ClipboardService.favorites.length + " items pinned")
            FormButtonRow {
                text: "Clear favorites"
                enabled: ClipboardService.favorites.length > 0
                onClicked: ClipboardService.clearFavorites()
            }
        }

        FormRow {
            label: "How to pin"
            description: "Hover a row in the popover or panel and press the pin. Pinned items stay in the Favorites tab."
            divider: false
        }
    }

    // "Clear history" wipes the cliphist store that backs the list.
    Process {
        id: wipeProc
        command: ["bash", "-c", "command -v cliphist >/dev/null && cliphist wipe 2>/dev/null || true"]
    }
}
