import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"
import "../components/lyrics.js" as Lyrics

// Focused harness for the lyrics surfaces: the side panel, the inline line
// under the artist (calendar mode) and the pinned strip under the closed notch.
// A stand-in lyric body keeps this runnable under plain `qml6`:
//   mkdir -p /tmp/opencode/preview
//   QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 dev/lyrics.qml
Window {
    id: stage
    width: 1200
    height: 720
    visible: true
    color: "#101014"

    AtollFonts {}

    // Stand-in for LyricsService: same shape, no lrclib behind it.
    QtObject {
        id: mock
        property var lines: Lyrics.parseLrc(
            "[00:00.00]\n" +
            "[00:12.30]Is this the real life?\n" +
            "[00:15.60]Is this just fantasy?\n" +
            "[00:19.10]\n" +
            "[00:25.40]Caught in a landslide\n" +
            "[00:29.20]No escape from reality\n" +
            "[00:34.00]Open your eyes\n" +
            "[00:37.80]Look up to the skies and see\n")
        property real duration: 210
        property string availability: "timed"
        property int currentIndex: 4
        property real sweepProgress: 0.45
        property string placeholder: "Show lyrics here"

        function pinnedSlots(context) {
            return Lyrics.pinnedSlots(lines, duration, currentIndex, context, 5);
        }
    }

    // Build a few lines directly for the pinned strip / row samples.
    readonly property var pinnedThree: Lyrics.pinnedSlots(mock.lines, mock.duration, 4, 3, 5)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            spacing: 16

            // Inline lyric under the artist (calendar sharing the row).
            Item {
                Layout.preferredWidth: 420
                Layout.preferredHeight: 180
                Rectangle { anchors.fill: parent; color: "#17171c"; radius: 10 }
                MediaWidget {
                    anchors.fill: parent
                    anchors.margins: 8
                    trackTitle: "Bohemian Rhapsody"
                    trackArtist: "Queen"
                    hasMedia: true
                    isPlaying: true
                    progress: 0.2
                    positionSeconds: 30
                    lengthSeconds: 210
                    showInlineLyric: true
                    inlineLyric: mock.lines[4].text
                }
            }

            // Side lyrics panel.
            Item {
                Layout.preferredWidth: 280
                Layout.preferredHeight: 180
                LyricsPanel {
                    anchors.fill: parent
                    lines: mock.lines
                    duration: mock.duration
                    availability: mock.availability
                    currentIndex: mock.currentIndex
                    sweepProgress: mock.sweepProgress
                    placeholder: mock.placeholder
                    highlightStyle: "sweep"
                    tint: Colors.accent
                }
            }
        }

        // Highlight styles side by side.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            color: "#17171c"
            radius: 10
            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 20
                Repeater {
                    model: ["sweep", "gradient", "solid"]
                    ColumnLayout {
                        required property string modelData
                        Layout.fillWidth: true
                        spacing: 6
                        Text {
                            text: modelData
                            color: "#8b949e"
                            font.pixelSize: 11
                        }
                        LyricLine {
                            Layout.fillWidth: true
                            text: "Caught in a landslide, no escape"
                            isCurrent: true
                            progress: 0.55
                            highlightStyle: parent.modelData
                            fontSize: 14
                            lineLimit: 2
                            tint: Colors.accent
                        }
                        LyricLine {
                            Layout.fillWidth: true
                            text: "No escape from reality"
                            isCurrent: false
                            highlightStyle: parent.modelData
                            fontSize: 14
                            lineLimit: 2
                        }
                    }
                }
            }
        }

        // Pinned strip, on the closed notch's black.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 90
            color: "#000000"
            radius: 24
            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                PinnedLyrics {
                    Layout.fillWidth: true
                    slots: stage.pinnedThree
                    sweepProgress: 0.4
                    highlightStyle: "sweep"
                    tint: Colors.accent
                }
            }
        }
    }

    Timer {
        interval: 1200
        running: true
        onTriggered: stage.contentItem.grabToImage(function (res) {
            res.saveToFile("/tmp/opencode/preview/lyrics.png");
            Qt.quit();
        })
    }
}
