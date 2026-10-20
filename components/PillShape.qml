import QtQuick
import "../theme"

// Port of Atoll's `DynamicIslandPillShape` (closed shape, used in Dynamic
// Island mode on displays without a physical notch): a rounded rectangle whose
// radius is clamped to half the smaller side, i.e. a true capsule when
// radius >= height/2. The radius animates between closed (16) and open (24).
//
// Per-corner Rectangle instead of QtQuick.Shapes (see NotchShape.qml).
Rectangle {
    id: root

    property real radius: Atoll.islandClosedRadius
    readonly property real resolvedRadius: Math.min(radius, Math.min(width, height) / 2)

    property color fillColor: Colors.black
    property bool gradientFill: false
    property color topColor: Colors.black
    property color bottomColor: Colors.black

    property color strokeColor: "transparent"
    property real strokeWidth: 0

    color: root.gradientFill ? "transparent" : root.fillColor
    topLeftRadius: root.resolvedRadius
    topRightRadius: root.resolvedRadius
    bottomLeftRadius: root.resolvedRadius
    bottomRightRadius: root.resolvedRadius
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
