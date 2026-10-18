// Offscreen harness for the Home/media player (MediaWidget).
//   QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 dev/media.qml
// MediaWidget only depends on the theme, so it renders without the Quickshell
// runtime (unlike the settings tabs).
import QtQuick
import "../theme"
import "../components"

Window {
    id: stage
    width: 640
    height: 260
    visible: true
    color: "#0a0a0c"

    AtollFonts {}

    Item {
        anchors.fill: parent
        anchors.margins: 16

        MediaWidget {
            width: 460
            height: 168
            trackTitle: "505"
            trackArtist: "Arctic Monkeys"
            artUrl: "file:///home/raunakxshrivastva/Pictures/Wallpapers/blue-abstract-3840x2160-25119.jpg"
            appIconSource: ""
            brandColor: "#1db954"
            tintArtist: true
            hasMedia: true
            isPlaying: true
            positionSeconds: 209
            lengthSeconds: 253
            progress: positionSeconds / lengthSeconds
            shuffleActive: true
            loopActive: true
            sliderColor: "#efe7d7"
        }
    }

    Timer {
        interval: 1800; running: true
        onTriggered: stage.contentItem.grabToImage(function(res) {
            res.saveToFile("/tmp/opencode/preview/media.png"); Qt.exit(0)
        })
    }
    Timer { interval: 9000; running: true; onTriggered: Qt.exit(2) }
}
