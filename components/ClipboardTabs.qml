import QtQuick
import "../theme"

// History | Favorites selector, used by both clipboard surfaces.
//
// The panel shows Atoll's ClipboardSegmentedTabs (a selection pill that moves
// between two 24pt segments); the popover uses the plain ClipboardTabButton
// shape instead (a filled blue button with the count in a capsule).
Item {
    id: tabs

    property string selected: "history"      // "history" | "favorites"
    property int historyCount: 0
    property int favoritesCount: 0
    property bool segmented: true

    signal tabPicked(string tab)

    readonly property var model: [
        { key: "history", label: "History", icon: "clock", count: tabs.historyCount },
        { key: "favorites", label: "Favorites", icon: "heart.fill", count: tabs.favoritesCount }
    ]

    implicitWidth: row.implicitWidth + (tabs.segmented ? 4 : 0)
    implicitHeight: 28

    // Segmented track behind both tabs.
    Rectangle {
        visible: tabs.segmented
        anchors.fill: parent
        radius: 9
        color: Colors.fillSubtle
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: tabs.segmented ? 2 : 0
        spacing: tabs.segmented ? 2 : 0
        height: 24

        Repeater {
            model: tabs.model

            delegate: Rectangle {
                id: button
                required property var modelData
                readonly property bool isSelected: tabs.selected === modelData.key

                width: inner.implicitWidth + (tabs.segmented ? 20 : 24)
                height: tabs.segmented ? 24 : 24
                radius: tabs.segmented ? 7 : 6
                color: button.isSelected
                    ? (tabs.segmented ? Colors.fillActive : Colors.accent)
                    : (mouse.containsMouse ? Colors.fillSubtle : "transparent")
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: Motion.instant } }

                Row {
                    id: inner
                    anchors.centerIn: parent
                    spacing: tabs.segmented ? 5 : 6

                    SvgIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: button.modelData.icon
                        color: button.isSelected ? Colors.white : Colors.textSecondary
                        implicitWidth: tabs.segmented ? 13 : 14
                        implicitHeight: tabs.segmented ? 13 : 14
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: button.modelData.label
                        color: button.isSelected ? Colors.white : Colors.textSecondary
                        font.family: Typography.family
                        font.pixelSize: tabs.segmented ? Typography.s11 : Typography.s11
                        font.weight: tabs.segmented ? Typography.medium : Typography.medium
                    }

                    // Count, hidden while the list is empty.
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: button.modelData.count > 0
                        implicitWidth: count.implicitWidth + (tabs.segmented ? 0 : 8)
                        implicitHeight: tabs.segmented ? count.implicitHeight : 14
                        radius: tabs.segmented ? 0 : 7
                        color: tabs.segmented
                            ? "transparent"
                            : (button.isSelected ? Colors.fillActive : Colors.fillSubtle)

                        Text {
                            id: count
                            anchors.centerIn: parent
                            text: button.modelData.count
                            color: tabs.segmented
                                ? (button.isSelected ? Colors.textSecondary : Colors.textSecondary)
                                : (button.isSelected ? Colors.white : Colors.textSecondary)
                            font.family: tabs.segmented ? Typography.familyRounded : Typography.family
                            font.pixelSize: tabs.segmented ? Typography.s9 : Typography.s9
                            font.weight: Typography.semibold
                        }
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tabs.tabPicked(button.modelData.key)
                }
            }
        }
    }
}
