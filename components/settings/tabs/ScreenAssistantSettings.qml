import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > Screen Assistant (SettingsTab.screenAssistant).
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Screen Assistant"
        footer: "The macOS release uses Apple's on-device vision APIs. On Linux this feature is not available yet."

        FormRow {
            label: "Enable screen assistant"
            description: "Coming soon on Linux."
            divider: false
            FormToggle {
                enabled: false
                checked: false
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Model"

        FormRow {
            label: "Provider"
            FormPicker {
                enabled: false
                options: [
                    { value: "onDevice", label: "On-device" },
                    { value: "cloud", label: "Cloud" }
                ]
                value: "onDevice"
            }
        }
        FormRow {
            label: "API key"
            divider: false
            FormTextRow {
                enabled: false
                fieldWidth: 190
                placeholder: "Not available"
            }
        }
    }
}
