import QtQuick
import "../../theme"

// macOS-style switch, used as a row's control (Defaults.Toggle).
Row {
    id: t
    property bool checked: false
    property bool enabled: true
    signal toggled(bool value)

    opacity: enabled ? 1.0 : 0.45

    Rectangle {
        width: 40; height: 24; radius: 12
        color: t.checked ? Colors.accent : Qt.rgba(1, 1, 1, 0.18)
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 20; height: 20; radius: 10; y: 2
            x: t.checked ? 18 : 2
            color: "white"
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: t.enabled
            onClicked: t.toggled(!t.checked)
        }
    }
}
