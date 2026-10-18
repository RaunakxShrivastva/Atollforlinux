import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > TimerSettings.
ColumnLayout {
    spacing: 12

    function fmt(seconds) {
        var m = Math.floor(seconds / 60);
        var s = seconds % 60;
        return m + ":" + (s < 10 ? "0" + s : "" + s);
    }

    FormSection {
        Layout.fillWidth: true
        title: "Timer"

        FormRow {
            label: "Enable timer"
            FormToggle {
                checked: Settings.values.enableTimerFeature
                onToggled: (v) => Settings.set("enableTimerFeature", v)
            }
        }
        FormRow {
            label: "Display mode"
            divider: false
            FormPicker {
                enabled: Settings.values.enableTimerFeature
                options: [
                    { value: "tab", label: "Dedicated tab" },
                    { value: "liveActivity", label: "Live activity" }
                ]
                value: Settings.values.timerDisplayMode
                onSelected: (v) => Settings.set("timerDisplayMode", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Presets"
        footer: "Long-press a preset in the notch to start it."

        Repeater {
            model: Settings.values.timerPresets
            delegate: FormRow {
                required property var modelData
                label: modelData.name
                FormLabel { text: fmt(modelData.duration) }
            }
        }
    }
}
