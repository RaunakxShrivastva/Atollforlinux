import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > StatsSettings.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Monitoring"

        FormRow {
            label: "Refresh interval"
            FormSlider {
                from: 0.5
                to: 5
                step: 0.5
                trackWidth: 150
                value: Settings.values.statsInterval
                valueText: Number(Settings.values.statsInterval).toFixed(1) + " s"
                onMoved: (v) => Settings.set("statsInterval", v)
            }
        }
        FormRow {
            label: "CPU"
            divider: false
            FormToggle {
                checked: Settings.values.statsShowCPU
                onToggled: (v) => Settings.set("statsShowCPU", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Sensors"

        FormRow {
            label: "Memory"
            FormToggle {
                checked: Settings.values.statsShowMemory
                onToggled: (v) => Settings.set("statsShowMemory", v)
            }
        }
        FormRow {
            label: "GPU"
            FormToggle {
                checked: Settings.values.statsShowGPU
                onToggled: (v) => Settings.set("statsShowGPU", v)
            }
        }
        FormRow {
            label: "Network"
            FormToggle {
                checked: Settings.values.statsShowNetwork
                onToggled: (v) => Settings.set("statsShowNetwork", v)
            }
        }
        FormRow {
            label: "Disk"
            divider: false
            FormToggle {
                checked: Settings.values.statsShowDisk
                onToggled: (v) => Settings.set("statsShowDisk", v)
            }
        }
    }
}
