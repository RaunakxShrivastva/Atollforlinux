import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../services"
import "settings"

// Atoll Settings window, ported from DynamicIsland/components/Settings/SettingsView.swift.
// A macOS NavigationSplitView: a 216px sidebar (search + grouped tab list) next
// to a grouped-form detail pane. Opened from the notch gear, `atoll settings`,
// or `quickshell ipc call settings toggle`.
FloatingWindow {
    id: win

    title: "Atoll Settings"
    minimumSize: Qt.size(700, 460)
    implicitWidth: 720
    implicitHeight: 620
    visible: false
    color: "transparent"

    // FloatingWindow is a compositor-managed toplevel: it has no x/y. It opens
    // on the focused screen and the compositor decides placement.
    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null

    function open() { win.visible = true; }
    function close() { win.visible = false; }
    function toggle() { win.visible = !win.visible; }

    // SettingsTab registry (icons + tints mirror SettingsView.swift).
    readonly property var tabGroups: [
        { title: "", tabs: [
            { id: "general",    title: "General",    icon: "gear",             tint: "#0a84ff", src: "settings/tabs/GeneralSettings.qml" },
            { id: "appearance", title: "Appearance", icon: "paintpalette",     tint: "#bf5af2", src: "settings/tabs/AppearanceSettings.qml" }
        ] },
        { title: "Media & Display", tabs: [
            { id: "media",        title: "Media",         icon: "play.laptopcomputer",  tint: "#30d158", src: "settings/tabs/MediaSettings.qml" },
            { id: "liveActivities", title: "Live Activities", icon: "waveform.path.ecg", tint: "#ff2d55", src: "settings/tabs/LiveActivitiesSettings.qml" },
            { id: "lockScreen",   title: "Lock Screen",   icon: "lock.laptopcomputer",  tint: "#ff9f0a", src: "settings/tabs/LockScreenSettings.qml" },
            { id: "devices",      title: "Devices",       icon: "headphones",           tint: "#1b1c1f", src: "settings/tabs/DevicesSettings.qml" }
        ] },
        { title: "System", tabs: [
            { id: "hudAndOSD", title: "Controls", icon: "dial.medium.fill",  tint: "#5e5ce6", src: "settings/tabs/ControlsSettings.qml" },
            { id: "battery",   title: "Battery",  icon: "battery.100.bolt",  tint: "#34c759", src: "settings/tabs/BatterySettings.qml" }
        ] },
        { title: "Productivity", tabs: [
            { id: "timer",    title: "Timer",    icon: "timer",      tint: "#ff453a", src: "settings/tabs/TimerSettings.qml" },
            { id: "calendar", title: "Calendar", icon: "calendar",   tint: "#64d2ff", src: "settings/tabs/CalendarSettings.qml" },
            { id: "notes",    title: "Notes",    icon: "note.text",  tint: "#fac010", src: "settings/tabs/NotesSettings.qml" }
        ] },
        { title: "Utilities", tabs: [
            { id: "clipboard",      title: "Clipboard",      icon: "clipboard",               tint: "#66d4cf", src: "settings/tabs/ClipboardSettings.qml" },
            { id: "screenAssistant", title: "Screen Assistant", icon: "brain.head.profile",   tint: "#ff2d55", src: "settings/tabs/ScreenAssistantSettings.qml" },
            { id: "colorPicker",    title: "Color Picker",   icon: "eyedropper",              tint: "#0a84ff", src: "settings/tabs/ColorPickerSettings.qml" },
            { id: "shelf",          title: "Shelf",          icon: "books.vertical",          tint: "#a2845e", src: "settings/tabs/ShelfSettings.qml" },
            { id: "downloads",      title: "Downloads",      icon: "square.and.arrow.down",   tint: "#8e8e93", beta: true, src: "settings/tabs/DownloadsSettings.qml" },
            { id: "shortcuts",      title: "Shortcuts",      icon: "keyboard",                tint: "#ff9f0a", src: "settings/tabs/ShortcutsSettings.qml" }
        ] },
        { title: "Developer", tabs: [
            { id: "stats",    title: "Stats",    icon: "chart.xyaxis.line", tint: "#40c8e0", src: "settings/tabs/StatsSettings.qml" },
            { id: "terminal", title: "Terminal", icon: "apple.terminal",     tint: "#33cc66", src: "settings/tabs/TerminalSettings.qml" }
        ] },
        { title: "Integrations", tabs: [
            { id: "extensions", title: "Extensions", icon: "puzzlepiece.extension", tint: "#8e5af4", beta: true, src: "settings/tabs/ExtensionsSettings.qml" }
        ] },
        { title: "Info", tabs: [
            { id: "about", title: "About", icon: "info.circle", tint: "#8e8e93", src: "settings/tabs/AboutSettings.qml" }
        ] }
    ]

    property string currentTab: "general"
    property string searchText: ""

    function tabMeta(id) {
        for (var g = 0; g < tabGroups.length; g++)
            for (var t = 0; t < tabGroups[g].tabs.length; t++)
                if (tabGroups[g].tabs[t].id === id) return tabGroups[g].tabs[t];
        return null;
    }
    function matches(tab) {
        if (searchText === "") return true;
        return (tab.title + " " + tab.id).toLowerCase().indexOf(searchText.toLowerCase()) !== -1;
    }
    function firstMatch() {
        for (var g = 0; g < tabGroups.length; g++)
            for (var t = 0; t < tabGroups[g].tabs.length; t++)
                if (matches(tabGroups[g].tabs[t])) return tabGroups[g].tabs[t].id;
        return "general";
    }

    // ---- Window chrome ----
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#151518"
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0

            // ---- Sidebar ----
            Rectangle {
                Layout.preferredWidth: 216
                Layout.fillHeight: true
                color: Qt.rgba(1, 1, 1, 0.03)
                topLeftRadius: 11
                bottomLeftRadius: 11

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        radius: 8
                        color: Colors.fill
                        border.color: searchInput.activeFocus ? Colors.accent : Colors.hairline
                        border.width: 1

                        Text {
                            id: searchIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            text: Icons.glyph("magnifyingglass")
                            color: Colors.textTertiary
                            font.family: Typography.iconFamily
                            font.pixelSize: 15
                        }
                        TextInput {
                            id: searchInput
                            anchors.left: searchIcon.right
                            anchors.leftMargin: 7
                            anchors.right: parent.right
                            anchors.rightMargin: 9
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colors.textPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.s12
                            clip: true
                            selectByMouse: true
                            onTextEdited: {
                                win.searchText = text;
                                if (win.searchText !== "") win.currentTab = win.firstMatch();
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search"
                                visible: searchInput.text === ""
                                color: Colors.textTertiary
                                font: searchInput.font
                            }
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: listCol.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: listCol
                            width: parent.width
                            spacing: 2

                            Repeater {
                                model: win.tabGroups
                                delegate: ColumnLayout {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        visible: modelData.title !== ""
                                        text: modelData.title
                                        color: Colors.textTertiary
                                        font.family: Typography.family
                                        font.pixelSize: Typography.s10
                                        font.weight: Typography.semibold
                                        font.capitalization: Font.AllUppercase
                                        font.letterSpacing: 0.5
                                        Layout.leftMargin: 8
                                        Layout.topMargin: 10
                                        Layout.bottomMargin: 2
                                    }

                                    Repeater {
                                        model: modelData.tabs
                                        delegate: Rectangle {
                                            required property var modelData
                                            visible: win.matches(modelData)
                                            Layout.fillWidth: true
                                            implicitHeight: visible ? 36 : 0
                                            radius: 8
                                            color: win.currentTab === modelData.id ? Colors.accent
                                                 : (rowMouse.containsMouse ? Colors.fillSubtle : "transparent")

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 6
                                                anchors.rightMargin: 8
                                                spacing: 9
                                                SidebarIcon { icon: modelData.icon; tint: modelData.tint }
                                                Text {
                                                    text: modelData.title
                                                    color: "white"
                                                    font.family: Typography.family
                                                    font.pixelSize: Typography.s13
                                                    font.weight: win.currentTab === modelData.id ? Typography.medium : Typography.regular
                                                    Layout.fillWidth: true
                                                }
                                                Rectangle {
                                                    visible: modelData.beta === true
                                                    implicitWidth: betaText.implicitWidth + 10
                                                    implicitHeight: 15
                                                    radius: 4
                                                    color: Colors.accent
                                                    Text { id: betaText; anchors.centerIn: parent; text: "BETA"; color: "white"; font.family: Typography.family; font.pixelSize: 8; font.weight: Typography.bold }
                                                }
                                            }
                                            MouseArea {
                                                id: rowMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: win.currentTab = modelData.id
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                width: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // ---- Detail ----
            Flickable {
                id: detailFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: loader.implicitHeight + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Loader {
                    id: loader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 20
                    anchors.topMargin: 24
                    width: detailFlick.width - 40
                    source: win.tabMeta(win.currentTab) ? win.tabMeta(win.currentTab).src : ""
                }
            }
        }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { win.toggle(); }
        function open(): void { win.open(); }
        function close(): void { win.close(); }
        function show(): void { win.open(); }
        function tab(id: string): void { if (id !== "") win.currentTab = id; }
        function search(text: string): void { win.searchText = text; }
    }
}
