import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > HUDAndOSDSettingsView (tab id "hudAndOSD").
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "HUD"

        FormRow {
            label: "System HUD"
            FormToggle {
                checked: Settings.values.enableSystemHUD
                onToggled: (v) => Settings.set("enableSystemHUD", v)
            }
        }
        FormRow {
            label: "Volume"
            FormToggle {
                enabled: Settings.values.enableSystemHUD
                checked: Settings.values.enableVolumeHUD
                onToggled: (v) => Settings.set("enableVolumeHUD", v)
            }
        }
        FormRow {
            label: "Brightness"
            FormToggle {
                enabled: Settings.values.enableSystemHUD
                checked: Settings.values.enableBrightnessHUD
                onToggled: (v) => Settings.set("enableBrightnessHUD", v)
            }
        }
        FormRow {
            label: "Keyboard backlight"
            divider: false
            FormToggle {
                enabled: Settings.values.enableSystemHUD
                checked: Settings.values.enableKeyboardBacklightHUD
                onToggled: (v) => Settings.set("enableKeyboardBacklightHUD", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "OSD"

        FormRow {
            label: "Custom OSD"
            description: "Replace the desktop's OSD with the notch overlay."
            FormToggle {
                checked: Settings.values.enableCustomOSD
                onToggled: (v) => Settings.set("enableCustomOSD", v)
            }
        }
        FormRow {
            label: "Vertical layout"
            FormToggle {
                checked: Settings.values.enableVerticalHUD
                onToggled: (v) => Settings.set("enableVerticalHUD", v)
            }
        }
        FormRow {
            label: "Circular layout"
            divider: false
            FormToggle {
                checked: Settings.values.enableCircularHUD
                onToggled: (v) => Settings.set("enableCircularHUD", v)
            }
        }
    }
}
