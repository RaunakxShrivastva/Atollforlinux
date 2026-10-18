import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../theme"
import "../components"

// Offline preview harness (not part of the running shell). Renders the notch in
// compact + expanded states on a mock desktop so visuals can be reviewed as a PNG
// without a compositor.
Window {
    id: stage
    width: 900
    height: 460
    visible: true
    color: "#101318"

    // mock wallpaper
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1b2735" }
            GradientStop { position: 0.45; color: "#2a3a4d" }
            GradientStop { position: 1.0; color: "#0e1116" }
        }
    }
    Rectangle { width: parent.width; height: 26; color: "#00000018" }

    // ---------- Compact ----------
    Item {
        id: compact
        x: 70; y: 0
        width: 300; height: 90

        NotchShape {
            id: compactShape
            anchors.horizontalCenter: parent.horizontalCenter
            width: 214; height: 36
            topRadius: Atoll.notchClosedTopRadius
            bottomRadius: Atoll.notchClosedBottomRadius
        }

        CompactPill {
            anchors.horizontalCenter: compactShape.horizontalCenter
            anchors.verticalCenter: compactShape.verticalCenter
            clockTime: "9:41"
            isMediaPlaying: true
            batteryLevel: 87
            isCharging: false
        }
    }

    // ---------- Expanded ----------
    Item {
        id: expanded
        x: 440; y: 0
        width: 420; height: 280

        NotchShape {
            id: expShape
            anchors.horizontalCenter: parent.horizontalCenter
            width: 384; height: 196
            topRadius: Atoll.notchOpenTopRadius
            bottomRadius: Atoll.notchOpenBottomRadius
        }

        MultiEffect {
            source: expShape
            anchors.fill: expShape
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.55
            shadowBlur: 0.9
            shadowVerticalOffset: 8
            blurMax: 40
        }

        ColumnLayout {
            anchors.horizontalCenter: expShape.horizontalCenter
            anchors.top: expShape.top
            width: expShape.width - 28
            height: expShape.height
            spacing: 2

            NotchHeaderBar {
                activeTab: "HOME"
                batteryLevel: 87
                isCharging: false
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                MediaWidget {
                    trackTitle: "Bohemian Rhapsody"
                    trackArtist: "Queen"
                    hasMedia: true
                    isPlaying: true
                    progress: 0.42
                    positionSeconds: 145
                    lengthSeconds: 354
                }
            }
        }
    }

    Timer {
        interval: 900; running: true; onTriggered: {
            stage.contentItem.grabToImage(function(res) {
                res.saveToFile("/tmp/opencode/preview/atoll.png");
                Qt.exit(0);
            });
        }
    }
    Timer { interval: 8000; running: true; onTriggered: { console.log("WATCHDOG"); Qt.exit(2); } }
}
