import QtQuick
import "../theme"
import "../components"

// Offline fidelity harness for the header strip and the icon set.
// Renders the header at 1x and 2x (the macOS sample screenshots are retina)
// plus a sheet of every glyph we use, so the Material Symbols variable axes
// (FILL/GRAD/opsz/wght) can be eyeballed against SF Symbols.
Window {
    id: stage
    width: 1400
    height: 900
    visible: true
    color: "#0a0a0c"

    AtollFonts {}

    readonly property var iconSheet: [
        "house.fill", "tray.fill", "timer", "chart.xyaxis.line", "calendar",
        "doc.on.clipboard", "apple.terminal", "list.clipboard", "eyedropper",
        "gearshape", "shuffle", "backward.fill", "play.fill", "forward.fill",
        "repeat", "speaker.wave.2.fill", "sun.max.fill", "moon.fill",
        "lock.fill", "magnifyingglass", "plus", "checkmark", "xmark", "trash",
        "doc.on.doc", "waveform", "battery.100.bolt", "wifi", "cpu",
        "memorychip", "internaldrive", "square.and.arrow.down",
        "puzzlepiece.extension", "note.text", "keyboard", "info.circle.fill",
        "arrow.clockwise", "wand.and.stars", "pin.fill", "music.note"
    ]

    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 26

        // 1x on the island's real black surface
        Rectangle {
            width: 560
            height: 46
            color: "#000000"
            NotchHeaderBar {
                width: parent.width
                presentation: "island"
                activeTab: "HOME"
                batteryLevel: 65
                isCharging: false
            }
        }

        // 2x -- matches the scale of the macOS sample screenshots
        Rectangle {
            width: 560
            height: 96
            color: "#000000"
            NotchHeaderBar {
                width: 560
                presentation: "island"
                activeTab: "SHELF"
                batteryLevel: 33
                isCharging: true
                scale: 2.0
                transformOrigin: Item.TopLeft
            }
        }

        Grid {
            columns: 10
            columnSpacing: 22
            rowSpacing: 14
            Repeater {
                model: stage.iconSheet
                delegate: Column {
                    spacing: 3
                    SvgIcon {
                        iconName: modelData
                        color: "white"
                        implicitWidth: 30
                        implicitHeight: 30
                    }
                    Text {
                        text: String(modelData).replace(".fill", "")
                        color: "#8b93a7"
                        font.pixelSize: 9
                        font.family: Typography.family
                    }
                }
            }
        }
    }

    Timer {
        interval: 1500; running: true
        onTriggered: stage.contentItem.grabToImage(function(res) {
            res.saveToFile("/tmp/opencode/preview/header.png"); Qt.exit(0)
        })
    }
    Timer { interval: 9000; running: true; onTriggered: Qt.exit(2) }
}
