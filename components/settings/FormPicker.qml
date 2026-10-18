import QtQuick
import QtQuick.Controls
import "../../theme"

// macOS pop-up button. options: [{ value, label }].
Row {
    id: p
    property var options: []
    property var value: undefined
    signal selected(var value)

    function labelFor(v) {
        for (var i = 0; i < options.length; i++)
            if (options[i].value === v) return options[i].label;
        return "";
    }

    Rectangle {
        id: box
        implicitWidth: Math.max(140, textItem.implicitWidth + 40)
        height: 28
        radius: 7
        color: mouse.containsMouse ? Colors.fillHover : Colors.fill
        border.color: Colors.hairline
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            id: textItem
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: p.labelFor(p.value)
            color: Colors.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.s12
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "\u25BE"
            color: Colors.textSecondary
            font.pixelSize: 9
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.visible ? popup.close() : popup.open()
        }

        Popup {
            id: popup
            y: box.height + 4
            width: Math.max(box.width, 170)
            padding: 4
            background: Rectangle {
                radius: 9
                color: "#1b1b1f"
                border.color: Colors.hairlineStrong
                border.width: 1
            }
            contentItem: Column {
                spacing: 0
                Repeater {
                    model: p.options
                    delegate: Rectangle {
                        required property var modelData
                        width: popup.availableWidth
                        height: 30
                        radius: 6
                        color: optMouse.containsMouse ? Colors.fillHover
                             : (modelData.value === p.value ? Colors.fill : "transparent")
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.label
                            color: Colors.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.s12
                        }
                        MouseArea {
                            id: optMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { p.selected(modelData.value); popup.close(); }
                        }
                    }
                }
            }
        }
    }
}
