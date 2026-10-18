import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > SettingsTab.colorPicker.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Color picker"

        FormRow {
            label: "Enable colour picker"
            FormToggle {
                checked: Settings.values.enableColorPickerFeature
                onToggled: (v) => Settings.set("enableColorPickerFeature", v)
            }
        }
        FormRow {
            label: "Display mode"
            // Atoll's ColorPickerDisplayMode: the header button opens either a
            // floating panel (or here, a window) or a popover attached to it.
            FormPicker {
                enabled: Settings.values.enableColorPickerFeature
                options: [
                    { value: "panel", label: "Panel" },
                    { value: "popover", label: "Popover" }
                ]
                value: Settings.values.colorPickerDisplayMode
                onSelected: (v) => Settings.set("colorPickerDisplayMode", v)
            }
        }
        FormRow {
            label: "Header icon"
            FormToggle {
                enabled: Settings.values.enableColorPickerFeature
                checked: Settings.values.showColorPickerIcon !== false
                onToggled: (v) => Settings.set("showColorPickerIcon", v)
            }
        }
        FormRow {
            label: "Show all colour formats"
            divider: false
            FormToggle {
                enabled: Settings.values.enableColorPickerFeature
                checked: Settings.values.showColorFormats !== false
                onToggled: (v) => Settings.set("showColorFormats", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "History"

        FormRow {
            label: "Copy format"
            FormPicker {
                enabled: Settings.values.enableColorPickerFeature
                options: [
                    { value: "hex", label: "HEX" },
                    { value: "rgb", label: "RGB" },
                    { value: "rgba", label: "RGBA" },
                    { value: "hsl", label: "HSL" },
                    { value: "hsv", label: "HSV" }
                ]
                value: Settings.values.colorPickerFormat
                onSelected: (v) => Settings.set("colorPickerFormat", v)
            }
        }
        FormRow {
            label: "History size"
            divider: false
            FormStepper {
                value: Settings.values.colorHistorySize
                from: 1
                to: 50
                onChanged: (v) => Settings.set("colorHistorySize", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Sampling"
        footer: "Picks the pixel under the cursor. Uses hyprpicker on Hyprland; on "
                + "other compositors it grabs a region with Spectacle and reads its "
                + "centre, so drag a small box around the colour you want."

        FormRow {
            label: "Backends"
            divider: false
            FormLabel { text: "hyprpicker → Spectacle region fallback" }
        }
    }
}
