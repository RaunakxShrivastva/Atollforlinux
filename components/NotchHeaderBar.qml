import QtQuick
import QtQuick.Layouts
import "../theme"

// Port of Atoll's DynamicIslandHeader (components/Notch/DynamicIslandHeader.swift).
// Layout: left = icon-only tab strip (HStack spacing 24, height 26), a black
// center spacer masked by the notch shape (notch mode only), then right = black
// 30x30 capsule action buttons and the battery readout. All chrome is monochrome
// (Atoll sets the header foreground to .gray and never uses colored badges).
RowLayout {
    id: root

    property string activeTab: "HOME"
    property int batteryLevel: 100
    property bool isCharging: false
    property string presentation: "island"   // "island" | "notch"
    property real closedWidth: Atoll.closedWidth

    // Feature flags (Atoll hides these tabs/actions when the matching Defaults
    // toggle is off: TabSelectionView gates timer/clipboard on
    // enableTimerFeature/enableClipboardManager).
    property bool showTimer: true
    property bool showShelf: true
    property bool showClipboardTab: true
    property bool showClipboardAction: true
    property bool showColorPicker: true
    property bool showBattery: true
    property bool showSettings: true
    property bool showStats: true
    property bool showNotes: false
    property bool showCaffeinate: false
    property bool showDownloads: false
    property bool showTerminal: false
    property bool showUsage: false
    property bool extrasOpen: false
    property bool reduceMotion: false
    property bool caffeinateActive: false
    property color accentColor: "#0a84ff"

    signal caffeinateToggled()
    signal extrasToggled()

    // Tab strip. Atoll's order (TabSelectionView.swift): home, shelf, timer,
    // stats, usage, notes (+ the clipboard when it is not merged into notes),
    // terminal. The Calendar lives inside Home, not as a tab. Membership is
    // driven by the matching Settings toggles, so the strip changes live.
    property var tabs: [
        { id: "HOME",      icon: "house.fill" },
        { id: "SHELF",     icon: "tray.fill" },
        { id: "TIMER",     icon: "timer" },
        { id: "STATS",     icon: "chart.xyaxis.line" },
        { id: "USAGE",     icon: "chart.bar.doc.horizontal" },
        { id: "NOTES",     icon: "note.text" },
        { id: "CLIPBOARD", icon: "doc.on.clipboard" },
        { id: "DOWNLOADS", icon: "arrow.down.circle" },
        { id: "TERMINAL",  icon: "apple.terminal" }
    ]

    // Trailing action capsules (DynamicIslandHeader right side, dev order:
    // list.clipboard, eyedropper, gearshape).
    property var actions: [
        { id: "clipboard",   icon: "list.clipboard" },
        { id: "colorpicker", icon: "eyedropper" },
        { id: "settings",    icon: "gearshape" }
    ]

    // Per-symbol point sizes so a mixed row lands on a common ink height
    // (Atoll's DynamicIslandHeader.headerGlyphSizes). Default is the row size.
    property var glyphSizes: ({
        "web.camera": 14.5,
        "list.clipboard": 13,
        "eyedropper": 14.3,
        "timer": 14.4,
        "gearshape": 14.2,
        "ellipsis": 15.0,
        "cup.and.saucer": 15.0,
        "cup.and.saucer.fill": 15.0
    })

    function glyphSize(name) {
        var s = glyphSizes[name];
        // The map holds SF point sizes, solved so each glyph lands on ~16 of ink.
        // SvgIcon's `size` is an ink target, so bring them onto the same scale.
        return (s === undefined ? Atoll.headerActionGlyphSize : s * 1.11);
    }

    readonly property var visibleTabs: tabs.filter(function (t) {
        if (t.id === "SHELF" && !showShelf) return false;
        if (t.id === "TIMER" && !showTimer) return false;
        if (t.id === "STATS" && !showStats) return false;
        if (t.id === "USAGE" && !showUsage) return false;
        if (t.id === "CLIPBOARD" && !showClipboardDedicatedTab) return false;
        // The merged Notes tab carries the clipboard too when they are combined.
        if (t.id === "NOTES" && !showNotes && !showClipboardTab) return false;
        if (t.id === "DOWNLOADS" && !showDownloads) return false;
        if (t.id === "TERMINAL" && !showTerminal) return false;
        return true;
    })
    readonly property var visibleActions: actions.filter(function (a) {
        if (a.id === "colorpicker" && !showColorPicker) return false;
        if (a.id === "settings" && !showSettings) return false;
        if (a.id === "clipboard" && !showClipboardAction) return false;
        return true;
    })

    // A dedicated clipboard tab exists only in "notchTab" mode; otherwise the
    // clipboard shares the Notes tab.
    property bool showClipboardDedicatedTab: false

    // Whether a tab should read as selected. The clipboard action switches to
    // the merged Notes tab when there is no dedicated one.
    function isTabSelected(tabId) {
        if (tabId === root.activeTab) return true;
        if (tabId === "NOTES" && root.activeTab === "CLIPBOARD"
            && !root.showClipboardDedicatedTab) return true;
        return false;
    }

    signal tabSelected(string tab)
    signal actionTriggered(string action)

    spacing: 0
    Layout.fillWidth: true
    Layout.preferredHeight: Atoll.headerButton
    Layout.leftMargin: Atoll.headerPadding
    Layout.rightMargin: Atoll.headerPadding

    // ---- Left: tab strip ----
    // macOS Atoll marks the active tab with a white capsule behind the glyph.
    // That pill sits flush against the window's top edge in notch/menu-bar
    // modes and the content mask keeps shaving its top curve, so the selected
    // state is carried by the glyph instead: bright white and slightly
    // magnified, idle tabs stay dim.
    Item {
        id: tabStripHost
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: tabStrip.width
        implicitHeight: Atoll.tabHeight

        Row {
            id: tabStrip
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Atoll.tabSpacing

            Repeater {
                model: root.visibleTabs
                delegate: Item {
                    id: tabItem
                    required property var modelData
                    width: Atoll.tabWidth
                    height: Atoll.tabHeight

                    SvgIcon {
                        anchors.centerIn: parent
                        iconName: tabItem.modelData.id === "NOTES" && !root.showNotes
                                  ? "doc.on.clipboard" : tabItem.modelData.icon
                        color: root.isTabSelected(tabItem.modelData.id) || tabMouse.pressed
                             ? Colors.white : Colors.tabIdle
                        implicitWidth: Atoll.tabIconSize
                        implicitHeight: Atoll.tabIconSize
                        // Selected: white and magnified. Press: the HIG dim-and-
                        // squash feedback (the system Button does the same).
                        scale: root.isTabSelected(tabItem.modelData.id) ? 1.22
                             : (tabMouse.pressed ? 0.86 : 1.0)
                        Behavior on scale { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: Motion.fast; easing.type: Easing.Bezier; easing.bezierCurve: Motion.smoothCurve } }
                    }

                    MouseArea {
                        id: tabMouse
                        // Hit area reaches into the 24pt gaps so the strip has no
                        // dead zone (HIG minimum target; visual width unchanged).
                        anchors.fill: parent
                        anchors.leftMargin: -Atoll.tabSpacing / 2
                        anchors.rightMargin: -Atoll.tabSpacing / 2
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tabSelected(tabItem.modelData.id)
                    }
                }
            }
        }
    }

    // ---- Center: black spacer masked by the notch, notch mode only ----
    Item { Layout.fillWidth: true }

    // Fixed height on purpose: a Layout.fillHeight child inflates this nested
    // RowLayout's implicit height, which the ColumnLayout then honours, pushing
    // the whole header down. A 30px block is equivalent since the row is 30 tall.
    Rectangle {
        visible: root.presentation === "notch"
        Layout.preferredWidth: Math.min(root.closedWidth, Atoll.centerSpacerMax)
        Layout.preferredHeight: Atoll.headerButton
        color: Colors.black
    }

    Item { Layout.fillWidth: true }

    // ---- Right: action capsules + battery ----
    RowLayout {
        Layout.alignment: Qt.AlignVCenter
        spacing: Atoll.headerActionSpacing

        Repeater {
            model: root.visibleActions
            delegate: Rectangle {
                required property var modelData
                Layout.preferredWidth: Atoll.headerButton
                Layout.preferredHeight: Atoll.headerButton
                radius: width / 2
                color: actMouse.pressed ? Colors.fillActive
                     : (actMouse.containsMouse ? Colors.fillHover : Colors.black)
                Behavior on color { ColorAnimation { duration: Motion.instant } }

                SvgIcon {
                    anchors.centerIn: parent
                    iconName: modelData.icon
                    color: Colors.white
                    implicitWidth: root.glyphSize(modelData.icon)
                    implicitHeight: root.glyphSize(modelData.icon)
                    scale: actMouse.pressed ? 0.9 : 1.0
                    Behavior on scale { NumberAnimation { duration: Motion.instant; easing.type: Easing.OutCubic } }
                }
                MouseArea {
                    id: actMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.actionTriggered(modelData.id)
                }
            }
        }

        // Caffeinate (General > "Enable caffeinate" + showCaffeinateIcon): a
        // tinted cup while a sleep inhibitor is held.
        Rectangle {
            visible: root.showCaffeinate
            Layout.preferredWidth: Atoll.headerButton
            Layout.preferredHeight: Atoll.headerButton
            radius: width / 2
            color: root.caffeinateActive ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22)
                 : (cafMouse.containsMouse ? Colors.fillHover : Colors.black)
            Behavior on color { ColorAnimation { duration: Motion.instant } }

            SvgIcon {
                anchors.centerIn: parent
                iconName: root.caffeinateActive ? "cup.and.saucer.fill" : "cup.and.saucer"
                color: root.caffeinateActive ? root.accentColor : Colors.white
                implicitWidth: root.glyphSize("cup.and.saucer")
                implicitHeight: root.glyphSize("cup.and.saucer")
                scale: cafMouse.pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: Motion.instant; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                id: cafMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.caffeinateToggled()
            }
        }

        // Battery (DynamicIslandBatteryView). The figure sits to the LEFT of the
        // body, and the body is an outlined capsule with a nub, filled with
        // `batteryColor` (white / green when charging / red at <=20%).
        RowLayout {
            Layout.leftMargin: Atoll.headerSpacing
            spacing: 4
            visible: root.showBattery

            Text {
                text: root.batteryLevel + "%"
                color: root.isCharging ? Colors.systemGreen : Colors.white
                font.family: Typography.family
                font.pixelSize: Atoll.batteryPercentFontSize
                font.weight: Typography.medium
            }

            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 1.5

                Rectangle {
                    width: 28
                    height: 13
                    radius: 4
                    color: "transparent"
                    border.color: root.isCharging ? Colors.systemGreen
                                : (root.batteryLevel <= 20 ? Colors.systemRed : Colors.batteryOutline)
                    border.width: 1

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                        width: Math.max(2, (parent.width - 4) * Math.max(0, Math.min(1, root.batteryLevel / 100.0)))
                        radius: 2
                        color: root.isCharging ? Colors.systemGreen
                             : (root.batteryLevel <= 20 ? Colors.systemRed : Colors.white)
                    }
                }

                // Nub (SF's `battery.*` symbols carry one)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2.5
                    height: 6
                    radius: 0.75
                    color: root.isCharging ? Colors.systemGreen : Colors.batteryOutline
                }
            }
        }

        // "…" overflow: opens Atoll's extras menu (hide / settings / exit).
        Rectangle {
            Layout.preferredWidth: Atoll.headerButton
            Layout.preferredHeight: Atoll.headerButton
            radius: width / 2
            color: root.extrasOpen ? Colors.fillActive
                 : (extrasMouse.containsMouse ? Colors.fillHover : Colors.black)
            Behavior on color { ColorAnimation { duration: Motion.instant } }

            SvgIcon {
                anchors.centerIn: parent
                iconName: "ellipsis"
                color: Colors.white
                implicitWidth: root.glyphSize("ellipsis")
                implicitHeight: root.glyphSize("ellipsis")
                scale: extrasMouse.pressed ? 0.9 : 1.0
                Behavior on scale { NumberAnimation { duration: Motion.instant; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                id: extrasMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.extrasToggled()
            }
        }
    }
}
