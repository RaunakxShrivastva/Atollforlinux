import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > CalendarSettings.
ColumnLayout {
    spacing: 12

    FormSection {
        Layout.fillWidth: true
        title: "Calendar"

        FormRow {
            label: "Show calendar"
            description: "Display the upcoming event in the notch."
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
        title: "Source"
        footer: "An iCalendar (.ics) file, as exported by khal, Thunderbird, Nextcloud or Google Calendar."

        FormRow {
            label: "Calendar file"
            description: Settings.calendarPath
            FormTextRow {
                text: Settings.values.calendarPath
                onEdited: (t) => Settings.set("calendarPath", t)
            }
        }
        FormRow {
            label: "Upcoming events shown"
            divider: false
            FormStepper {
                from: 1
                to: 12
                value: Settings.values.calendarUpcomingCount
                onChanged: (v) => Settings.set("calendarUpcomingCount", v)
            }
        }
    }
}
