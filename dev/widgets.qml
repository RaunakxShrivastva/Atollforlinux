import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

// Offline preview of the five content widgets for visual review.
Window {
    id: stage
    width: 1180
    height: 560
    visible: true
    color: "#0e1116"

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1b2735" }
            GradientStop { position: 1.0; color: "#0e1116" }
        }
    }

    component Frame: Rectangle {
        id: frame
        property string title: ""
        default property alias content: holder.data

        width: 372; height: 200
        radius: 20
        color: "#08080a"
        border.color: Colors.hairline
        border.width: 1

        Text {
            x: 12; y: -18
            text: frame.title
            color: Colors.textTertiary
            font.family: Typography.family
            font.pixelSize: 11
        }
        Item { id: holder; anchors.fill: parent }
    }

    Grid {
        x: 40; y: 50
        columns: 3
        spacing: 26

        Frame {
            title: "SystemWidget"
            SystemWidget { cpuUsage: 34; ramUsage: 61; ramUsedMb: 9800; ramTotalMb: 16000; batteryPercent: 87 }
        }
        Frame {
            title: "TimerWidget"
            TimerWidget { formattedTime: "24:18"; isRunning: true }
        }
        Frame {
            title: "CalendarWidget"
            height: 232
            CalendarWidget {}
        }
        Frame {
            title: "QuickActionLauncher"
            QuickActionLauncher {}
        }
        Frame {
            title: "NotificationWidget"
            NotificationWidget { appName: "Spotify"; summary: "Now Playing"; body: "Bohemian Rhapsody — Queen" }
        }
    }

    Timer { interval: 900; running: true; onTriggered: {
        stage.contentItem.grabToImage(function(res) { res.saveToFile("/tmp/opencode/preview/widgets.png"); Qt.exit(0); });
    }}
    Timer { interval: 8000; running: true; onTriggered: Qt.exit(2) }
}
