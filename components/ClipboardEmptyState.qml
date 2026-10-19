import QtQuick
import QtQuick.Layouts
import "../theme"

// Empty / no-results state for both clipboard surfaces (Atoll has a panel and a
// popover variant that differ only in wording and icon).
Item {
    id: root

    property bool hasSearch: false
    property bool isHistoryTab: true
    property bool popover: false

    readonly property string glyph: root.hasSearch
        ? "magnifyingglass" : (root.isHistoryTab ? "doc.on.clipboard" : "heart.fill")

    readonly property string title: root.hasSearch
        ? "No results"
        : (root.isHistoryTab ? "No clipboard history" : "No favorites")

    readonly property string subtitle: root.hasSearch
        ? (root.popover ? "Try different search terms" : "Try a different search term")
        : (root.isHistoryTab
            ? (root.popover ? "Copy something to start" : "Copy something to get started")
            : (root.popover ? "Pin items to add favorites" : "Pin items to keep them here"))

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, implicitWidth)
        spacing: 0

        // Icon disc
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.popover ? 48 : 56
            Layout.preferredHeight: root.popover ? 48 : 56
            radius: width / 2
            color: Colors.fillSubtle

            SvgIcon {
                anchors.centerIn: parent
                iconName: root.glyph
                color: Colors.textSecondary
                implicitWidth: root.popover ? 20 : 22
                implicitHeight: root.popover ? 20 : 22
            }
        }

        Item { Layout.preferredHeight: 14 }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.title
            color: Colors.white
            font.family: Typography.familyDisplay
            font.pixelSize: root.popover ? Typography.s12 : Typography.s13
            font.weight: Typography.semibold
        }

        Item { Layout.preferredHeight: 3 }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            text: root.subtitle
            color: Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: root.popover ? Typography.s10 : Typography.s11
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
