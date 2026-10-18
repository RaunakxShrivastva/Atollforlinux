import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > Shelf (SettingsTab.shelf).
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Shelf"

        FormRow {
            label: "Enable shelf"
            description: "Drop files onto the notch to stash them."
            FormToggle {
                checked: Settings.values.enableShelf
                onToggled: (v) => Settings.set("enableShelf", v)
            }
        }
        FormRow {
            label: "Maximum items"
            divider: false
            FormStepper {
                enabled: Settings.values.enableShelf
                value: Settings.values.shelfMaxItems
                from: 1
                to: 30
                onChanged: (v) => Settings.set("shelfMaxItems", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Drop target"
        footer: "Files are tracked by path; nothing is copied or moved."

        FormRow {
            label: "Shelf location"
            divider: false
            FormLabel {
                text: "~/.local/share/atoll/shelf"
                monospace: true
            }
        }
    }
}
