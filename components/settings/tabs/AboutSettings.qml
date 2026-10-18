import QtQuick
import QtQuick.Layouts
import "../../../theme"
import "../../../services"
import ".."

// Ported from SettingsView.swift > About.
ColumnLayout {
    spacing: 12

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: 6
        Layout.bottomMargin: 6
        spacing: 6

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 72
            height: 72
            radius: 18
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2a2a2e" }
                GradientStop { position: 1.0; color: "#0c0c0e" }
            }
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
            Text {
                anchors.centerIn: parent
                text: Icons.glyph("music.note")
                color: "white"
                font.family: Typography.iconFamily
                font.pixelSize: 34
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Atoll for Linux"
            color: Colors.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.s20
            font.weight: Typography.semibold
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "A dynamic island for your desktop"
            color: Colors.textTertiary
            font.family: Typography.family
            font.pixelSize: Typography.s12
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Info"

        FormRow {
            label: "Version"
            FormLabel { text: "1.0.0 (linux)" }
        }
        FormRow {
            label: "Based on"
            FormLabel { text: "Atoll by Ebullioscopic" }
        }
        FormRow {
            label: "Engine"
            FormLabel { text: "Quickshell 0.3.1 · Qt 6.11" }
        }
        FormRow {
            label: "Source"
            divider: false
            FormButtonRow { text: "GitHub" }
        }
    }

    FormSection {
        Layout.fillWidth: true
        title: "Reset"
        footer: "Restores every setting to its default value."

        FormRow {
            label: "Reset all settings"
            divider: false
            FormButtonRow {
                text: "Reset…"
                onClicked: Settings.reset()
            }
        }
    }
}
