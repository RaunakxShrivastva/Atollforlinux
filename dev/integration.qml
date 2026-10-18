import QtQuick
import "components"

// Offline integration preview: renders the REAL NotchContainer (services and all)
// in both presentation modes and every tab, so geometry can be diffed against
// Atoll's numbers. Run with: quickshell -p dev/integration.qml
Window {
    id: stage
    width: 1400
    height: 860
    visible: true
    color: "#141418"

    AtollFonts {}

    component Cell: Item {
        property string label: ""
        property string presentation: "island"
        property string mode: "EXPANDED"
        property string tab: "HOME"

        NotchContainer {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            presentation: parent.presentation
            mode: parent.mode
            activeTab: parent.tab
            shadowsEnabled: false
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: parent.label
            color: "#7d8590"
            font.family: "Inter"
            font.pixelSize: 12
        }
    }

    // ---- Island mode ----
    Cell { x: 30;  y: 20;  width: 300; height: 200; label: "island / compact";  presentation: "island"; mode: "COMPACT";  tab: "HOME" }
    Cell { x: 360; y: 20;  width: 430; height: 200; label: "island / HOME";     presentation: "island"; mode: "EXPANDED"; tab: "HOME" }
    Cell { x: 820; y: 20;  width: 430; height: 200; label: "island / STATS";    presentation: "island"; mode: "EXPANDED"; tab: "STATS" }
    Cell { x: 30;  y: 250; width: 430; height: 260; label: "island / TIMER";    presentation: "island"; mode: "EXPANDED"; tab: "TIMER" }
    Cell { x: 480; y: 250; width: 430; height: 260; label: "island / CLIPBOARD"; presentation: "island"; mode: "EXPANDED"; tab: "CLIPBOARD" }
    Cell { x: 930; y: 250; width: 430; height: 260; label: "island / SHELF";    presentation: "island"; mode: "EXPANDED"; tab: "SHELF" }

    // ---- Notch mode ----
    Cell { x: 30;  y: 540; width: 300; height: 200; label: "notch / compact";   presentation: "notch"; mode: "COMPACT";  tab: "HOME" }
    Cell { x: 360; y: 540; width: 660; height: 240; label: "notch / HOME";      presentation: "notch"; mode: "EXPANDED"; tab: "HOME" }

    Timer {
        interval: 9000; running: true; onTriggered: {
            stage.contentItem.grabToImage(function(res) {
                res.saveToFile("/tmp/opencode/preview/integration.png");
                console.log("SAVED integration.png");
                Qt.exit(0);
            });
        }
    }
    Timer { interval: 30000; running: true; onTriggered: { console.log("WATCHDOG"); Qt.exit(2); } }
}
