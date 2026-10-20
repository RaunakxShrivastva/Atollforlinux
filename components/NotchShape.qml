import QtQuick
import "../theme"

// Direct port of Atoll's `NotchShape` (DynamicIsland/components/Notch/NotchShape.swift).
// Four quad-curves join the top edge to the side walls (inset by topRadius) and
// the side walls to the bottom edge. Defaults 6 / 14 match NotchShape.swift;
// opened state uses top 19 / bottom 24 (cornerRadiusInsets.opened).
//
// Drawn with a per-corner Rectangle (Qt 6.7+) rather than QtQuick.Shapes: the
// CurveRenderer used to leave the silhouette blank on some drivers, which made
// the whole island look transparent while its icons stayed visible.
Rectangle {
    id: root

    property real topRadius: Atoll.notchClosedTopRadius
    property real bottomRadius: Atoll.notchClosedBottomRadius

    // Atoll fills the notch solid black.
    property color fillColor: Colors.black
    property bool gradientFill: false
    property color topColor: Colors.black
    property color bottomColor: Colors.black

    property color strokeColor: "transparent"
    property real strokeWidth: 0

    color: root.gradientFill ? "transparent" : root.fillColor
    topLeftRadius: root.topRadius
    topRightRadius: root.topRadius
    bottomLeftRadius: root.bottomRadius
    bottomRightRadius: root.bottomRadius
    border.color: root.strokeColor
    border.width: root.strokeWidth
    antialiasing: true
    gradient: root.gradientFill ? grad : null

    Gradient {
        id: grad
        GradientStop { position: 0.0; color: root.topColor }
        GradientStop { position: 1.0; color: root.bottomColor }
    }
}
