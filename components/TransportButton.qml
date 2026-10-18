import QtQuick
import "../theme"

// Ported from HoverButton.swift: a 30pt (40pt for the large play button) target
// with a grey capsule that fades in on hover. `active` tints the glyph (used by
// shuffle / repeat when they are engaged).
Item {
    id: b

    property string icon: ""
    property int box: Atoll.mediaTransportBox
    property int glyphSize: Atoll.mediaTransportGlyph
    property color glyphColor: "#ffffff"
    property bool active: false
    property color activeColor: Colors.accent
    signal clicked()

    implicitWidth: box
    implicitHeight: box
    width: box
    height: box

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: hover.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    SvgIcon {
        anchors.centerIn: parent
        iconName: b.icon
        color: b.active ? b.activeColor : b.glyphColor
        implicitWidth: b.glyphSize
        implicitHeight: b.glyphSize
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
