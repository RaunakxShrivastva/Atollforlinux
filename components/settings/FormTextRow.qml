import QtQuick
import "../../theme"

// Editable text field for a form row.
Row {
    id: tr
    property string text: ""
    property string placeholder: ""
    property int fieldWidth: 190
    signal edited(string text)

    Rectangle {
        width: tr.fieldWidth
        height: 28
        radius: 7
        color: Colors.fill
        border.color: input.activeFocus ? Colors.accent : Colors.hairline
        border.width: 1

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            text: tr.text
            color: Colors.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.s12
            selectByMouse: true
            clip: true
            onTextEdited: tr.edited(text)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: tr.placeholder
                visible: input.text === ""
                color: Colors.textTertiary
                font: input.font
            }
        }
    }
}
