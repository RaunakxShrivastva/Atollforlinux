import QtQuick
import QtQuick.Layouts
import "../theme"

// One clipboard row, shared by ClipboardPopover and ClipboardPanel.
//
// Atoll has two near-identical row types: ClipboardPanelItemRow (a 34pt type
// badge - or the image thumbnail - a tinted "Text · 4m ago" subtitle and a
// fixed 78pt gutter of hover actions, so revealing the actions never shoves the
// text sideways) and ClipboardPopoverItemRow (a bare blue glyph, an 11pt
// preview and colour-coded heart/copy/trash actions). `popover` switches
// between the two.
Item {
    id: row

    property var item: null
    property bool pinned: false    // favorites rows; also history rows already pinned
    property bool popover: false

    signal copyClicked()
    signal pinClicked()
    signal deleteClicked()

    readonly property string kind: row.item ? (row.item.kind || "Text") : "Text"
    readonly property string preview: row.item
        ? String(row.item.preview || "").replace(/\s+/g, " ").trim() : ""
    readonly property bool hasThumb: !row.popover && row.item
        && row.item.thumb !== "" && thumbImg.status === Image.Ready

    // Muted per-type tints (ClipboardPanel.swift extension ClipboardItemType).
    function kindTint(k) {
        if (k === "URL") return "#5990eb";
        if (k === "File") return "#eba84c";
        if (k === "Image") return "#a87ae6";
        if (k === "Rich Text") return "#5cb89e";
        return "#8c94a3";
    }

    function kindIcon(k) {
        if (k === "URL") return "link";
        if (k === "File") return "doc";
        if (k === "Image") return "photo";
        if (k === "Rich Text") return "doc.richtext";
        return "doc.text";
    }

    readonly property color tint: kindTint(row.kind)
    // Briefly flips the glyph/icon to a check after a copy.
    property bool justCopied: false

    implicitHeight: row.popover ? 44 : 52

    Rectangle {
        anchors.fill: parent
        radius: row.popover ? 4 : 12
        color: hover.containsMouse
            ? (row.popover ? Colors.fillHover : Colors.fill)
            : (row.popover ? "transparent" : Colors.fillSubtle)
        border.width: row.popover ? 0 : 1
        border.color: hover.containsMouse ? Colors.hairline : "transparent"
        Behavior on color { ColorAnimation { duration: Motion.instant } }
    }

    // Row-wide click target (copy), below the action buttons.
    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.copyClicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: row.popover ? 14 : 10
        anchors.rightMargin: row.popover ? 14 : 94
        anchors.topMargin: row.popover ? 6 : 9
        anchors.bottomMargin: row.popover ? 6 : 9
        spacing: row.popover ? 10 : 10

        // ---- Panel: type badge / thumbnail. Popover: a bare glyph. ----
        Item {
            Layout.preferredWidth: row.popover ? 16 : 34
            Layout.preferredHeight: row.popover ? 16 : 34
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                visible: !row.popover
                anchors.fill: parent
                radius: 9
                color: row.hasThumb
                    ? Colors.fillSubtle
                    : Qt.rgba(row.tint.r, row.tint.g, row.tint.b, 0.18)
                border.width: 1
                border.color: Colors.fill

                Image {
                    id: thumbImg
                    anchors.fill: parent
                    anchors.margins: 1
                    visible: row.item && row.item.thumb !== "" && status === Image.Ready
                    source: row.item ? row.item.thumb : ""
                    sourceSize.width: 68
                    sourceSize.height: 68
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                }
            }

            SvgIcon {
                anchors.centerIn: parent
                visible: row.popover ? true : !row.hasThumb
                iconName: row.justCopied && !row.popover
                    ? "checkmark" : row.kindIcon(row.kind)
                color: row.popover
                    ? Colors.systemBlue
                    : (row.justCopied ? Colors.systemGreen : row.tint)
                implicitWidth: row.popover ? 14 : 17
                implicitHeight: row.popover ? 14 : 17
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: row.popover ? 3 : 2

            Text {
                Layout.fillWidth: true
                text: row.preview
                color: Colors.white
                font.family: Typography.family
                font.pixelSize: row.popover ? Typography.s11 : Typography.s13
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                clip: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Text {
                    text: row.kind
                    color: row.popover
                        ? Colors.textSecondary
                        : Qt.rgba(row.tint.r, row.tint.g, row.tint.b, 0.95)
                    font.family: Typography.family
                    font.pixelSize: row.popover ? Typography.s9 : Typography.s10
                    font.weight: Typography.medium
                }
                Text {
                    visible: !row.popover
                    text: "·"
                    color: Colors.textTertiary
                    font.family: Typography.family
                    font.pixelSize: Typography.s10
                    font.weight: Typography.medium
                }
                Text {
                    visible: !row.popover
                    text: row.item ? row.item.ageLong : ""
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.s10
                    font.weight: Typography.medium
                }

                Item { Layout.fillWidth: true }

                Text {
                    visible: row.popover
                    text: row.item ? row.item.age : ""
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.s9
                }
            }
        }
    }

    // ---- Hover actions: pin / copy / delete ----
    Row {
        anchors.right: parent.right
        anchors.rightMargin: row.popover ? 8 : 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        ClipboardActionButton {
            icon: row.popover ? (row.pinned ? "heart.fill" : "heart")
                              : (row.pinned ? "pin.fill" : "pin")
            active: row.pinned
            iconColor: row.popover
                ? (row.pinned ? Colors.systemRed : Colors.textSecondary)
                : Colors.textSecondary
            // A pinned row keeps its marker so the state is readable without
            // hovering every row to find it.
            alwaysVisible: row.pinned
            onActivated: row.pinClicked()
        }

        ClipboardActionButton {
            icon: row.justCopied ? "checkmark" : "doc.on.doc"
            iconColor: row.justCopied ? Colors.systemGreen
                                      : (row.popover ? Colors.systemGreen : Colors.textSecondary)
            onActivated: {
                row.copyClicked();
                row.justCopied = true;
                resetTimer.restart();
            }
        }

        ClipboardActionButton {
            icon: "trash"
            iconColor: row.popover ? Colors.systemRed : Colors.textSecondary
            hoverColor: Colors.systemRed
            onActivated: row.deleteClicked()
        }
    }

    Timer {
        id: resetTimer
        interval: 1500
        onTriggered: row.justCopied = false
    }

    // Atoll's ClipboardRowActionButton: a 24pt rounded target that fades in on
    // hover (and stays visible while it carries state, like a set pin).
    component ClipboardActionButton: Item {
        id: button

        property string icon: "doc.on.doc"
        property bool active: false
        property color iconColor: Colors.textSecondary
        property color hoverColor: button.iconColor
        property bool alwaysVisible: false

        signal activated()

        implicitWidth: 24
        implicitHeight: 24
        opacity: button.alwaysVisible || area.containsMouse ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Motion.instant } }

        Rectangle {
            anchors.fill: parent
            radius: 7
            color: area.containsMouse ? Colors.fillHover : "transparent"
        }

        SvgIcon {
            anchors.centerIn: parent
            iconName: button.icon
            color: button.active
                ? (row.popover ? button.iconColor : Colors.accent)
                : (area.containsMouse ? button.hoverColor : button.iconColor)
            implicitWidth: 14
            implicitHeight: 14
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.activated()
        }
    }
}
