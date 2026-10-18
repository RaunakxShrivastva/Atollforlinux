import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > LiveActivitiesSettings.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Live activities"

        FormRow {
            label: "System HUD"
            description: "Volume, brightness and backlight overlays."
            FormToggle {
                checked: Settings.values.enableHUD
                onToggled: (v) => Settings.set("enableHUD", v)
            }
        }
        FormRow {
            label: "Calendar"
            description: "Show the next event in the notch."
            FormToggle {
                checked: Settings.values.showCalendar
                onToggled: (v) => Settings.set("showCalendar", v)
            }
        }
        FormRow {
                    settingKey: "hideCompletedReminders"
            label: "Hide completed reminders"
            FormToggle {
                checked: Settings.values.hideCompletedReminders
                onToggled: (v) => Settings.set("hideCompletedReminders", v)
            }
        }
        FormRow {
                    settingKey: "hideAllDayEvents"
            label: "Hide all-day events"
            divider: false
            FormToggle {
                checked: Settings.values.hideAllDayEvents
                onToggled: (v) => Settings.set("hideAllDayEvents", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Indicators"

        FormRow {
            label: "Battery indicator"
            FormToggle {
                checked: Settings.values.showBatteryIndicator
                onToggled: (v) => Settings.set("showBatteryIndicator", v)
            }
        }
        FormRow {
            label: "Battery percentage inside"
            FormToggle {
                checked: Settings.values.showBatteryPercentInside
                onToggled: (v) => Settings.set("showBatteryPercentInside", v)
            }
        }
        FormRow {
            label: "Minimalistic battery indicator"
            divider: false
            FormToggle {
                checked: Settings.values.showMinimalisticBatteryIndicator
                onToggled: (v) => Settings.set("showMinimalisticBatteryIndicator", v)
            }
        }
    }
}
