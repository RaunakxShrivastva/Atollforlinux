import QtQuick
import "../../theme"

// macOS stepper: [ - value + ].
Row {
    id: st
    property int value: 0
    property int from: 0
    property int to: 99
    property int step: 1
    signal changed(int value)

    Rectangle {
        width: 104
        height: 28
        radius: 7
        color: Colors.fill
        border.color: Colors.hairline

        Text {
            id: minus
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            horizontalAlignment: Text.AlignHCenter
            text: "\u2212"
            color: st.value <= st.from ? Colors.textTertiary : Colors.textPrimary
            font.pixelSize: Typography.s14
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { var v = Math.max(st.from, st.value - st.step); if (v !== st.value) st.changed(v); }
            }
        }
        Text {
            anchors.centerIn: parent
            text: st.value
            color: Colors.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.s12
        }
        Text {
            id: plus
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            horizontalAlignment: Text.AlignHCenter
            text: "+"
            color: st.value >= st.to ? Colors.textTertiary : Colors.textPrimary
            font.pixelSize: Typography.s14
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { var v = Math.min(st.to, st.value + st.step); if (v !== st.value) st.changed(v); }
            }
        }
    }
}
