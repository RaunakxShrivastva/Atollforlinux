import QtQuick
import "../../theme"

// macOS-style slider with a trailing value label.
Row {
    id: s
    property real from: 0
    property real to: 100
    property real step: 1
    property real value: 0
    property string valueText: ""
    property int trackWidth: 170
    signal moved(real value)

    spacing: 10

    function commit(px) {
        var frac = Math.max(0, Math.min(1, px / track.width));
        var v = s.from + frac * (s.to - s.from);
        if (s.step > 0) v = Math.round(v / s.step) * s.step;
        v = Math.max(s.from, Math.min(s.to, v));
        if (v !== s.value) s.moved(v);
    }

    Rectangle {
        id: track
        width: s.trackWidth
        height: 4
        radius: 2
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.rgba(1, 1, 1, 0.18)

        Rectangle {
            width: Math.max(0, Math.min(track.width, (s.value - s.from) / Math.max(0.0001, s.to - s.from) * track.width))
            height: parent.height
            radius: 2
            color: Colors.accent
        }
        Rectangle {
            width: 16; height: 16; radius: 8
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(track.width - width,
                (s.value - s.from) / Math.max(0.0001, s.to - s.from) * track.width - width / 2))
        }
        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -10
            anchors.bottomMargin: -10
            cursorShape: Qt.PointingHandCursor
            onPressed: (m) => s.commit(m.x)
            onPositionChanged: (m) => { if (pressed) s.commit(m.x); }
        }
    }

    Text {
        visible: s.valueText !== ""
        text: s.valueText
        color: Colors.textSecondary
        font.family: Typography.family
        font.pixelSize: Typography.s12
        anchors.verticalCenter: parent.verticalCenter
    }
}
