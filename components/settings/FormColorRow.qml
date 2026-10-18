import QtQuick
import QtQuick.Controls
import "../../theme"

// Colour well with a swatch palette pop-up.
Row {
    id: cr
    property color value: "#0a84ff"
    property var palette: [
        "#0a84ff", "#5e5ce6", "#bf5af2", "#ff2d55", "#ff375f", "#ff9f0a",
        "#ffd60a", "#30d158", "#40c8e0", "#64d2ff", "#ffffff", "#8e8e93"
    ]
    // A string, not `color`: a QColor serializes into settings.json as an
    // object ({r,g,b,a,...}) that then fails to reparse as a hex string.
    signal selected(string value)

    Rectangle {
        id: well
        width: 46
        height: 26
        radius: 7
        color: cr.value
        border.color: Colors.hairlineStrong
        border.width: 1
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.visible ? popup.close() : popup.open()
        }

        Popup {
            id: popup
            y: well.height + 4
            padding: 8
            background: Rectangle {
                radius: 10
                color: "#1b1b1f"
                border.color: Colors.hairlineStrong
                border.width: 1
            }
            contentItem: Grid {
                columns: 6
                spacing: 6
                Repeater {
                    model: cr.palette
                    delegate: Rectangle {
                        required property var modelData
                        width: 24
                        height: 24
                        radius: 6
                        color: modelData
                        border.color: Colors.hairlineStrong
                        border.width: 1
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { cr.selected(String(modelData)); popup.close(); }
                        }
                    }
                }
            }
        }
    }
}
