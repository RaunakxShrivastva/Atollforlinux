import QtQuick
import "../../theme"

// macOS segmented control. options: [{ value, label }].
Row {
    id: seg
    property var options: []
    property var value: undefined
    signal selected(var value)

    Rectangle {
        height: 28
        radius: 7
        color: Colors.fill
        border.color: Colors.hairline
        implicitWidth: segRow.implicitWidth + 6

        Row {
            id: segRow
            anchors.centerIn: parent
            spacing: 2
            Repeater {
                model: seg.options
                delegate: Rectangle {
                    required property var modelData
                    width: label.implicitWidth + 22
                    height: 22
                    radius: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: modelData.value === seg.value ? Colors.fillActive
                         : (sm.containsMouse ? Colors.fillSubtle : "transparent")
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: modelData.label
                        color: Colors.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.s12
                        font.weight: modelData.value === seg.value ? Typography.medium : Typography.regular
                    }
                    MouseArea {
                        id: sm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: seg.selected(modelData.value)
                    }
                }
            }
        }
    }
}
