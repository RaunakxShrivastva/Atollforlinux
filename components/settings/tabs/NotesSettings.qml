import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > NotesSettings (part of SettingsTab.notes).
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Notes"
        footer: "Notes are stored as Markdown under ~/.local/share/atoll/notes."

        FormRow {
            label: "Enable notes"
            description: "Add a quick-note tab to the notch."
            FormToggle {
                checked: Settings.values.enableNotes
                onToggled: (v) => Settings.set("enableNotes", v)
            }
        }
        FormRow {
            label: "Storage location"
            divider: false
            FormLabel {
                text: "~/.local/share/atoll/notes"
                monospace: true
            }
        }
    }
}
