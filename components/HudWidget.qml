import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../theme"

// The OSD that appears in the notch when the volume / brightness / keyboard
// backlight changes (Controls > System HUD). Three layouts, per Settings:
//   default  : icon + horizontal bar  (macOS style)
//   vertical : icon stacked over the bar
//   circular : a ring gauge around the icon
Item {
    id: root

    property string kind: "volume"      // volume | brightness | keyboard | battery | color
    property bool charging: false
    property string colorText: ""       // kind "color": the picked value
    property real value: 0.0            // 0..1
    property bool muted: false
    property bool vertical: false
    property bool circular: false
    property color tint: Colors.white

    readonly property string iconName: {
        if (kind === "battery") {
            if (charging) return "battery.100.bolt";
            if (value <= 0.1) return "battery.0";
            if (value <= 0.35) return "battery.25";
            if (value <= 0.6) return "battery.50";
            if (value <= 0.85) return "battery.75";
            return "battery.100";
        }
        if (kind === "brightness") return value > 0.66 ? "sun.max.fill" : (value > 0.33 ? "sun.max" : "sun.min");
        if (kind === "keyboard") return "keyboard";
        if (muted || value <= 0.001) return "speaker.slash.fill";
        if (value < 0.34) return "speaker.wave.1.fill";
        if (value < 0.67) return "speaker.wave.2.fill";
        return "speaker.wave.3.fill";
    }

    implicitWidth: kind === "color" ? 150 : (circular ? 34 : (vertical ? 84 : 118))
    implicitHeight: circular ? 34 : (vertical ? 44 : 24)

    // ---- Colour swatch (colour picker) ----
    RowLayout {
        visible: root.kind === "color"
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 8

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 18
            implicitHeight: 18
            radius: 5
            color: root.tint
            border.color: Qt.rgba(1, 1, 1, 0.35)
            border.width: 1
        }
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.colorText
            color: Colors.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.s12
            font.weight: Typography.semibold
            elide: Text.ElideRight
            renderType: Text.QtRendering
        }
    }

    // ---- Circular gauge ----
    Shape {
        anchors.centerIn: parent
        visible: root.circular
        width: 34
        height: 34
        layer.enabled: true
        ShapePath {
            strokeColor: Qt.rgba(1, 1, 1, 0.22)
            strokeWidth: 3
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: 17; centerY: 17; radiusX: 14; radiusY: 14
                startAngle: -90; sweepAngle: 360
            }
        }
        ShapePath {
            strokeColor: root.tint
            strokeWidth: 3
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: 17; centerY: 17; radiusX: 14; radiusY: 14
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(1, root.value))
            }
        }
    }

    SvgIcon {
        id: glyph
        anchors.centerIn: root.circular ? parent
                      : (root.vertical ? undefined : undefined)
        visible: root.circular
        iconName: root.iconName
        color: root.tint
        implicitWidth: 16
        implicitHeight: 16
    }

    // ---- Linear layouts ----
    RowLayout {
        visible: !root.circular && !root.vertical
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 8

        SvgIcon {
            Layout.alignment: Qt.AlignVCenter
            iconName: root.iconName
            color: root.tint
            implicitWidth: 17
            implicitHeight: 17
        }
        HudBar {
            Layout.fillWidth: true
            value: root.value
            tint: root.tint
        }
    }

    ColumnLayout {
        visible: root.vertical && !root.circular
        anchors.centerIn: parent
        width: parent.width
        spacing: 3

        SvgIcon {
            Layout.alignment: Qt.AlignHCenter
            iconName: root.iconName
            color: root.tint
            implicitWidth: 16
            implicitHeight: 16
        }
        HudBar {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 64
            value: root.value
            tint: root.tint
        }
    }

    component HudBar: Rectangle {
        id: bar
        property real value: 0.5
        property color tint: Colors.white
        implicitHeight: 7
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.22)

        Rectangle {
            width: Math.max(bar.height, bar.width * Math.max(0, Math.min(1, bar.value)))
            height: parent.height
            radius: parent.radius
            color: bar.tint
            Behavior on width { NumberAnimation { duration: Motion.instant; easing.type: Easing.OutCubic } }
        }
    }
}
