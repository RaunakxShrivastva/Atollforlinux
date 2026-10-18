import QtQuick
import QtQuick.Layouts
import "../../theme"

// A grouped "Form" section: optional uppercase header, a rounded card holding
// the rows, and an optional caption footer (mirrors SwiftUI's
// Section { } header: { } footer: { }).
ColumnLayout {
    id: section
    property string title: ""
    property string footer: ""
    default property alias rows: inner.data

    spacing: 5

    Text {
        visible: section.title !== ""
        text: section.title
        color: Colors.textSecondary
        font.family: Typography.family
        font.pixelSize: Typography.s11
        font.weight: Typography.semibold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 0.6
        Layout.leftMargin: 6
        Layout.topMargin: 8
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: inner.implicitHeight
        radius: 10
        color: Qt.rgba(1, 1, 1, 0.045)
        border.color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 1

        ColumnLayout {
            id: inner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 0
        }
    }

    Text {
        visible: section.footer !== ""
        text: section.footer
        color: Colors.textTertiary
        font.family: Typography.family
        font.pixelSize: Typography.s11
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6
        Layout.bottomMargin: 2
    }
}
