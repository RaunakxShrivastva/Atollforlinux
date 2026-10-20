import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

// Full-screen colour picker, ported from the behaviour of macOS' Digital Color
// Meter / `hyprpicker`: the whole screen freezes, a loupe follows the pointer
// showing the pixel grid and its hex, and a click copies the colour.
//
// KWin has no zwlr-screencopy_v1, so hyprpicker cannot run here. The service
// grabs one full-screen frame with Spectacle and this window samples that frame
// (with ImageMagick) as the pointer moves - the screen is static while picking.
PanelWindow {
    id: win

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    visible: ColorPickerService.overlayVisible

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "atoll-colorpick"
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: win.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // The frozen frame fills the screen. Stretching is exact because the grab
    // has the same aspect ratio as the output.
    Image {
        id: shot
        anchors.fill: parent
        source: ColorPickerService.shotUrl
        fillMode: Image.Stretch
        smooth: false
        cache: false
        asynchronous: false

    }

    function imagePixel(mx, my) {
        var sw = shot.sourceSize.width;
        var sh = shot.sourceSize.height;
        if (!sw || !sh)
            return [0, 0];
        return [Math.max(0, Math.min(sw - 1, Math.floor(mx * sw / win.width))),
                Math.max(0, Math.min(sh - 1, Math.floor(my * sh / win.height)))];
    }

    function sampleAt(mx, my) {
        var p = imagePixel(mx, my);
        cursorX = mx;
        cursorY = my;
        ColorPickerService.sampleAt(p[0], p[1]);
    }

    property real cursorX: width / 2
    property real cursorY: height / 2

    // Sample the middle of the screen once the window has been laid out.
    onVisibleChanged: if (visible) initialSample.restart()

    Timer {
        id: initialSample
        interval: 120
        onTriggered: win.sampleAt(win.width / 2, win.height / 2)
    }

    readonly property int loupeSize: 156
    readonly property int loupePixels: 15
    readonly property int cell: loupeSize / loupePixels

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.CrossCursor
        focus: true

        onPositionChanged: mouse => win.sampleAt(mouse.x, mouse.y)
        onEntered: win.sampleAt(mouseX, mouseY)
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                ColorPickerService.commitPick();
            else
                ColorPickerService.cancelPick();
        }
        Keys.onEscapePressed: ColorPickerService.cancelPick()
    }

    // Thin crosshair all the way across the frozen frame.
    Rectangle {
        x: 0
        y: Math.round(win.cursorY)
        width: win.width
        height: 1
        color: "#80ffffff"
        visible: win.visible
    }
    Rectangle {
        x: Math.round(win.cursorX)
        y: 0
        width: 1
        height: win.height
        color: "#80ffffff"
        visible: win.visible
    }

    // ---- Loupe ----
    Rectangle {
        id: loupe
        width: win.loupeSize
        height: win.loupeSize + 58
        radius: Metrics.r12
        color: Colors.panel
        border.width: 1
        border.color: Colors.hairlineStrong
        visible: win.visible
        x: Math.round(Math.min(win.width - width - 12,
                               Math.max(12, win.cursorX + 22)))
        y: Math.round(Math.min(win.height - height - 12,
                               Math.max(12, win.cursorY + 22)))

        Image {
            id: zoom
            x: 1
            y: 1
            width: win.loupeSize - 2
            height: win.loupeSize - 2
            source: ColorPickerService.shotUrl
            cache: false
            smooth: false
            fillMode: Image.Stretch
            sourceClipRect: {
                var p = win.imagePixel(win.cursorX, win.cursorY);
                var half = Math.floor(win.loupePixels / 2);
                return Qt.rect(p[0] - half, p[1] - half, win.loupePixels, win.loupePixels);
            }
        }

        // Pixel grid + the centre cell.
        Repeater {
            model: win.loupePixels + 1
            Rectangle {
                x: index * win.cell
                y: 1
                width: 1
                height: win.loupeSize - 2
                color: "#33000000"
            }
        }
        Repeater {
            model: win.loupePixels + 1
            Rectangle {
                x: 1
                y: index * win.cell
                width: win.loupeSize - 2
                height: 1
                color: "#33000000"
            }
        }
        Rectangle {
            x: 1 + Math.floor(win.loupePixels / 2) * win.cell
            y: 1 + Math.floor(win.loupePixels / 2) * win.cell
            width: win.cell
            height: win.cell
            color: "transparent"
            border.width: 2
            border.color: Colors.white
        }

        Row {
            anchors.top: zoom.bottom
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Rectangle {
                width: 18
                height: 18
                radius: 4
                color: ColorPickerService.hoverHex
                border.width: 1
                border.color: Colors.hairlineStrong
            }
            Column {
                spacing: 1
                Text {
                    text: ColorPickerService.hoverHex
                    color: Colors.textPrimary
                    font.family: Typography.familyMono
                    font.pixelSize: Typography.s13
                    font.weight: Typography.semibold
                }
                Text {
                    text: ColorPickerService.hoverRgb
                    color: Colors.textSecondary
                    font.family: Typography.familyMono
                    font.pixelSize: Typography.s10
                }
            }
        }
    }

    // ---- Hint ----
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        width: hint.implicitWidth + 28
        height: 34
        radius: 17
        color: "#cc0b0b0d"
        border.width: 1
        border.color: Colors.hairlineStrong
        visible: win.visible

        Text {
            id: hint
            anchors.centerIn: parent
            text: "Click to copy  ·  Esc to cancel"
            color: Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.s12
        }
    }
}
