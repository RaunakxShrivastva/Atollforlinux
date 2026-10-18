import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../theme"

// Home tab media player, ported from NotchHomeView.swift
// (MusicPlayerView + AlbumArtView + MusicControlsView).
//
//   HStack(alignment: .top, spacing: 12) { AlbumArtView; MusicControlsView }
//
// Album art is 90x90 with a soft colour glow behind it while playing, an app
// badge on its bottom-trailing corner, and a dim overlay when paused. The
// controls column stacks title, artist, the timeline (elapsed left, duration
// right) and the transport row (shuffle, prev, play, next, repeat).
Item {
    id: root

    // ---- Playback ----
    property string trackTitle: "No Media Playing"
    property string trackArtist: ""
    property string artUrl: ""
    property bool isPlaying: false
    property bool hasMedia: false
    property real progress: 0.0
    property real positionSeconds: 0
    property real lengthSeconds: 0

    // ---- Transport state ----
    property bool shuffleActive: false
    property bool loopActive: false
    property bool loopOne: false

    // ---- Player branding ----
    property string appIconSource: ""
    property color brandColor: Colors.accent
    property bool tintArtist: false
    property color sliderColor: "#ffffff"

    // ---- Settings-driven presentation ----
    property bool lighting: true            // lightingEffect: colour glow behind art
    property real parallax: 6               // parallaxEffectIntensity
    property bool showShuffleRepeat: true   // showShuffleAndRepeat
    property bool showOutputControl: true   // showMediaOutputControl
    property bool showStandardControls: true// showStandardMediaControls
    property var slots: []                  // musicControlSlots (5 MusicControlButton names)
    property int controlSlots: 3            // legacy slot count (kept for callers)
    property bool reduceMotion: false       // Reduce motion: no parallax travel
    property bool waveformScrubber: true    // enableWaveformScrubber
    property string skipBehavior: "track"   // musicSkipBehavior

    signal playPauseClicked()
    signal nextClicked()
    signal seekBackClicked()
    signal seekForwardClicked()
    signal prevClicked()
    signal shuffleClicked()
    signal repeatClicked()
    signal artClicked()
    signal outputClicked()
    signal seekRequested(real fraction)

    property string cachedArtUrl: ""

    readonly property string formattedArtUrl: {
        if (!root.artUrl || root.artUrl === "") return "";
        let url = root.artUrl;
        if (url.startsWith("file://") || url.startsWith("http://") || url.startsWith("https://")) return url;
        if (url.startsWith("/")) return "file://" + url;
        return url;
    }

    onFormattedArtUrlChanged: {
        if (formattedArtUrl && formattedArtUrl !== "") cachedArtUrl = formattedArtUrl;
    }

    // Atoll's trailing label is the track duration (TrailingLabel.duration), not
    // a "-remaining" countdown.
    function formatTime(totalSec) {
        if (!totalSec || isNaN(totalSec) || totalSec <= 0) return "0:00";
        var mins = Math.floor(totalSec / 60);
        var secs = Math.floor(totalSec % 60);
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    readonly property string elapsedText: formatTime(positionSeconds)
    readonly property string durationText: formatTime(lengthSeconds)

    // avgColor.ensureMinimumBrightness(factor: 0.6) from NotchHomeView.
    function ensureBrightness(c, min) {
        var l = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
        if (l >= min) return c;
        var t = (min - l) / (1 - l);
        return Qt.rgba(c.r + (1 - c.r) * t, c.g + (1 - c.g) * t, c.b + (1 - c.b) * t, 1);
    }

    readonly property color artistColor: tintArtist
        ? ensureBrightness(brandColor, 0.66)
        : Colors.textSecondary

    anchors.fill: parent
    anchors.margins: 4

    RowLayout {
        anchors.fill: parent
        spacing: Atoll.mediaRowSpacing

        // ---- Album artwork ----
        Item {
            id: art

            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: Atoll.albumOpen
            Layout.preferredHeight: Atoll.albumOpen

            // albumArtBackground: the cover blurred behind itself, scaled 1.3x1.4
            // and faded in while playing.
            Image {
                id: glowSource
                anchors.centerIn: parent
                width: parent.width * Atoll.mediaGlowScaleX
                height: parent.height * Atoll.mediaGlowScaleY
                source: artImage.source
                fillMode: Image.PreserveAspectCrop
                visible: false
                layer.enabled: true
            }

            MultiEffect {
                source: glowSource
                anchors.fill: glowSource
                blurEnabled: true
                blur: 0.9
                blurMax: 48
                opacity: (root.isPlaying && root.hasMedia && root.lighting) ? Atoll.mediaGlowOpacity : 0.0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.InOutQuad } }
            }

            HoverHandler { id: artHover }

            Rectangle {
                id: artClip
                anchors.fill: parent
                radius: Atoll.albumOpenRadius
                // parallaxEffectIntensity: the cover drifts with the pointer.
                transform: Translate {
                    x: artHover.hovered && root.parallax > 0
                       ? (artHover.point.position.x / Math.max(1, art.width) - 0.5) * root.parallax * 2 : 0
                    y: artHover.hovered && root.parallax > 0
                       ? (artHover.point.position.y / Math.max(1, art.height) - 0.5) * root.parallax * 2 : 0
                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                }
                color: Colors.panelElevated
                border.color: Colors.hairline
                border.width: 1
                clip: true
                scale: root.isPlaying ? 1.0 : 0.85
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                Image {
                    id: artImage
                    anchors.fill: parent
                    source: root.formattedArtUrl !== "" ? root.formattedArtUrl : root.cachedArtUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: root.hasMedia && source !== "" && status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    visible: !artImage.visible
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#26262e" }
                        GradientStop { position: 1.0; color: "#141418" }
                    }
                    SvgIcon {
                        anchors.centerIn: parent
                        iconName: "music.note"
                        color: Colors.textTertiary
                        implicitWidth: 30
                        implicitHeight: 30
                    }
                }

                // albumArtDarkOverlay: dims the cover while paused.
                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: root.isPlaying ? 0.0 : 0.35
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                }
            }

            // appIconOverlay: the playing app's icon, 36x36, offset 10pt past the
            // art's bottom-trailing corner.
            Rectangle {
                id: badge
                width: Atoll.mediaBadge
                height: Atoll.mediaBadge
                radius: 9
                color: "#0b0b0d"
                border.color: Qt.rgba(1, 1, 1, 0.14)
                border.width: 1
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: -Atoll.mediaBadgeOffset
                anchors.bottomMargin: -Atoll.mediaBadgeOffset
                visible: root.hasMedia

                Image {
                    id: appIcon
                    anchors.fill: parent
                    anchors.margins: 2
                    source: root.appIconSource
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    visible: !appIcon.visible
                    color: Colors.panelElevated
                    SvgIcon {
                        anchors.centerIn: parent
                        iconName: "music.note"
                        color: root.brandColor
                        implicitWidth: 18
                        implicitHeight: 18
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.artClicked()
                }
            }

            MouseArea {
                anchors.fill: artClip
                cursorShape: Qt.PointingHandCursor
                onClicked: root.artClicked()
            }
        }

        // ---- Track info, timeline, transport ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: Atoll.mediaInfoTop
            Layout.leftMargin: Atoll.mediaInfoLeading
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.hasMedia ? (root.trackTitle || "Unknown Track") : "No Media Playing"
                color: Colors.textPrimary
                font.family: Typography.familyDisplay
                font.pixelSize: Typography.s18
                font.weight: Typography.semibold
                font.letterSpacing: Typography.trackTight
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.hasMedia ? (root.trackArtist || "") : ""
                color: root.artistColor
                font.family: Typography.family
                font.pixelSize: Typography.s16
                font.weight: Typography.medium
                elide: Text.ElideRight
            }

            Item { Layout.preferredHeight: 6 }

            // musicSlider (stacked): track, then the time labels 6pt below.
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Atoll.mediaSliderHeight
                Layout.topMargin: 4
                radius: Atoll.mediaSliderHeight / 2
                color: Qt.rgba(1, 1, 1, 0.22)

                Rectangle {
                    width: Math.max(0, Math.min(parent.width,
                        parent.width * Math.min(1.0, Math.max(0.0, root.progress))))
                    height: parent.height
                    radius: parent.radius
                    color: root.sliderColor
                }

                // enableWaveformScrubber: click/drag anywhere on the timeline to
                // seek (the bar grows while scrubbing, per CustomSlider).
                MouseArea {
                    id: scrub
                    anchors.fill: parent
                    anchors.topMargin: -6
                    anchors.bottomMargin: -6
                    enabled: root.waveformScrubber && root.hasMedia
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onPressed: mouse => root.seekRequested(Math.max(0, Math.min(1, mouse.x / width)))
                    onPositionChanged: mouse => {
                        if (pressed) root.seekRequested(Math.max(0, Math.min(1, mouse.x / width)));
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6

                Text {
                    text: root.elapsedText
                    color: Colors.textTertiary
                    font.family: Typography.family
                    font.pixelSize: Atoll.mediaTimeFontSize
                    font.weight: Typography.medium
                    font.letterSpacing: 0.2
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.durationText
                    color: Colors.textTertiary
                    font.family: Typography.family
                    font.pixelSize: Atoll.mediaTimeFontSize
                    font.weight: Typography.medium
                    font.letterSpacing: 0.2
                }
            }

            Item { Layout.preferredHeight: 6 }

            // playbackControls: HStack(spacing: 8) over the configured 5 slots
            // (MusicControlButton.defaultLayout = shuffle, trackBackward,
            // playPause, trackForward, repeatMode). With "Show shuffle and
            // repeat" off it falls back to the skip-behaviour layout.
            RowLayout {
                Layout.fillWidth: true
                spacing: Atoll.mediaTransportSpacing

                Item { Layout.fillWidth: true }

                Repeater {
                    model: root.effectiveSlots

                    delegate: TransportButton {
                        required property string modelData
                        readonly property string kind: modelData
                        visible: root.iconFor(kind) !== ""
                        icon: root.iconFor(kind)
                        box: kind === "playPause" ? Atoll.mediaPlayBox : Atoll.mediaTransportBox
                        glyphSize: kind === "playPause" ? Atoll.mediaPlayGlyph : Atoll.mediaTransportGlyph
                        active: kind === "shuffle" ? root.shuffleActive
                              : (kind === "repeatMode" ? root.loopActive : false)
                        activeColor: root.brandColor
                        onClicked: root.trigger(kind)
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    // ---- Transport slot model (MusicControlButton) ----
    readonly property var defaultSlots: ["shuffle", "trackBackward", "playPause", "trackForward", "repeatMode"]

    readonly property var effectiveSlots: {
        if (root.showShuffleRepeat && root.slots && root.slots.length === 5)
            return root.slots;
        if (root.skipBehavior === "seek")
            return ["none", "seekBackward", "playPause", "seekForward", "none"];
        return ["none", "trackBackward", "playPause", "trackForward", "none"];
    }

    function iconFor(kind) {
        switch (kind) {
            case "shuffle":       return "shuffle";
            case "trackBackward": return "backward.fill";
            case "playPause":     return root.isPlaying ? "pause.fill" : "play.fill";
            case "trackForward":  return "forward.fill";
            case "repeatMode":    return root.loopOne ? "repeat.1" : "repeat";
            case "mediaOutput":   return "hifispeaker";
            case "seekBackward":  return "gobackward.10";
            case "seekForward":   return "goforward.10";
            default:              return "";
        }
    }

    function trigger(kind) {
        switch (kind) {
            case "shuffle":       root.shuffleClicked(); break;
            case "trackBackward": root.prevClicked(); break;
            case "playPause":     root.playPauseClicked(); break;
            case "trackForward":  root.nextClicked(); break;
            case "repeatMode":    root.repeatClicked(); break;
            case "mediaOutput":   root.outputClicked(); break;
            case "seekBackward":  root.seekBackClicked(); break;
            case "seekForward":   root.seekForwardClicked(); break;
        }
    }
}
