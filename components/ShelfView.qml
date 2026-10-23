import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"
import "../services"

// Shelf tab, ported from Atoll's ShelfView + FileShareView: a square Quick
// Share tile on the left (drop or pick files to share them with the selected
// provider) and the dashed drop panel on the right (files land in a chip row).
// Providers are discovered from this machine's binaries by QuickShareService.
Item {
    id: root

    anchors.fill: parent
    anchors.margins: Metrics.padCard

    // ---------------------------------------------------------------- left
    // FileShareView: the provider tile. Dark fill, dashed border, provider
    // icon + name, switch button (top-right) opening the Quick Share picker.
    Item {
        id: tile
        height: parent.height
        width: height                          // square, like the reference
        readonly property bool targeted: shareDrop.containsDrag

        Rectangle {
            anchors.fill: parent
            radius: Metrics.r12
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.35) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.20) }
            }
        }
        DashFrame {
            anchors.fill: parent
            radius: Metrics.r12
            lineWidth: 2.5
            strokeColor: tile.targeted ? Qt.rgba(0.04, 0.52, 1.0, 0.9)
                                       : Qt.rgba(1, 1, 1, 0.1)
        }

        // Centre: icon in a soft circle + the provider's name.
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 48; implicitHeight: 48; radius: 24
                color: Qt.rgba(1, 1, 1, tile.targeted ? 0.11 : 0.09)
                SvgIcon {
                    anchors.centerIn: parent
                    iconName: "square.and.arrow.up"
                    size: 26
                    color: tile.targeted ? Colors.accent : Colors.textSecondary
                    scale: tile.targeted ? 1.06 : 1.0
                    Behavior on scale { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: tile.width - 16
                text: QuickShareService.selected !== "" ? QuickShareService.selected : "Share"
                color: Qt.rgba(1, 1, 1, 0.8)
                elide: Text.ElideRight
                font.family: Typography.family
                font.pixelSize: Typography.s12
                font.weight: Typography.medium
                renderType: Text.QtRendering
            }
        }

        // Switch button, top-right: opens the Quick Share service picker.
        Item {
            id: switchBtn
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 6
            width: 30; height: 30

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: switchMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                Behavior on color { ColorAnimation { duration: Motion.fast } }
            }
            SvgIcon {
                anchors.centerIn: parent
                iconName: "switch.2"
                size: 14
                color: switchMouse.containsMouse ? Colors.accent : Colors.textSecondary
            }
            MouseArea {
                id: switchMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    QuickShareService.ensureDiscovered();
                    sharePopover.visible = !sharePopover.visible;
                }
            }
        }

        // Click the tile body: pick files the same way the reference opens
        // its AirDrop picker, then share them with the selected provider.
        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: 36
            cursorShape: Qt.PointingHandCursor
            onClicked: if (QuickShareService.selected !== "") picker.running = true
        }

        DropArea {
            id: shareDrop
            anchors.fill: parent
            // No keys filter: accept every drag type the compositor delivers
            // (file managers, terminals, browsers).
            onDropped: drop => {
                var paths = root.pathsFromDrop(drop);
                if (paths.length > 0) QuickShareService.share(paths);
            }
        }
    }

    // --------------------------------------------------------------- right
    // The drop panel: empty state is the tray glyph + "Drop files here";
    // dropped files become clickable chips with a per-item remove.
    Item {
        id: panel
        anchors.left: tile.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: Metrics.gapM
        readonly property bool targeted: panelDrop.containsDrag

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: Qt.rgba(0, 0, 0, 0.20)
        }
        DashFrame {
            anchors.fill: parent
            radius: 16
            lineWidth: 2.5
            strokeColor: panel.targeted ? Qt.rgba(0.04, 0.52, 1.0, 0.9)
                                        : Qt.rgba(1, 1, 1, 0.1)
        }

        // Empty state (ShelfView.content's isEmpty branch).
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10
            visible: shelfItems.length === 0

            SvgIcon {
                Layout.alignment: Qt.AlignHCenter
                iconName: "tray.and.arrow.down"
                size: 26
                color: Qt.rgba(1, 1, 1, panel.targeted ? 0.9 : 0.55)
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Drop files here"
                color: Qt.rgba(1, 1, 1, 0.55)
                font.family: Typography.family
                font.pixelSize: Typography.s13
                font.weight: Typography.medium
                renderType: Text.QtRendering
            }
        }

        // Chip row once files have landed.
        Item {
            anchors.fill: parent
            anchors.margins: 10
            visible: shelfItems.length > 0

            Flickable {
                id: chipFlick
                anchors.fill: parent
                anchors.rightMargin: clearLabel.visible ? clearLabel.width + 10 : 0
                contentWidth: chipRow.width
                contentHeight: height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Row {
                    id: chipRow
                    height: parent.height
                    spacing: 6

                    Repeater {
                        model: shelfItems
                        delegate: Rectangle {
                            id: chip
                            required property var modelData
                            required property int index
                            height: parent.height
                            width: chipLabel.implicitWidth + 46
                            radius: 8
                            color: chipMouse.containsMouse ? Colors.fillHover : Colors.fill

                            SvgIcon {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                iconName: "doc"
                                size: 13
                                color: Colors.textSecondary
                            }
                            Text {
                                id: chipLabel
                                anchors.left: parent.left
                                anchors.leftMargin: 26
                                anchors.right: chipX.left
                                anchors.rightMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                text: chip.modelData.name
                                color: Colors.textPrimary
                                elide: Text.ElideRight
                                font.family: Typography.familyMono
                                font.pixelSize: Typography.s10
                                renderType: Text.QtRendering
                            }
                            SvgIcon {
                                id: chipX
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                iconName: "xmark"
                                size: 10
                                color: chipXMouse.containsMouse ? Colors.textPrimary : Colors.textTertiary
                            }
                            MouseArea {
                                id: chipXMouse
                                anchors.fill: chipX
                                anchors.margins: -5
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    shelfItems.splice(index, 1);
                                    shelfItems = shelfItems.slice();
                                }
                            }
                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                anchors.rightMargin: 20
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: openProc.launch(["xdg-open", "file://" + chip.modelData.path])
                            }
                        }
                    }
                }
            }

            Text {
                id: clearLabel
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Clear"
                color: clearMouse.containsMouse ? Colors.textPrimary : Colors.textTertiary
                font.family: Typography.family
                font.pixelSize: Typography.s10
                font.weight: Typography.medium
                renderType: Text.QtRendering
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: shelfItems = []
                }
            }
        }

        DropArea {
            id: panelDrop
            anchors.fill: parent
            // No keys filter: every file type (and path-bearing text) lands.
            onDropped: drop => root.addPaths(root.pathsFromDrop(drop))
        }
    }

    // ------------------------------------------------------------- popover
    // Quick Share picker (FileShareView's popover): headline, provider rows
    // with a check on the active one, and the "Currently:" footer.
    Rectangle {
        id: sharePopover
        visible: false
        z: 10
        width: 260
        height: popCol.implicitHeight + 24
        anchors.left: tile.left
        anchors.top: tile.bottom
        anchors.topMargin: 6
        radius: 12
        color: Qt.rgba(0.11, 0.11, 0.12, 0.98)
        border.width: 1
        border.color: Colors.hairline

        // Click-away catcher under the popover.
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: {}
        }

        ColumnLayout {
            id: popCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Text {
                text: "Quick Share"
                color: Colors.textPrimary
                font.family: Typography.family
                font.pixelSize: Typography.s12
                font.weight: Typography.bold
                renderType: Text.QtRendering
            }

            Repeater {
                model: QuickShareService.available

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: 6
                    color: rowMouse.containsMouse ? Colors.fillHover : "transparent"

                    SvgIcon {
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        iconName: "checkmark"
                        size: 11
                        visible: QuickShareService.selected === row.modelData.id
                        color: Colors.accent
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.id
                        color: Colors.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.s11
                        renderType: Text.QtRendering
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            QuickShareService.select(row.modelData.id);
                            sharePopover.visible = false;
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Colors.hairline }

            Text {
                Layout.fillWidth: true
                text: "Currently: " + (QuickShareService.selected !== "" ? QuickShareService.selected : "—")
                      + "\nFiles dropped on the tile will be shared via this service"
                color: Colors.textSecondary
                wrapMode: Text.WordWrap
                font.family: Typography.family
                font.pixelSize: Typography.s10
                renderType: Text.QtRendering
            }
        }
    }

    // ------------------------------------------------------------- helpers
    property var shelfItems: []

    // Landed files become {name, path} chips (deduped, trailing slashes
    // trimmed so "/dir/" and "/dir" are one chip).
    function addPaths(paths) {
        if (!paths || paths.length === 0) return;
        var next = shelfItems.slice();
        for (var i = 0; i < paths.length; i++) {
            var p = paths[i];
            var dup = false;
            for (var j = 0; j < next.length; j++) {
                if (next[j].path === p) { dup = true; break; }
            }
            if (dup) continue;
            var trimmed = p.replace(/\/+$/, "");
            var name = trimmed.split("/").pop();
            next.push({ name: name !== "" ? name : p, path: p });
        }
        shelfItems = next;
    }

    // DropArea hands us QUrls; only local file paths belong on the shelf.
    function pathsFromDrop(drop) {
        var out = [];
        var urls = drop.urls || [];
        for (var i = 0; i < urls.length; i++) {
            var s = urls[i].toString();
            if (s.startsWith("file://")) {
                var p = decodeURIComponent(s.substring(7));
                if (p !== "") out.push(p);
            } else if (s.startsWith("/")) {
                out.push(s);
            }
        }
        return out;
    }

    Process {
        id: picker
        command: ["zenity", "--file-selection", "--multiple", "--separator=\n"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n").filter(p => p !== "");
                if (lines.length > 0) QuickShareService.share(lines);
            }
        }
    }

    Process {
        id: openProc
        function launch(cmd) {
            command = ["sh", "-c", "\"$@\" >/dev/null 2>&1 &", "sh"].concat(cmd);
            running = true;
        }
    }

    // Discover providers when the tab first shows.
    onVisibleChanged: if (visible) QuickShareService.ensureDiscovered()

    Component.onCompleted: if (visible) QuickShareService.ensureDiscovered()
}
