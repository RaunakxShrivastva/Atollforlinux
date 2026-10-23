import QtQuick
import QtQuick.Effects
import QtMultimedia
import "../theme"

// Live camera preview shown as a third column beside the player (NotchHomeView's
// cameraPreview / WebcamView). QtMultimedia's ffmpeg backend is used; the v4l2
// capture device comes from the host, which picks the first camera the media
// stack exposes (loopback devices such as a virtual camera are filtered out by
// Qt itself).
Item {
    id: root

    property var device: null
    property string shape: "rectangle"
    property bool active: true
    property bool cornerRadiusScaling: true

    readonly property bool cameraAvailable: root.device !== null && root.device !== undefined

    readonly property real cornerRadius: root.shape === "circle"
        ? Math.min(width, height) / 2
        : (root.cornerRadiusScaling ? Atoll.albumOpenRadius : 12)

    // The rounded frame doubling as the mask for the video texture.
    // MultiEffect only picks up texture-backed sources: without
    // layer.enabled the hidden Rectangle never renders, so the mask stays
    // empty and neither the 12px rounded rectangle nor the circle shape is
    // ever applied to the camera feed.
    Rectangle {
        id: frame
        anchors.fill: parent
        radius: root.cornerRadius
        color: Colors.panelElevated
        visible: false
        layer.enabled: true
    }

    CaptureSession {
        id: session
        camera: Camera {
            id: camera
            cameraDevice: root.device
            active: root.active && root.cameraAvailable && root.visible
        }
        videoOutput: videoOut
    }

    VideoOutput {
        id: videoOut
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    MultiEffect {
        anchors.fill: parent
        source: videoOut
        maskEnabled: true
        maskSource: frame
        visible: root.active && root.cameraAvailable
        // WebcamView mirrors the preview (scaleEffect(x: -1, y: 1)): a mirror
        // that shows you a reversed reflection is not a mirror.
        transform: Scale {
            origin.x: root.width / 2
            origin.y: root.height / 2
            xScale: -1
        }
    }

    // Placeholder while the device opens (or if the module cannot render it).
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Colors.panelElevated
        visible: !(root.active && root.cameraAvailable)
        SvgIcon {
            anchors.centerIn: parent
            iconName: "video.fill"
            color: Colors.textTertiary
            implicitWidth: 22
            implicitHeight: 22
        }
    }

    Text {
        anchors.centerIn: parent
        visible: camera.errorString !== ""
        text: camera.errorString
        color: Colors.textTertiary
        font.family: Typography.family
        font.pixelSize: Typography.s11
        width: root.width - 16
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }
}
