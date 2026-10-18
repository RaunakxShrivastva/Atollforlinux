import QtQuick
import "../../theme"

// Capsule action button for a form row.
Row {
    id: br
    property string text: "Button"
    property bool prominent: false
    signal clicked()

    Rectangle {
        implicitWidth: label.implicitWidth + 30
        height: 28
        radius: 7
        color: br.prominent ? (bm.containsMouse ? Qt.lighter(Colors.accent, 1.1) : Colors.accent)
             : (bm.containsMouse ? Colors.fillHover : Colors.fill)
        border.color: br.prominent ? "transparent" : Colors.hairline
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            text: br.text
            color: "white"
            font.family: Typography.family
            font.pixelSize: Typography.s12
            font.weight: Typography.medium
        }
        MouseArea {
            id: bm
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: br.clicked()
        }
    }
}
