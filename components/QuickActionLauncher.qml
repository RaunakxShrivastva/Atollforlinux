import QtQuick
import QtQuick.Layouts
import "../theme"

RowLayout {
    id: root

    signal launchColorPicker()
    signal launchScreenshot()
    signal launchTerminal()
    signal showMetrics()
    signal showTimer()
    signal launchEmoji()

    // Appearance > Desktop: labels under the tiles, and the emoji tile.
    property bool showLabels: false
    property bool showEmoji: false

    spacing: Metrics.gapM
    anchors.fill: parent
    anchors.margins: Metrics.padCard

    component Action: Rectangle {
        id: action
        property string icon: "tune"
        property string label: ""
        property color accent: Colors.accent
        signal activated()

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: Metrics.r12
        color: actionMouse.containsMouse ? Colors.fillHover : Colors.fillSubtle

        Behavior on color { ColorAnimation { duration: Motion.fast } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Metrics.gapS

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 40; height: 40; radius: 20
                color: Qt.rgba(action.accent.r, action.accent.g, action.accent.b, 0.18)
                SvgIcon {
                    anchors.centerIn: parent
                    iconName: action.icon
                    color: action.accent
                    implicitWidth: 20
                    implicitHeight: 20
                }
            }

            Text {
                visible: root.showLabels
                Layout.alignment: Qt.AlignHCenter
                text: action.label
                color: Colors.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.s12
                font.weight: Typography.medium
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.activated()
        }
    }

    Action {
        icon: "colorPicker"; label: "Colour"; accent: Colors.accent
        onActivated: root.launchColorPicker()
    }
    Action {
        icon: "screenshot"; label: "Capture"; accent: Colors.systemGreen
        onActivated: root.launchScreenshot()
    }
    Action {
        icon: "terminal"; label: "Terminal"; accent: Colors.systemPurple
        onActivated: root.launchTerminal()
    }
    Action {
        visible: root.showEmoji
        icon: "smiley"; label: "Emoji"; accent: Colors.systemYellow
        onActivated: root.launchEmoji()
    }
}
