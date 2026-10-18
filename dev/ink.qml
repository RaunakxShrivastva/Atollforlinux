import QtQuick
import "../theme"
import "../components"

// Measures Material Symbols' ink height at a known font size so SvgIcon can
// compensate: SF Symbols render ~0.72 * pointSize of ink, Material Symbols
// leave more padding inside the em box, which is why same-size glyphs look
// smaller/"cheaper" than macOS.
Window {
    id: stage
    width: 1000
    height: 200
    visible: true
    color: "#000000"

    readonly property var probes: ["house.fill", "gearshape", "doc.on.clipboard", "timer", "play.fill"]

    Row {
        anchors.centerIn: parent
        spacing: 20
        Repeater {
            model: stage.probes
            delegate: Item {
                width: 180
                height: 180
                SvgIcon {
                    anchors.centerIn: parent
                    iconName: modelData
                    color: "white"
                    implicitWidth: 100
                    implicitHeight: 100
                    fontPixelOverride: 100
                }
            }
        }
    }

    Timer {
        interval: 1200; running: true
        onTriggered: stage.contentItem.grabToImage(function(res) {
            res.saveToFile("/tmp/opencode/preview/ink.png"); Qt.exit(0)
        })
    }
    Timer { interval: 8000; running: true; onTriggered: Qt.exit(2) }
}
