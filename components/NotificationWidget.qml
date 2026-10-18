import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    anchors.fill: parent

    property string appName: "Notification"
    property string summary: ""
    property string body: ""
    property string appIcon: ""

    signal dismissClicked()

    readonly property bool hasNotification: summary !== "" || body !== ""

    // ---- Active notification row ----
    RowLayout {
        anchors.fill: parent
        anchors.margins: Metrics.padCard
        spacing: Metrics.gapL
        visible: root.hasNotification

        // App icon badge
        Rectangle {
            width: 44
            height: 44
            radius: Metrics.r12
            color: Colors.fill

            Image {
                anchors.fill: parent
                anchors.margins: 6
                source: root.appIcon
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: root.appIcon !== ""
            }
            SvgIcon {
                anchors.centerIn: parent
                visible: root.appIcon === ""
                iconName: "bell"
                color: Colors.accent
                implicitWidth: 22
                implicitHeight: 22
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: root.appName
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.s11
                    font.weight: Typography.semibold
                    textFormat: Text.PlainText
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "now"
                    color: Colors.textTertiary
                    font.family: Typography.family
                    font.pixelSize: Typography.s11
                }
            }

            Text {
                text: root.summary
                color: Colors.textPrimary
                font.family: Typography.familyDisplay
                font.pixelSize: Typography.s14
                font.weight: Typography.semibold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.body
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.s12
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                visible: text !== ""
            }
        }

        Rectangle {
            width: 26
            height: 26
            radius: 13
            color: closeMouse.containsMouse ? Colors.fill : "transparent"

            SvgIcon {
                anchors.centerIn: parent
                iconName: "close"
                color: Colors.textSecondary
                implicitWidth: 15
                implicitHeight: 15
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dismissClicked()
            }
        }
    }

    // ---- Empty state ----
    ColumnLayout {
        anchors.centerIn: parent
        spacing: Metrics.gapS
        visible: !root.hasNotification

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 44
            height: 44
            radius: Metrics.r12
            color: Colors.fill

            SvgIcon {
                anchors.centerIn: parent
                iconName: "bell"
                color: Colors.textTertiary
                implicitWidth: 22
                implicitHeight: 22
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "No New Notifications"
            color: Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.s13
            font.weight: Typography.medium
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "You're all caught up"
            color: Colors.textTertiary
            font.family: Typography.family
            font.pixelSize: Typography.s11
        }
    }
}
