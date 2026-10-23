import QtQuick
import QtQuick.Layouts
import "../theme"

// Closed-state island.
//
// Idle:  clock + battery (DynamicIslandBatteryView).
// Media: album art + "Title • Artist" + waveform capsule, matching Atoll's
//        collapsed Now Playing strip (DynamicIslandSamples/media.png). The
//        clock/battery are hidden while a track is up, exactly as on macOS.
RowLayout {
    id: root

    property string clockTime: ""
    property bool isMediaPlaying: false
    property string artUrl: ""
    property int batteryLevel: 100
    property bool isCharging: false
    property string title: ""
    property string artist: ""
    property color tintColor: Colors.mediaAccent

    // Settings-driven presentation (General / Appearance).
    property bool minimalistic: false       // enableMinimalisticUI: art only
    property bool showBattery: true         // showBatteryIndicator
    property bool minimalBattery: false     // showMinimalisticBatteryIndicator
    property bool percentInside: false      // showBatteryPercentInside
    property bool visualizer: true          // useMusicVisualizer
    property int barCount: 4                // visualizerBarCount

    // Per-item closed-notch toggles (Media > "Closed notch").
    property bool showAlbumArt: true        // closedShowAlbumArt
    property bool showTrackTitle: true      // closedShowTrackTitle
    property bool showClock: true           // closedShowClock

    // Notification takeover: while one is active it replaces the media row
    // (Dynamic Island style) and the notch morphs to its content width.
    property bool notifActive: false
    property string notifApp: ""
    property string notifSummary: ""
    property string notifBody: ""
    property string notifIcon: ""
    signal notificationClicked()
    function notifRowWidth(): real { return notifRow.implicitWidth; }

    // Productivity > Timer with displayMode "liveActivity": the running
    // countdown takes over the closed pill.
    property bool timerActive: false
    property string timerText: ""

    // Idle aliveness: a very slow breath so a resting island still feels on.
    // Suppressed by Reduce motion and whenever something is actually happening.
    property bool reduceMotion: false
    property bool idleAlive: true
    property real idlePulse: 1.0
    SequentialAnimation on idlePulse {
        running: root.idleAlive && !root.reduceMotion
        loops: Animation.Infinite
        NumberAnimation { to: 0.86; duration: 1700; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 1700; easing.type: Easing.InOutSine }
    }

    readonly property bool showMedia: !root.timerActive
                                      && (isMediaPlaying || (title !== "" && title !== "Unknown Track"))
    // True when at least one media item is actually drawn on the pill. When
    // media plays but every per-item toggle (Media > "Closed notch") is off,
    // the pill falls back to the idle presentation (clock/battery) instead of
    // going blank -- the closed notch always shows something.
    readonly property bool mediaContentVisible: root.showMedia && !root.notifActive
        && (root.showAlbumArt
            || (root.showTrackTitle && !root.minimalistic)
            || (root.visualizer && !root.minimalistic))

    spacing: 10

    // 12-Hour Clock Timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            let hours = d.getHours();
            let minutes = d.getMinutes().toString().padStart(2, '0');
            hours = hours % 12;
            hours = hours ? hours : 12; // Convert 0 to 12
            root.clockTime = hours + ":" + minutes;
        }
    }

    property string cachedArtUrl: ""

    readonly property string formattedArtUrl: {
        if (!root.artUrl || root.artUrl === "") return "";
        let u = root.artUrl;
        if (u.startsWith("file://") || u.startsWith("http://") || u.startsWith("https://")) return u;
        if (u.startsWith("/")) return "file://" + u;
        return u;
    }

    onFormattedArtUrlChanged: {
        if (formattedArtUrl && formattedArtUrl !== "") {
            cachedArtUrl = formattedArtUrl;
        }
    }

    // ---- Media layout ----
    // Left: album thumbnail
    Rectangle {
        visible: root.showMedia && root.showAlbumArt && !root.notifActive
        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: 6
        implicitWidth: 19
        implicitHeight: 19
        radius: 5
        color: Colors.surfaceHover
        clip: true

        Image {
            id: artImage
            anchors.fill: parent
            source: root.formattedArtUrl !== "" ? root.formattedArtUrl : root.cachedArtUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: status === Image.Ready
        }

        SvgIcon {
            anchors.centerIn: parent
            visible: artImage.status !== Image.Ready
            iconName: "music.note"
            color: Colors.textSecondary
            implicitWidth: 12
            implicitHeight: 12
        }
    }

    // Center: "Title • Artist"
    Text {
        visible: root.showMedia && !root.minimalistic && root.showTrackTitle && !root.notifActive
        Layout.alignment: Qt.AlignVCenter
        Layout.maximumWidth: 196
        text: root.artist !== "" ? root.title + "  \u2022  " + root.artist : root.title
        color: Colors.textPrimary
        font.family: Typography.family
        font.pixelSize: Typography.s12
        font.weight: Typography.medium
        font.letterSpacing: Typography.trackTight
        elide: Text.ElideRight
        renderType: Text.QtRendering
    }

    // Right: waveform inside a translucent capsule (Atoll's AudioVisualizerView)
    Rectangle {
        visible: root.showMedia && !root.minimalistic && root.visualizer && !root.notifActive
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: 6
        implicitWidth: 30
        implicitHeight: 20
        radius: 6
        color: Qt.rgba(1, 1, 1, 0.14)

        Row {
            anchors.centerIn: parent
            spacing: 2.2

            Repeater {
                model: root.barCount
                Rectangle {
                    width: 2.4
                    height: root.isMediaPlaying ? (index % 2 === 0 ? 11 : 6) : 4
                    radius: 1.2
                    color: Colors.white
                    opacity: root.isMediaPlaying ? 1.0 : 0.5

                    Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

                    Timer {
                        interval: 140 + (index * 55)
                        running: root.isMediaPlaying && !root.reduceMotion
                        repeat: true
                        onTriggered: parent.height = Math.floor(Math.random() * 9) + 4
                    }
                }
            }
        }
    }

    // Notification takeover row (Media > "Closed notch" > notifications on).
    // Replaces the media strip while a notification is live; the notch width
    // follows this row's implicit width (NotchContainer binds to it).
    Item {
        id: notifRow
        visible: root.notifActive
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: notifInner.implicitWidth
        implicitHeight: notifInner.implicitHeight

        RowLayout {
            id: notifInner
            anchors.fill: parent
            spacing: 8

            // App icon badge, like the album thumbnail's shape language.
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 19
                implicitHeight: 19
                radius: 5
                color: Colors.surfaceHover
                clip: true

                Image {
                    id: notifIconImg
                    anchors.fill: parent
                    anchors.margins: 3
                    source: root.notifIcon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                }
                SvgIcon {
                    anchors.centerIn: parent
                    visible: notifIconImg.status !== Image.Ready
                    iconName: "bell"
                    color: Colors.textSecondary
                    implicitWidth: 12
                    implicitHeight: 12
                }
            }

            // App name over summary, both single-line elided; body trails the
            // summary when there is no app name to lead with. ColumnLayout +
            // Layout.fillWidth (not Column + width: parent.width) so the
            // implicit width flows out to the notch without a binding loop.
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: 240
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: root.notifApp
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.s10
                    font.weight: Typography.medium
                    font.letterSpacing: Typography.trackTight
                    elide: Text.ElideRight
                    renderType: Text.QtRendering
                }
                Text {
                    Layout.fillWidth: true
                    text: root.notifBody !== ""
                        ? root.notifSummary + "  \u2022  " + root.notifBody
                        : root.notifSummary
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.s12
                    font.weight: Typography.semibold
                    font.letterSpacing: Typography.trackTight
                    elide: Text.ElideRight
                    renderType: Text.QtRendering
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.notificationClicked()
        }
    }

    // Center: 12-Hour Clock Readout (idle state only)
    Text {
        // The explicit "Show clock" toggle (Media > Closed notch) is the
        // single source of truth; minimalistic no longer hides it. Hidden
        // only while something else owns the pill (media content, timer,
        // notification takeover).
        visible: root.showClock && !root.mediaContentVisible && !root.notifActive
                 && !root.timerActive
        opacity: root.idlePulse
        text: root.clockTime
        color: Colors.textPrimary
        font.family: Typography.family
        font.pixelSize: Typography.s13
        font.weight: Typography.semibold
        font.letterSpacing: Typography.trackTight
        renderType: Text.QtRendering
        Layout.alignment: Qt.AlignVCenter
    }

    // Center: live timer (takes over the pill while a timer runs)
    RowLayout {
        visible: root.timerActive && !root.notifActive
        Layout.alignment: Qt.AlignVCenter
        spacing: 6

        SvgIcon {
            Layout.alignment: Qt.AlignVCenter
            iconName: "timer"
            color: Colors.systemAccent
            implicitWidth: 14
            implicitHeight: 14
        }
        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.timerText
            color: Colors.textPrimary
            font.family: Typography.family
            font.pixelSize: Typography.s13
            font.weight: Typography.semibold
            font.letterSpacing: Typography.trackTight
            renderType: Text.QtRendering
        }
    }

    // Right Component: Battery Level & Charging Indicator (idle state only --
    // the collapsed media strip on macOS carries no clock/battery).
    RowLayout {
        // Show battery is the master switch for the closed pill; the
        // minimalistic-mode switch (Live Activities) only matters when
        // minimalistic hides everything else, and a notification takeover
        // always owns the pill alone.
        visible: root.showBattery && !root.mediaContentVisible && !root.timerActive
                 && !root.notifActive
                 && (!root.minimalistic || root.minimalBattery || root.showMedia)
                 && (!root.minimalistic || root.minimalBattery)
        opacity: root.idlePulse
        spacing: 4
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: 6

        // Battery Pill Graphic
        Rectangle {
            id: batteryBody
            width: root.percentInside ? 27 : 20
            height: root.percentInside ? 13 : 10
            radius: root.percentInside ? 3.5 : 3
            color: "transparent"
            border.color: root.isCharging ? Colors.systemAccent : (root.batteryLevel <= 20 ? Colors.error : Colors.textSecondary)
            border.width: 1

            readonly property color fillColor: root.isCharging ? Colors.systemAccent
                                                : (root.batteryLevel <= 20 ? Colors.error : Colors.textPrimary)
            // Luminance of the fill, so the reading stays legible over it.
            readonly property bool fillIsLight: (0.2126 * fillColor.r + 0.7152 * fillColor.g + 0.0722 * fillColor.b) > 0.55

            // Inner Battery Liquid Fill
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1.5
                width: Math.max(2, (batteryBody.width - 3) * (root.batteryLevel / 100.0))
                radius: 1.5
                color: batteryBody.fillColor
            }

            // Percentage printed inside the battery body. The fill only reaches
            // part-way, so the digits straddle the fill and the dark background:
            // an outline in the opposite colour keeps every digit legible.
            Text {
                visible: root.percentInside
                anchors.centerIn: parent
                text: String(root.batteryLevel)
                color: batteryBody.fillIsLight ? "#000000" : Colors.white
                style: Text.Outline
                styleColor: batteryBody.fillIsLight ? Colors.white : "#000000"
                font.family: Typography.family
                font.bold: true
                font.pixelSize: 8
                renderType: Text.QtRendering
            }
        }

        // Battery Percentage Text (outside the body, unless "inside")
        Text {
            visible: !root.percentInside
            text: root.batteryLevel + "%"
            color: root.isCharging ? Colors.systemGreen : Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.s11
            font.weight: Typography.medium
            renderType: Text.QtRendering
        }
    }
}
