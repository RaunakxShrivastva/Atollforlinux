import QtQuick
import "../../theme"

// Read-only value shown at the trailing edge of a form row.
Row {
    id: l
    property string text: ""
    property bool monospace: false
    property color color: Colors.textSecondary

    Text {
        text: l.text
        color: l.color
        font.family: l.monospace ? Typography.familyMono : Typography.family
        font.pixelSize: Typography.s12
        anchors.verticalCenter: parent.verticalCenter
    }
}
