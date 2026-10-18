import QtQuick
import QtQuick.Layouts
import "../theme"

ColumnLayout {
    id: root

    property string formattedTime: "25:00"
    property bool isRunning: false
    // Productivity > Timer: preset list + how the timer is presented
    // ("tab" = this view, "liveActivity" = countdown in the closed pill).
    property var presets: [
        { name: "Focus", duration: 1500, color: "#ff9f0a" },
        { name: "Break", duration: 300, color: "#30d158" },
        { name: "Deep Work", duration: 2700, color: "#bf5af2" }
    ]
    property string displayMode: "tab"

    function fmt(sec) {
        var m = Math.floor(sec / 60);
        var s = sec % 60;
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
    }

    signal startTimer(int seconds)
    signal startStopwatch()
    signal togglePause()
    signal resetTimer()

    spacing: Metrics.gapM
    anchors.fill: parent
    anchors.margins: Metrics.padCard

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: Metrics.gapS

        Rectangle {
            width: 26; height: 26; radius: 13
            color: Colors.atollOrange
            SvgIcon {
                anchors.centerIn: parent
                iconName: "timer"
                color: Colors.black
                implicitWidth: 15
                implicitHeight: 15
            }
        }

        ColumnLayout {
            spacing: 0
            Text {
                text: "Timer"
                color: Colors.textPrimary
                font.family: Typography.familyDisplay
                font.pixelSize: Typography.s14
                font.weight: Typography.semibold
            }
            Text {
                text: root.isRunning ? "Running" : "Paused"
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.s11
            }
        }

        Item { Layout.fillWidth: true }

        Text {
            text: root.formattedTime
            color: Colors.textPrimary
            font.family: Typography.familyMono
            font.pixelSize: Typography.s20
            font.weight: Typography.semibold
        }
    }

    // Controls
    RowLayout {
        Layout.fillWidth: true
        spacing: Metrics.gapS

        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: Metrics.r8
            color: pauseMouse.containsMouse ? Colors.fillHover : Colors.fill

            RowLayout {
                anchors.centerIn: parent
                spacing: Metrics.gapS
                SvgIcon { iconName: root.isRunning ? "pause" : "play"; color: Colors.textPrimary; implicitWidth: 13; implicitHeight: 13 }
                Text {
                    text: root.isRunning ? "Pause" : "Start"
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.s13
                    font.weight: Typography.semibold
                }
            }
            MouseArea { id: pauseMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.togglePause() }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: Metrics.r8
            color: stopMouse.containsMouse ? Qt.darker(Colors.accent, 1.15) : Colors.accent

            RowLayout {
                anchors.centerIn: parent
                spacing: Metrics.gapS
                SvgIcon { iconName: "close"; color: Colors.white; implicitWidth: 13; implicitHeight: 13 }
                Text {
                    text: "Stop"
                    color: Colors.white
                    font.family: Typography.family
                    font.pixelSize: Typography.s13
                    font.weight: Typography.semibold
                }
            }
            MouseArea { id: stopMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.resetTimer() }
        }
    }

    // Presets
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Metrics.gapXs

        Text {
            text: "Presets"
            color: Colors.textTertiary
            font.family: Typography.family
            font.pixelSize: Typography.s11
            font.weight: Typography.medium
        }

        component Preset: Rectangle {
            id: preset
            property string name: ""
            property string duration: ""
            property color dot: Colors.atollOrange
            property int seconds: 1500

            Layout.fillWidth: true
            height: 30
            radius: Metrics.r8
            color: presetMouse.containsMouse ? Colors.fill : Colors.fillSubtle

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.gapL
                anchors.rightMargin: Metrics.gapL
                spacing: Metrics.gapM

                Rectangle { width: 8; height: 8; radius: 4; color: preset.dot }
                Text {
                    text: preset.name
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.s13
                    font.weight: Typography.medium
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: preset.duration
                    color: Colors.textTertiary
                    font.family: Typography.familyMono
                    font.pixelSize: Typography.s11
                }
            }
            MouseArea {
                id: presetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.startTimer(preset.seconds)
            }
        }

        Repeater {
            model: root.presets
            delegate: Preset {
                required property var modelData
                name: modelData.name
                duration: root.fmt(Number(modelData.duration) || 0)
                dot: modelData.color ? modelData.color : Colors.atollOrange
                seconds: Number(modelData.duration) || 1500
            }
        }
    }
}
