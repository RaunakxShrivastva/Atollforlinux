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
            FormToggle {
                checked: Settings.values.statsShowCPU
                onToggled: (v) => Settings.set("statsShowCPU", v)
            }
        }
        FormRow {
            label: "LLM Usage Monitor"
            divider: false
            description: "Adds a Usage tab tracking token spend across your configured AI providers"
            FormToggle {
                checked: Settings.values.enableLLMUsageFeature
                onToggled: (v) => Settings.set("enableLLMUsageFeature", v)
            }
        }
    }

    // Atoll shows this section only while the monitor is on.
    FormSection {
        Layout.fillWidth: true
        visible: Settings.llmUsageEnabled
        title: "LLM Providers"
        footer: "Choose which AI providers appear in the Usage tab. Claude and Codex "
                + "read their local usage logs; Cursor, Antigravity and New API need "
                + "macOS credentials or a configured endpoint, so they report why they "
                + "are unavailable instead of showing figures."

        Repeater {
            model: Settings.llmProviders
            delegate: FormRow {
                required property var modelData
                required property int index
                label: modelData.name
                divider: index < Settings.llmProviders.length - 1
                FormToggle {
                    checked: Settings.values[modelData.key] === true
                    onToggled: (v) => Settings.set(modelData.key, v)
                }
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
