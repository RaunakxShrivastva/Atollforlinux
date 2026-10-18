import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > Charge (tab "battery").
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Battery"

        FormRow {
            label: "Show battery indicator"
            FormToggle {
                checked: Settings.values.showBatteryIndicator
                onToggled: (v) => Settings.set("showBatteryIndicator", v)
            }
        }
        FormRow {
            label: "Percentage inside the icon"
            FormToggle {
                checked: Settings.values.showBatteryPercentInside
                onToggled: (v) => Settings.set("showBatteryPercentInside", v)
            }
        }
        FormRow {
            label: "Power status notifications"
            divider: false
            FormToggle {
                checked: Settings.values.showPowerStatusNotifications
                onToggled: (v) => Settings.set("showPowerStatusNotifications", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Charging HUD"

        FormRow {
            label: "Charging"
            FormToggle {
                checked: Settings.values.showChargingBatteryHUD
                onToggled: (v) => Settings.set("showChargingBatteryHUD", v)
            }
        }
        FormRow {
            label: "Charging duration"
            FormStepper {
                value: Settings.values.chargingBatteryHUDDuration
                from: 1
                to: 10
                onChanged: (v) => Settings.set("chargingBatteryHUDDuration", v)
            }
        }
        FormRow {
            label: "Low battery"
            FormToggle {
                checked: Settings.values.showLowBatteryHUD
                onToggled: (v) => Settings.set("showLowBatteryHUD", v)
            }
        }
        FormRow {
            label: "Low battery duration"
            FormStepper {
                value: Settings.values.lowBatteryHUDDuration
                from: 1
                to: 20
                onChanged: (v) => Settings.set("lowBatteryHUDDuration", v)
            }
        }
        FormRow {
            label: "Fully charged"
            FormToggle {
                checked: Settings.values.showFullBatteryHUD
                onToggled: (v) => Settings.set("showFullBatteryHUD", v)
            }
        }
        FormRow {
            label: "Fully charged duration"
            divider: false
            FormStepper {
                value: Settings.values.fullBatteryHUDDuration
                from: 1
                to: 20
                onChanged: (v) => Settings.set("fullBatteryHUDDuration", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Caffeinate"
        footer: "Keep the machine awake using systemd-inhibit while enabled."

        FormRow {
            label: "Enable caffeinate"
            FormToggle {
                checked: Settings.values.enableCaffeinate
                onToggled: (v) => Settings.set("enableCaffeinate", v)
            }
        }
        FormRow {
            label: "Show icon in notch"
            FormToggle {
                enabled: Settings.values.enableCaffeinate
                checked: Settings.values.showCaffeinateIcon
                onToggled: (v) => Settings.set("showCaffeinateIcon", v)
            }
        }
        FormRow {
            label: "Default duration"
            FormPicker {
                enabled: Settings.values.enableCaffeinate
                options: [
                    { value: "indefinite", label: "Indefinitely" },
                    { value: "15m", label: "15 minutes" },
                    { value: "30m", label: "30 minutes" },
                    { value: "1h", label: "1 hour" },
                    { value: "2h", label: "2 hours" }
                ]
                value: Settings.values.caffeinateDefaultDuration
                onSelected: (v) => Settings.set("caffeinateDefaultDuration", v)
            }
        }
        FormRow {
            label: "Keep display awake"
            divider: false
            FormToggle {
                enabled: Settings.values.enableCaffeinate
                checked: Settings.values.caffeinateKeepsDisplayAwake
                onToggled: (v) => Settings.set("caffeinateKeepsDisplayAwake", v)
            }
        }
    }
}
