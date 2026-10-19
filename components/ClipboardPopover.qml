import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"

// Clipboard popover - the dropdown attached to the header's clipboard button in
// "Popover" display mode, ported from ClipboardPopover.swift (280 x 320).
//
// Header ("Clipboard" + clear), History/Favorites tabs, a search field, then
// one row per entry. Favorites rows pin/unpin, history rows pin, and every row
// copies on click - Atoll keeps the popover open after a copy so you can pick
// several.
//
// SwiftUI hands an attached .popover its own window, which can hang outside the
// notch; the island's Wayland input region is only the notch silhouette, so
// here the card is docked inside the notch's content area instead (the same
// call made for the colour-picker popover).
Item {
    id: root

    property var service: null
    property string selectedTab: "history"
    property string searchText: ""

    signal closeRequested()

    readonly property var source: root.selectedTab === "favorites"
        ? (root.service ? root.service.favorites : [])
        : (root.service ? root.service.entries : [])
    readonly property var rows: root.filter(root.source)
    readonly property bool canClear: root.source.length > 0

    function filter(list) {
        var q = root.searchText.trim().toLowerCase();
        var out = [];
        for (var i = 0; i < list.length; i++) {
            if (q === "") { out.push(list[i]); continue; }
            var p = String(list[i].preview || "").toLowerCase();
            var k = String(list[i].kind || "").toLowerCase();
            if (p.indexOf(q) >= 0 || k.indexOf(q) >= 0) out.push(list[i]);
        }
        return out;
    }

    function clearCurrentTab() {
        if (!root.service) return;
        if (root.selectedTab === "favorites") root.service.clearFavorites();
        else root.service.clear();
    }

    implicitWidth: 280
    implicitHeight: 320

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Colors.panel
        border.width: 1
        border.color: Colors.hairline

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ---- Header ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 14
                Layout.bottomMargin: 6
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    SvgIcon {
                        Layout.alignment: Qt.AlignVCenter
                        iconName: "doc.on.clipboard"
                        size: 15
                        color: Colors.white
                    }
                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: "Clipboard"
                        color: Colors.white
                        font.family: Typography.familyDisplay
                        font.pixelSize: Typography.s13
                        font.weight: Typography.semibold
                    }
                    Item { Layout.fillWidth: true }

                    // Atoll leaves this a flat red glyph, dimmed when the tab is
                    // already empty.
                    SvgIcon {
                        Layout.alignment: Qt.AlignVCenter
                        iconName: "trash"
                        size: 13
                        color: Colors.systemRed
                        opacity: root.canClear ? 1 : 0.35
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -5
                            enabled: root.canClear
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clearCurrentTab()
                        }
                    }
                }

                ClipboardTabs {
                    id: tabs
                    Layout.alignment: Qt.AlignLeft
                    segmented: false
                    selected: root.selectedTab
                    historyCount: root.service ? root.service.entries.length : 0
                    favoritesCount: root.service ? root.service.favorites.length : 0
                    onTabPicked: tab => root.selectedTab = tab
                }

                // Search
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: 5
                    color: searchInput.activeFocus ? Colors.fillActive
                         : (searchHover.containsMouse ? Colors.fill : Colors.fillSubtle)
                    border.width: 1
                    border.color: searchInput.activeFocus ? Colors.accent : "transparent"
                    Behavior on color { ColorAnimation { duration: Motion.instant } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        SvgIcon {
                            Layout.alignment: Qt.AlignVCenter
                            iconName: "magnifyingglass"
                            size: 12
                            color: Colors.textSecondary
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: root.searchText
                            placeholderText: "Search..."
                            color: Colors.white
                            placeholderTextColor: Colors.textTertiary
                            selectByMouse: true
                            font.family: Typography.family
                            font.pixelSize: Typography.s11
                            background: null
                            padding: 0
                            leftPadding: 0
                            rightPadding: 0
                            onTextChanged: root.searchText = text
                        }

                        SvgIcon {
                            Layout.alignment: Qt.AlignVCenter
                            visible: root.searchText !== ""
                            iconName: "xmark.circle.fill"
                            size: 11
                            color: Colors.textSecondary
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.searchText = ""
                            }
                        }
                    }

                    MouseArea {
                        id: searchHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.IBeamCursor
                        onClicked: searchInput.forceActiveFocus()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Colors.hairline
            }

            // ---- Rows ----
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.rows.length > 0
                clip: true
                contentHeight: list.implicitHeight + 16
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: list
                    x: 8
                    y: 8
                    width: parent.width - 16
                    spacing: 1

                    Repeater {
                        model: root.rows

                        delegate: ClipboardRow {
                            required property var modelData
                            width: list.width
                            popover: true
                            item: modelData
                            pinned: root.selectedTab === "favorites"
                                    || (root.service !== null && root.service.isFavorite(modelData))
                            onCopyClicked: {
                                if (root.selectedTab === "favorites") root.service.pickFavorite(modelData.id);
                                else root.service.pick(modelData.id);
                            }
                            onPinClicked: {
                                if (root.selectedTab === "favorites") root.service.unpin(modelData.id);
                                else root.service.pin(modelData.id);
                            }
                            onDeleteClicked: {
                                if (root.selectedTab === "favorites") root.service.unpin(modelData.id);
                                else root.service.remove(modelData.id);
                            }
                        }
                    }
                }
            }

            ClipboardEmptyState {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.rows.length === 0
                popover: true
                hasSearch: root.searchText.trim() !== ""
                isHistoryTab: root.selectedTab === "history"
            }
        }
    }

    // Typing needs the keyboard; shell.qml hands the island surface the
    // keyboard back while this popover is open. The history is re-read so an
    // entry copied since the popover last closed is present.
    onVisibleChanged: if (visible) {
        if (root.service) {
            root.service.refresh();
            root.service.refreshFavorites();
        }
        searchInput.forceActiveFocus();
    }
}
