import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > Downloads (SettingsTab.downloads).
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Downloads"

        FormRow {
            label: "Enable downloads widget"
            description: "Show active downloads in the notch."
            FormToggle {
                checked: Settings.values.enableDownloadsWidget
                onToggled: (v) => Settings.set("enableDownloadsWidget", v)
            }
        }
        FormRow {
            label: "Watch folder"
            divider: false
            FormTextRow {
                enabled: Settings.values.enableDownloadsWidget
                fieldWidth: 180
                text: Settings.values.downloadsPath
                placeholder: "~/Downloads"
                onEdited: (t) => Settings.set("downloadsPath", t)
            }
        }
    }
}
