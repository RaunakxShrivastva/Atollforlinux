import QtQuick
import QtQuick.Controls
import "../theme"
import "lyrics.js" as Lyrics

// The scrolling, swept lyrics list shared by the side panel and the pinned
// strip (SyncedLyricsList.swift). Rows are built once per lyrics set: a blank
// LRC marker long enough to count as an instrumental break becomes a note row.
ListView {
    id: root

    property var lines: []
    property real duration: 0
    property string availability: "unavailable"
    property int currentIndex: -1
    property real sweepProgress: 0
    property string placeholder: "Show lyrics here"

    property string highlightStyle: "sweep"
    property color sung: Colors.white
    property color unsung: "#a0a0a0"
    property color idle: Qt.rgba(1, 1, 1, 0.5)
    property color tint: Colors.accent
    property real fontSize: Atoll.lyricsListFontSize
    property real lineSpacing: Atoll.lyricsListLineSpacing
    property int lineLimit: Atoll.lyricsListLineLimit
    property real paddingH: Atoll.lyricsListPaddingH
    property real paddingV: Atoll.lyricsListPaddingV
    property bool userScroll: true

    readonly property var rows: Lyrics.buildRows(root.lines, root.duration, Atoll.instrumentalBreakThreshold)

    clip: true
    spacing: root.lineSpacing
    interactive: root.userScroll
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

    // A row's position in the list, or -1 when the index has no row of its own.
    function rowFor(index) {
        for (var i = 0; i < root.rows.length; i++) {
            if (root.rows[i].index === index) return i;
        }
        return -1;
    }

    function followCurrent(animated) {
        if (root.rows.length === 0) return;
        var target = root.rowFor(root.currentIndex);
        // Before the first line (index -1) rewind to the top; mid-track a
        // missing row means staying where the words still read true.
        if (target < 0) target = root.currentIndex < 0 ? 0 : -1;
        if (target >= 0) root.positionViewAtIndex(target, ListView.Center);
    }

    onCurrentIndexChanged: root.followCurrent(true)
    onRowsChanged: Qt.callLater(() => root.followCurrent(false))
    onCountChanged: Qt.callLater(() => root.followCurrent(false))

    model: root.rows

    delegate: Item {
        id: rowItem
        required property var modelData
        width: ListView.view.width
        implicitHeight: modelData.instrumental
            ? (Atoll.lyricsListInstrumentalFontSize + 6)
            : lineItem.implicitHeight

        LyricLine {
            id: lineItem
            visible: !rowItem.modelData.instrumental
            width: parent.width - root.paddingH * 2
            x: root.paddingH
            text: rowItem.modelData.text
            isCurrent: rowItem.modelData.index === root.currentIndex
            progress: root.sweepProgress
            highlightStyle: root.highlightStyle
            sung: root.sung
            unsung: root.unsung
            idle: root.idle
            tint: root.tint
            fontSize: root.fontSize
            lineLimit: root.lineLimit
        }

        Row {
            visible: rowItem.modelData.instrumental
            x: root.paddingH
            spacing: 4
            opacity: rowItem.modelData.index === root.currentIndex ? 1 : 0.5

            Repeater {
                model: 3
                SvgIcon {
                    iconName: "music.note"
                    color: root.sung
                    implicitWidth: Atoll.lyricsListInstrumentalFontSize
                    implicitHeight: Atoll.lyricsListInstrumentalFontSize
                    opacity: rowItem.modelData.index === root.currentIndex
                        ? (index / 3 < root.sweepProgress ? 1 : 0.55)
                        : 0.5
                }
            }
        }
    }

    // Shown while loading, when nothing was found, or for a track with no words.
    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.paddingH
        anchors.rightMargin: root.paddingH
        anchors.topMargin: root.paddingV + 4
        visible: root.rows.length === 0
        text: root.placeholder
        color: root.idle
        font.family: Typography.family
        font.pixelSize: root.fontSize
        font.weight: Typography.medium
        wrapMode: Text.WordWrap
        renderType: Text.QtRendering
    }
}
