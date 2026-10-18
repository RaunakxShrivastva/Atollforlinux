import QtQuick
import QtQuick.Shapes
import "../theme"

// Port of Atoll's `DynamicIslandPillShape` (closed shape, used in Dynamic
// Island mode on displays without a physical notch): a rounded rectangle whose
// radius is clamped to half the smaller side, i.e. a true capsule when
// radius >= height/2. The radius animates between closed (16) and open (24).
Shape {
    id: root

    property real radius: Atoll.islandClosedRadius
    readonly property real resolvedRadius: Math.min(radius, Math.min(width, height) / 2)

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
        fillColor: root.gradientFill ? "transparent" : root.fillColor
        fillGradient: root.gradientFill ? grad : null

        startX: root.resolvedRadius
        startY: 0
        PathLine { x: root.width - root.resolvedRadius; y: 0 }
        PathQuad { controlX: root.width; controlY: 0; x: root.width; y: root.resolvedRadius }
        PathLine { x: root.width; y: root.height - root.resolvedRadius }
        PathQuad { controlX: root.width; controlY: root.height; x: root.width - root.resolvedRadius; y: root.height }
        PathLine { x: root.resolvedRadius; y: root.height }
        PathQuad { controlX: 0; controlY: root.height; x: 0; y: root.height - root.resolvedRadius }
        PathLine { x: 0; y: root.resolvedRadius }
        PathQuad { controlX: 0; controlY: 0; x: root.resolvedRadius; y: 0 }
    }
}
