import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"

// Clipboard pane (Utilities > Clipboard). Mirrors Atoll's NotchClipboardView:
// a "Clipboard" heading with a circular red trash button, then a grid of cards
// (thumbnail/type glyph, preview, "Text"/"Image" subtitle, relative age, and a
// hover-revealed delete button in the top-trailing corner). Used both in the
// merged Notes tab (2 columns) and as the dedicated clipboard tab (adaptive).
Item {
    id: root

    property var entries: []
    property int columns: 2
    property string appName: ""
    property string summary: ""
    property string body: ""
    property string appIcon: ""
    property bool hasNotification: false

    signal pickRequested(int id)
    signal removeRequested(int id)
    signal clearRequested()
    signal dismissClicked()

    ColumnLayout {
        anchors.fill: parent
        spacing: 8
        visible: !root.hasNotification

        // ---- Heading ----
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.topMargin: 8
            Layout.bottomMargin: 4
            spacing: 8

            Text {
                text: "Clipboard"
                color: Colors.white
                font.family: Typography.familyDisplay
                font.pixelSize: Typography.s16
                font.weight: Typography.semibold
            }
            Item { Layout.fillWidth: true }

            // Circular trash button (shown only when there is history).
            Rectangle {
                visible: root.entries.length > 0
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                radius: 13
                color: clearMouse.containsMouse ? Colors.fillHover : Colors.fillSubtle
                Behavior on color { ColorAnimation { duration: Motion.instant } }

                SvgIcon {
                    anchors.centerIn: parent
                    iconName: "trash"
                    color: Colors.systemRed
                    implicitWidth: 14
                    implicitHeight: 14
                }
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.clearRequested()
                }
            }
        }

        // ---- Grid of cards ----
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.bottomMargin: 16
            visible: root.entries.length > 0
            clip: true
            contentHeight: grid.height
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Flow {
                id: grid
                width: parent.width
                spacing: 8

                Repeater {
                    model: root.entries

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        readonly property real cardWidth: Math.max(80,
                            (grid.width - grid.spacing * (root.columns - 1)) / root.columns)
                        width: cardWidth
                        height: 54
                        radius: 12
                        color: cardMouse.containsMouse ? Colors.fillHover : Colors.fill
                        border.color: Colors.hairline
                        border.width: 1
                        clip: true
                        Behavior on color { ColorAnimation { duration: Motion.instant } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            // Thumbnail (images) or the plain type glyph in blue.
                            Item {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28

                                // Type glyph (text entries).
                                SvgIcon {
                                    anchors.centerIn: parent
                                    visible: !(card.modelData.thumb !== "" && thumbImg.status === Image.Ready)
                                    iconName: card.modelData.kind === "Image" ? "photo" : "doc.text"
                                    color: Colors.systemBlue
                                    implicitWidth: 17
                                    implicitHeight: 17
                                }

                                // Image thumbnail in a rounded frame.
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: Colors.fillSubtle
                                    visible: card.modelData.thumb !== "" && thumbImg.status === Image.Ready

                                    Image {
                                        id: thumbImg
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        visible: card.modelData.thumb !== "" && status === Image.Ready
                                        source: card.modelData.thumb
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: false
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                Text {
                                    Layout.fillWidth: true
                                    text: card.modelData.preview.replace(/\s+/g, " ")
                                    color: Colors.white
                                    font.family: Typography.family
                                    font.pixelSize: Typography.s13
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: card.modelData.kind
                                        color: Colors.textSecondary
                                        font.family: Typography.family
                                        font.pixelSize: Typography.s10
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: card.modelData.age
                                        color: Colors.textSecondary
                                        font.family: Typography.family
                                        font.pixelSize: Typography.s10
                                    }
                                }
                            }
                        }

                        // Hover-only delete in the top-trailing corner.
                        Rectangle {
                            visible: cardMouse.containsMouse
                            width: 18
                            height: 18
                            radius: 9
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 4
                            color: Colors.black
                            opacity: 0.5

                            SvgIcon {
                                anchors.centerIn: parent
                                iconName: "xmark.circle.fill"
                                color: Colors.white
                                implicitWidth: 13
                                implicitHeight: 13
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.removeRequested(card.modelData.id)
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.pickRequested(card.modelData.id)
                        }
                    }
                }
            }
        }

        // ---- Empty state ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.entries.length === 0
            spacing: 8

            Item { Layout.fillHeight: true }
            SvgIcon {
                Layout.alignment: Qt.AlignHCenter
                iconName: "doc.on.clipboard"
                color: Colors.textTertiary
                implicitWidth: 32
                implicitHeight: 32
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "No copies yet"
                color: Colors.textSecondary
                font.family: Typography.familyDisplay
                font.pixelSize: Typography.s14
                font.weight: Typography.semibold
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Copy something to see it here"
                color: Colors.textTertiary
                font.family: Typography.family
                font.pixelSize: Typography.s11
            }
            Item { Layout.fillHeight: true }
        }
    }

    // ---- Live notification takes over the pane while one is up ----
    NotificationWidget {
        anchors.fill: parent
        anchors.margins: Metrics.padCard
        visible: root.hasNotification
        appName: root.appName
        summary: root.summary
        body: root.body
        appIcon: root.appIcon
        onDismissClicked: root.dismissClicked()
    }
}
