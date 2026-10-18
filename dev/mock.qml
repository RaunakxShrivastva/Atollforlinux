import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

// Visual harness that composes the real components (shapes, header, widgets)
// with mock data, mirroring NotchContainer's layout, so geometry can be checked
// under plain `qml6` (Quickshell's grabToImage is unavailable in some sessions).
// Run: QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 dev/mock.qml
Window {
    id: stage
    width: 1420
    height: 1060
    visible: true
    color: "#141418"

    AtollFonts {}

    // Mock wallpaper: grabToImage does not capture Window.color, so an explicit
    // background is needed for the black islands to read.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1f2c3d" }
            GradientStop { position: 0.5; color: "#31465f" }
            GradientStop { position: 1.0; color: "#0e1116" }
        }
    }

    component Island: Item {
        id: isl
        property string presentation: "island"
        property string tab: "HOME"
        property bool expanded: true

        readonly property bool island: presentation !== "notch"
        readonly property real headerH: Atoll.headerButton + Atoll.headerPadding * 2
        readonly property real sideInset: island ? 0
            : (expanded ? Atoll.notchOpenTopRadius : Atoll.notchClosedTopRadius)
        // Mirror NotchContainer.openWidth: grow to fit the header strip.
        width: expanded
            ? Math.max(island ? Atoll.islandOpenWidth : Atoll.notchOpenWidth,
                       mockHeader.implicitWidth + Atoll.headerPadding * 2)
            : Atoll.closedWidth
        height: expanded
            ? Math.max(island ? Atoll.islandOpenHeight : Atoll.notchOpenHeight,
                       headerH + Atoll.tabContentHeight(tab) + Atoll.headerPadding)
            : Atoll.closedHeight

        NotchShape {
            anchors.fill: parent
            visible: !isl.island
            fillColor: Colors.black
            topRadius: isl.expanded ? Atoll.notchOpenTopRadius : Atoll.notchClosedTopRadius
            bottomRadius: isl.expanded ? Atoll.notchOpenBottomRadius : Atoll.notchClosedBottomRadius
        }
        PillShape {
            anchors.fill: parent
            visible: isl.island
            fillColor: Colors.black
            radius: isl.expanded ? Atoll.islandOpenRadius : Atoll.islandClosedRadius
        }

        Item {
            anchors.fill: parent
            anchors.leftMargin: isl.sideInset
            anchors.rightMargin: isl.sideInset
            clip: true

            CompactPill {
                visible: !isl.expanded
                anchors.centerIn: parent
                width: Math.min(implicitWidth, parent.width - 8)
                isMediaPlaying: true
                batteryLevel: 87
            }

            ColumnLayout {
                visible: isl.expanded
                anchors.fill: parent
                spacing: 0

                NotchHeaderBar {
                    id: mockHeader
                    presentation: isl.presentation
                    activeTab: isl.tab
                    batteryLevel: 87
                    Layout.topMargin: Atoll.headerPadding
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: Atoll.headerPadding

                    // Home = media beside the calendar, mirroring the explicit
                    // 58:42 split NotchContainer uses (NotchHomeView's HStack).
                    Item {
                        anchors.fill: parent
                        visible: isl.tab === "HOME"

                        Item {
                            id: mockMediaHost
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.round((parent.width - 12) * 0.58)

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
                        Item {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width - mockMediaHost.width - 12

                            CalendarWidget { events: []; expanded: true }
                        }
                    }
                    SystemWidget {
                        visible: isl.tab === "STATS"
                        cpuUsage: 34; ramUsage: 61; ramUsedMb: 9800; ramTotalMb: 16000; batteryPercent: 87
                        hasGpu: true; gpuUsage: 17
                        netDown: 46000; netUp: 12000
                        diskRead: 4640000; diskWrite: 0
                        cpuHistory: [22, 28, 25, 31, 34, 30, 36, 34, 33, 34]
                        memHistory: [58, 59, 60, 61, 61, 62, 60, 61, 61, 61]
                        gpuHistory: [10, 30, 15, 40, 20, 17, 25, 17, 12, 17]
                        netDownHistory: [0, 0, 2, 10, 0, 0, 5, 0, 0, 0]
                        netUpHistory: [0, 1, 0, 2, 0, 0, 1, 0, 0, 0]
                        diskReadHistory: [0, 0, 10, 0, 0, 44, 0, 0, 0, 0]
                        diskWriteHistory: [0, 0, 0, 5, 0, 0, 2, 0, 0, 0]
                    }
                    TimerWidget { visible: isl.tab === "TIMER"; formattedTime: "24:18"; isRunning: true }
                    NotificationWidget {
                        visible: isl.tab === "CLIPBOARD"
                        appName: "Spotify"; summary: "Now Playing"; body: "Bohemian Rhapsody — Queen"
                    }
                    QuickActionLauncher { visible: isl.tab === "SHELF" }
                }
            }
        }
    }

    component Slot: Item {
        property string label: ""
        property alias item: holder.data
        Item { id: holder; anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: parent.label
            color: "#7d8590"; font.family: "Inter"; font.pixelSize: 11
        }
    }

    // Row 1
    Island { x: 40;  y: 20; presentation: "island"; expanded: false; tab: "HOME" }
    Island { x: 220; y: 20; presentation: "island"; expanded: true;  tab: "HOME" }
    Island { x: 670; y: 20; presentation: "island"; expanded: true;  tab: "STATS" }
    // Row 2
    Island { x: 40;  y: 260; presentation: "island"; expanded: true; tab: "TIMER" }
    Island { x: 490; y: 260; presentation: "island"; expanded: true; tab: "CLIPBOARD" }
    Island { x: 940; y: 260; presentation: "island"; expanded: true; tab: "SHELF" }
    // Row 3 (notch mode)
    Island { x: 40;  y: 550; presentation: "notch"; expanded: false; tab: "HOME" }
    Island { x: 220; y: 550; presentation: "notch"; expanded: true;  tab: "HOME" }
    Island { x: 40;  y: 790; presentation: "notch"; expanded: true;  tab: "TIMER" }

    Timer {
        interval: 1600; running: true; onTriggered: {
            stage.contentItem.grabToImage(function(res) {
                res.saveToFile("/tmp/opencode/preview/mock.png");
                Qt.exit(0);
            });
        }
    }
    Timer { interval: 12000; running: true; onTriggered: Qt.exit(2) }
}
