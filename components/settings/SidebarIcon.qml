import QtQuick
import "../../theme"

// macOS settings sidebar icon: a 26x26 gradient rounded square with a glyph.
Item {
    id: si
    property string icon: ""
    property color tint: Colors.accent
    implicitWidth: 26
    implicitHeight: 26
    width: 26
    height: 26

    Rectangle {
        anchors.fill: parent
        radius: 7
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(si.tint, 1.18) }
            GradientStop { position: 1.0; color: Qt.darker(si.tint, 1.08) }
        }
        border.color: Qt.rgba(1, 1, 1, 0.22)
        border.width: 1
    }
    Text {
        anchors.centerIn: parent
        text: Icons.glyph(si.icon)
        color: "white"
        font.family: Typography.iconFamily
        font.pixelSize: 15
    }
}
