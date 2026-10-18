import QtQuick
import "../theme"
import "../components"

Window {
    id: stage
    width: 900
    height: 420
    visible: true
    color: "#0a0a0c"

    AtollFonts {}

    Item {
      anchors.fill: parent
      anchors.margins: 20
      SystemWidget {
        cpuUsage: 34; ramUsage: 61; ramUsedMb: 9800; ramTotalMb: 16000; batteryPercent: 87
        hasGpu: true; gpuUsage: 17
        netDown: 46000; netUp: 12000
        diskRead: 4640000; diskWrite: 0
        cpuHistory: [22, 28, 25, 31, 34, 30, 36, 34, 33, 34]
        memHistory: [58, 59, 60, 61, 61, 62, 60, 61, 61, 61]
        gpuHistory: [10, 30, 15, 40, 20, 17, 25, 17, 12, 17]
        netDownHistory: [0, 0, 2, 10, 0, 0, 5, 0, 0, 0]
        netUpHistory: [0, 1, 0, 2, 0, 0, 1, 0, 0, 0]
        diskReadHistory: [0, 0, 10, 0, 0, 44, 0, 0, 0, 0]
        diskWriteHistory: [0, 0, 0, 5, 0, 0, 2, 0, 0, 0]
      }
    }

    Timer {
        interval: 1500; running: true
        onTriggered: stage.contentItem.grabToImage(function(res) {
            res.saveToFile("/tmp/opencode/preview/stats.png"); Qt.exit(0)
        })
    }
    Timer { interval: 9000; running: true; onTriggered: Qt.exit(2) }
}
