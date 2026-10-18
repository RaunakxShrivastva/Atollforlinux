import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > LockScreenSettings.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Widgets"

        FormRow {
                    settingKey: "enableLockScreenMediaWidget"
            label: "Media player"
            FormToggle {
                checked: Settings.values.enableLockScreenMediaWidget
                onToggled: (v) => Settings.set("enableLockScreenMediaWidget", v)
            }
        }
        FormRow {
                    settingKey: "enableLockScreenWeatherWidget"
            label: "Weather"
            FormToggle {
                checked: Settings.values.enableLockScreenWeatherWidget
                onToggled: (v) => Settings.set("enableLockScreenWeatherWidget", v)
            }
        }
        FormRow {
                    settingKey: "enableLockScreenFocusWidget"
            label: "Focus"
            FormToggle {
                checked: Settings.values.enableLockScreenFocusWidget
                onToggled: (v) => Settings.set("enableLockScreenFocusWidget", v)
            }
        }
        FormRow {
                    settingKey: "enableLockScreenReminderWidget"
            label: "Reminders"
            FormToggle {
                checked: Settings.values.enableLockScreenReminderWidget
                onToggled: (v) => Settings.set("enableLockScreenReminderWidget", v)
            }
        }
        FormRow {
                    settingKey: "enableLockScreenTimerWidget"
            label: "Timer"
            divider: false
            FormToggle {
                checked: Settings.values.enableLockScreenTimerWidget
                onToggled: (v) => Settings.set("enableLockScreenTimerWidget", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Weather"

        FormRow {
                    settingKey: "lockScreenWeatherShowsLocation"
            label: "Show location"
            FormToggle {
                checked: Settings.values.lockScreenWeatherShowsLocation
                onToggled: (v) => Settings.set("lockScreenWeatherShowsLocation", v)
            }
        }
        FormRow {
                    settingKey: "lockScreenWeatherShowsSunrise"
            label: "Show sunrise"
            FormToggle {
                checked: Settings.values.lockScreenWeatherShowsSunrise
                onToggled: (v) => Settings.set("lockScreenWeatherShowsSunrise", v)
            }
        }
        FormRow {
                    settingKey: "lockScreenWeatherShowsAQI"
            label: "Show air quality"
            FormToggle {
                checked: Settings.values.lockScreenWeatherShowsAQI
                onToggled: (v) => Settings.set("lockScreenWeatherShowsAQI", v)
            }
        }
        FormRow {
                    settingKey: "lockScreenWeatherTemperatureUnit"
            label: "Temperature unit"
            divider: false
            FormPicker {
                options: [
                    { value: "matchingSystem", label: "Match system" },
                    { value: "celsius", label: "Celsius" },
                    { value: "fahrenheit", label: "Fahrenheit" }
                ]
                value: Settings.values.lockScreenWeatherTemperatureUnit
                onSelected: (v) => Settings.set("lockScreenWeatherTemperatureUnit", v)
            }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Appearance"

        FormRow {
                    settingKey: "lockScreenWidgetAppearance"
            label: "Widget appearance"
            FormPicker {
                options: [
                    { value: "dark", label: "Dark" },
                    { value: "light", label: "Light" },
                    { value: "system", label: "System" }
                ]
                value: Settings.values.lockScreenWidgetAppearance
                onSelected: (v) => Settings.set("lockScreenWidgetAppearance", v)
            }
        }
        FormRow {
                    settingKey: "lockScreenGlassStyle"
            label: "Glass style"
            FormPicker {
                options: [
                    { value: "liquid", label: "Liquid" },
                    { value: "frosted", label: "Frosted" },
                    { value: "solid", label: "Solid" }
                ]
                value: Settings.values.lockScreenGlassStyle
                onSelected: (v) => Settings.set("lockScreenGlassStyle", v)
            }
        }
        FormRow {
                    settingKey: "lockScreenShowAppIcon"
            label: "Show app icon"
            FormToggle {
                checked: Settings.values.lockScreenShowAppIcon
                onToggled: (v) => Settings.set("lockScreenShowAppIcon", v)
            }
        }
        FormRow {
                    settingKey: "lockScreenPanelShowsBorder"
            label: "Panel border"
            FormToggle {
                checked: Settings.values.lockScreenPanelShowsBorder
                onToggled: (v) => Settings.set("lockScreenPanelShowsBorder", v)
            }
        }
        FormRow {
                    settingKey: "lockScreenPanelUsesBlur"
            label: "Panel blur"
            divider: false
            FormToggle {
                checked: Settings.values.lockScreenPanelUsesBlur
                onToggled: (v) => Settings.set("lockScreenPanelUsesBlur", v)
            }
        }
    }
}
