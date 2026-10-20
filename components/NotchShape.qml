import QtQuick
import QtQuick.Shapes
import "../theme"

// Direct port of Atoll's `NotchShape` (DynamicIsland/components/Notch/NotchShape.swift).
// Four quad-curves join the top edge to the side walls (inset by topRadius) and
// the side walls to the bottom edge. Defaults 6 / 14 match NotchShape.swift;
// opened state uses top 19 / bottom 24 (cornerRadiusInsets.opened).
Shape {
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

    antialiasing: true
    preferredRendererType: Shape.CurveRenderer
    asynchronous: false

    LinearGradient {
        id: grad
        x1: 0; y1: 0
        x2: 0; y2: root.height
        GradientStop { position: 0.0; color: root.topColor }
        GradientStop { position: 1.0; color: root.bottomColor }
    }

    ShapePath {
        strokeColor: root.strokeColor
        strokeWidth: root.strokeWidth
        joinStyle: ShapePath.RoundJoin
        capStyle: ShapePath.RoundCap
        fillColor: root.gradientFill ? "transparent" : root.fillColor
        fillGradient: root.gradientFill ? grad : null

        startX: 0
        startY: 0

        // top-left
        PathQuad { controlX: root.topRadius; controlY: 0; x: root.topRadius; y: root.topRadius }
        // left wall
        PathLine { x: root.topRadius; y: root.height - root.bottomRadius }
        // bottom-left
        PathQuad { controlX: root.topRadius; controlY: root.height; x: root.topRadius + root.bottomRadius; y: root.height }
        // bottom edge
        PathLine { x: root.width - root.topRadius - root.bottomRadius; y: root.height }
        // bottom-right
        PathQuad { controlX: root.width - root.topRadius; controlY: root.height; x: root.width - root.topRadius; y: root.height - root.bottomRadius }
        // right wall
        PathLine { x: root.width - root.topRadius; y: root.topRadius }
        // top-right
        PathQuad { controlX: root.width - root.topRadius; controlY: 0; x: root.width; y: 0 }
        // top edge
        PathLine { x: 0; y: 0 }
    }
}
