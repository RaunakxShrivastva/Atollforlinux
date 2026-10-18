import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

// Focused harness for the notch Home calendar (CalendarWidget), rendered in its
// expanded state so the date wheel and the selected-cell pill can be inspected
// offscreen. Run:
//   QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 dev/calendar.qml
Window {
    id: stage
    width: 760
    height: 260
    visible: true
    color: "#101014"

    AtollFonts {}

    Rectangle {
        x: 20; y: 20
        width: 400
        height: 150
        color: "#000000"
        radius: 16

        CalendarWidget {
            anchors.fill: parent
            anchors.margins: 8
            expanded: true
            events: [
                { summary: "Design review with the team", start: Date.now() + 3600000, allDay: false },
                { summary: "Ship the 2.3.0 build", start: Date.now() + 7200000, allDay: false }
            ]
        }
    }

    // Same widget, collapsed, to check the compact label.
    Rectangle {
        x: 440; y: 20
        width: 300
        height: 70
        color: "#000000"
        radius: 16

        CalendarWidget {
            anchors.fill: parent
            anchors.margins: 8
            events: []
        }
    }

    Timer {
        interval: 1200
        running: true
        onTriggered: stage.contentItem.grabToImage(function (res) {
            res.saveToFile("/tmp/opencode/preview/calendar.png");
            Qt.quit();
        })
    }
}
