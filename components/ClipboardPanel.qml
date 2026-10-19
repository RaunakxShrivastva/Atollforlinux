import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"

// Clipboard panel - the floating 380 x 480 window of the "Panel" display mode,
// ported from ClipboardPanel.swift / ClipboardPanelView.
//
// Search carries the header's identity (there is no separate title bar), then
// the sliding History|Favorites segmented control with the clear button on the
// same line, then one 52pt row per entry. The panel is a non-activating
// floating window in Atoll; here it is a layer-shell surface that stays above
// fullscreen windows (see ClipboardPanelWindow.qml). Window dragging
// (isMovableByWindowBackground) has no layer-shell equivalent.
Item {
    id: root

    property var service: null
    property string selectedTab: "history"
    property string searchText: ""

    signal closeRequested()
    signal pickRequested()

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

    implicitWidth: 380
    implicitHeight: 480

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: Colors.panel
        border.width: 1
        border.color: Colors.hairlineStrong

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // ---- Search + close ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: 9
                    color: searchInput.activeFocus ? Colors.fillActive
                         : (searchHover.containsMouse ? Colors.fill : Colors.fillSubtle)
                    border.width: 1
                    border.color: searchInput.activeFocus ? Colors.accent : "transparent"
                    Behavior on color { ColorAnimation { duration: Motion.instant } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        spacing: 7

                        SvgIcon {
                            Layout.alignment: Qt.AlignVCenter
                            iconName: "magnifyingglass"
                            size: 13
                            color: Colors.textSecondary
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: root.searchText
                            placeholderText: "Search clipboard"
                            color: Colors.white
                            placeholderTextColor: Colors.textTertiary
                            selectByMouse: true
                            font.family: Typography.family
                            font.pixelSize: Typography.s12
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
                            size: 12
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

                // NativeStyleCloseButton: a 13pt red disc with a white x.
                Item {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.centerIn: parent
                        width: closeHover.containsMouse ? 14.3 : 13
                        height: width
                        radius: width / 2
                        color: closeHover.containsMouse ? Qt.rgba(1, 0.27, 0.23, 0.8) : Colors.systemRed
                        Behavior on width { NumberAnimation { duration: Motion.instant } }

                        SvgIcon {
                            anchors.centerIn: parent
                            iconName: "xmark"
                            color: Colors.white
                            implicitWidth: 8
                            implicitHeight: 8
                        }
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            // ---- Tabs + clear ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ClipboardTabs {
                    segmented: true
                    selected: root.selectedTab
                    historyCount: root.service ? root.service.entries.length : 0
                    favoritesCount: root.service ? root.service.favorites.length : 0
                    onTabPicked: tab => root.selectedTab = tab
                }

                Item { Layout.fillWidth: true }

                Item {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        color: clearHover.containsMouse && root.canClear
                            ? Colors.fill : "transparent"
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }

                    SvgIcon {
                        anchors.centerIn: parent
                        iconName: "trash"
                        // Red only once you are actually on it.
                        color: clearHover.containsMouse && root.canClear
                            ? Colors.systemRed : Colors.textSecondary
                        opacity: root.canClear ? 1 : 0.35
                        implicitWidth: 14
                        implicitHeight: 14
                    }

                    MouseArea {
                        id: clearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.canClear
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.clearCurrentTab()
                    }
                }
            }

            // ---- Rows ----
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.rows.length > 0
                clip: true
                contentHeight: list.implicitHeight + 8
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Column {
                    id: list
                    y: 4
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.rows

                        delegate: ClipboardRow {
                            required property var modelData
                            width: list.width
                            item: modelData
                            pinned: root.selectedTab === "favorites"
                                    || (root.service !== null && root.service.isFavorite(modelData))
                            onCopyClicked: {
                                if (root.selectedTab === "favorites") root.service.pickFavorite(modelData.id);
                                else root.service.pick(modelData.id);
                                root.pickRequested();
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
                hasSearch: root.searchText.trim() !== ""
                isHistoryTab: root.selectedTab === "history"
            }
        }
    }

    onVisibleChanged: if (visible) searchInput.forceActiveFocus()
}
