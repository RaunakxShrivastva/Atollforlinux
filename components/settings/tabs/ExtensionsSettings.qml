import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > ExtensionsSettings.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Extensions"
        footer: "Atoll extensions are JavaScript plugins discovered in ~/.config/atoll/extensions."

        FormRow {
                    settingKey: "enableExtensions"
            label: "Enable extensions"
            FormToggle {
                checked: Settings.values.enableExtensions
                onToggled: (v) => Settings.set("enableExtensions", v)
            }
        }
        FormRow {
            label: "Extensions folder"
            divider: false
            FormLabel {
                text: "~/.config/atoll/extensions"
                monospace: true
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Installed"

        FormRow {
            label: "No extensions installed"
            divider: false
            FormButtonRow { text: "Open folder" }
        }
    }
}
