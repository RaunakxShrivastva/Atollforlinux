import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > NotesSettingsView.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "General"
        footer: "Customize how you organize and create notes. Enabling color filtering and search helps manage large lists."

        FormRow {
            label: "Enable notes"
            description: "Add a quick-note tab to the notch."
            FormToggle {
                checked: Settings.values.enableNotes
                onToggled: (v) => Settings.set("enableNotes", v)
            }
        }
        FormRow {
            label: "Enable note pinning"
            description: "Pin important notes to the top of the list."
            FormToggle {
                enabled: Settings.notesEnabled
                checked: Settings.values.enableNotePinning !== false
                onToggled: (v) => Settings.set("enableNotePinning", v)
            }
        }
        FormRow {
            label: "Enable note search"
            description: "Filter notes by title and body."
            FormToggle {
                enabled: Settings.notesEnabled
                checked: Settings.values.enableNoteSearch === true
                onToggled: (v) => Settings.set("enableNoteSearch", v)
            }
        }
        FormRow {
            label: "Enable color filtering"
            description: "Narrow the list down to one note colour."
            FormToggle {
                enabled: Settings.notesEnabled
                checked: Settings.values.enableNoteColorFiltering === true
                onToggled: (v) => Settings.set("enableNoteColorFiltering", v)
            }
        }
        FormRow {
            label: "Enable create from clipboard"
            description: "Paste clipboard text or an image into a new note."
            FormToggle {
                enabled: Settings.notesEnabled
                checked: Settings.values.enableCreateFromClipboard !== false
                onToggled: (v) => Settings.set("enableCreateFromClipboard", v)
            }
        }
        FormRow {
            label: "Show character count"
            divider: false
            description: "Display the note length under the editor."
            FormToggle {
                enabled: Settings.notesEnabled
                checked: Settings.values.enableNoteCharCount !== false
                onToggled: (v) => Settings.set("enableNoteCharCount", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Storage"
        footer: "Notes are saved as JSON with their attachments in note-images/."

        FormRow {
            label: "Storage location"
            divider: false
            FormLabel {
                text: "~/.local/share/atoll/notes.json"
                monospace: true
            }
        }
    }
}
