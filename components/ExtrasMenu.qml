import QtQuick
import QtQuick.Layouts
import "../theme"

// Atoll's extras menu (DynamicIslandExtrasMenu), raised by the header's "…"
// button: a row of large black tiles -- Hide (collapse), Settings, Exit.
RowLayout {
    id: root

    signal hideRequested()
    signal settingsRequested()
    signal exitRequested()

    spacing: 20

    component LargeTile: Rectangle {
        id: tile
        property string iconName: ""
        property string label: ""
        signal clicked()

        Layout.preferredWidth: 70
        Layout.preferredHeight: 70
        radius: 12
        color: tMouse.containsMouse || tMouse.pressed ? Colors.fillHover : Colors.black
        Behavior on color { ColorAnimation { duration: Motion.instant } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            SvgIcon {
                Layout.alignment: Qt.AlignHCenter
                iconName: tile.iconName
                color: Colors.white
                implicitWidth: 20
                implicitHeight: 20
                scale: tMouse.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: Motion.instant; easing.type: Easing.OutCubic } }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: tile.label
                color: Colors.white
                font.family: Typography.familyDisplay
                font.pixelSize: Typography.s13
            }
        }

        MouseArea {
            id: tMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }

    LargeTile {
        iconName: "arrow.down.forward.and.arrow.up.backward"
        label: "Hide"
        onClicked: root.hideRequested()
    }
    LargeTile {
        iconName: "gear"
        label: "Settings"
        onClicked: root.settingsRequested()
    }
    LargeTile {
        iconName: "xmark"
        label: "Exit"
        onClicked: root.exitRequested()
    }
}
