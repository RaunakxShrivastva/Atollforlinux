import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"

// Port of Atoll's `StandaloneCalendarView` (components/Calendar/DynamicIslandCalendar.swift).
//
// NotchHomeView uses this instead of `CalendarView` when the media player is
// hidden (no active session + "Auto-hide inactive notch media player"), so the
// home tab is never a stretched single-day strip:
//
//   left pane   |  month title + year, prev/next chevrons, weekday header,
//               |  a scrollable month grid with fade edges
//   right pane  |  the selected day's events, or the empty state
//
// Both panes take half of the row (paneSpacing 12).
Item {
    id: root

    property var events: []                 // every event/reminder (CalendarService.agenda)
    property date selectedDate: new Date()
    property date displayedMonth: new Date(new Date().getFullYear(), new Date().getMonth(), 1)

    readonly property int paneSpacing: 12
    readonly property int cellHeight: 30
    readonly property int gridSpacing: 6

    readonly property var dayInitials: ["S", "M", "T", "W", "T", "F", "S"]
    readonly property var monthWide: ["January", "February", "March", "April", "May", "June",
                                      "July", "August", "September", "October", "November", "December"]

    // Calendar.firstWeekday, as a Sunday-based index (Qt: Monday = 1 ... Sunday = 7).
    readonly property int firstWeekday: Qt.locale().firstDayOfWeek % 7

    function startOfDay(d) {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate());
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }

    // Weeks covering the displayed month, padded to whole rows.
    readonly property var weeks: {
        var y = root.displayedMonth.getFullYear();
        var m = root.displayedMonth.getMonth();
        var first = new Date(y, m, 1);
        var lead = (first.getDay() - root.firstWeekday + 7) % 7;
        var daysInMonth = new Date(y, m + 1, 0).getDate();
        var rows = Math.ceil((lead + daysInMonth) / 7);
        var out = [];
        for (var w = 0; w < rows; w++) {
            var row = [];
            for (var d = 0; d < 7; d++)
                row.push(new Date(y, m, 1 - lead + w * 7 + d));
            out.push(row);
        }
        return out;
    }

    readonly property var weekdayOrder: {
        var out = [];
        for (var i = 0; i < 7; i++)
            out.push(root.dayInitials[(root.firstWeekday + i) % 7]);
        return out;
    }

    readonly property string monthLabel: root.monthWide[root.displayedMonth.getMonth()]
    readonly property string yearLabel: String(root.displayedMonth.getFullYear())

    readonly property var dayEvents: {
        var out = [];
        for (var i = 0; i < root.events.length; i++) {
            var e = root.events[i];
            if (root.sameDay(new Date(e.start), root.selectedDate))
                out.push(e);
        }
        return out;
    }

    readonly property string emptyTitle: root.sameDay(root.selectedDate, new Date())
        ? "No events today" : "No events"

    function eventTime(e) {
        if (e.allDay) return "All-day";
        var d = new Date(e.start);
        return (d.getHours() < 10 ? "0" : "") + d.getHours() + ":"
             + (d.getMinutes() < 10 ? "0" : "") + d.getMinutes();
    }

    function showMonth(offset) {
        var d = new Date(root.displayedMonth.getFullYear(), root.displayedMonth.getMonth() + offset, 1);
        root.displayedMonth = d;
        root.selectedDate = d;
    }

    // Eased scroll-to-centre for the month grid (wheel-picker feel).
    NumberAnimation {
        id: gridScroll
        target: grid
        property: "contentY"
        duration: Motion.base
        easing.type: Easing.OutCubic
    }

    // Center the grid on the selected day (requestDatePickerCenterOnCurrentDate),
    // gliding there instead of jumping.
    function centerOnSelected() {
        var first = new Date(root.displayedMonth.getFullYear(), root.displayedMonth.getMonth(), 1);
        var lead = (first.getDay() - root.firstWeekday + 7) % 7;
        var dayIndex = Math.round((root.startOfDay(root.selectedDate) - first) / 86400000);
        var row = Math.floor((lead + dayIndex) / 7);
        var target = row * root.cellHeight + root.cellHeight / 2 - grid.height / 2;
        target = Math.max(0, Math.min(Math.max(0, grid.contentHeight - grid.height), target));
        if (Settings.reduceMotionEnabled || grid.height <= 0) {
            gridScroll.stop();
            grid.contentY = target;
        } else {
            gridScroll.stop();
            gridScroll.to = target;
            if (Math.abs(grid.contentY - target) > 0.5) gridScroll.start();
            else grid.contentY = target;
        }
    }

    onSelectedDateChanged: {
        var d = new Date(root.selectedDate.getFullYear(), root.selectedDate.getMonth(), 1);
        if (d.getTime() !== root.displayedMonth.getTime())
            root.displayedMonth = d;
        centerOnSelected();
    }
    onDisplayedMonthChanged: centerOnSelected()
    onHeightChanged: centerOnSelected()
    Component.onCompleted: centerOnSelected()

    readonly property real paneWidth: Math.max(0, (width - root.paneSpacing) / 2)

    // Swift lays each pane out with an explicit `.frame(width: paneWidth)`;
    // a RowLayout would hand the month grid (whose content has no implicit
    // width) almost the whole row and collapse the agenda pane.
    Item {
        anchors.fill: parent

        // ---- Left pane: month picker ----
        ColumnLayout {
            x: 6
            y: 4
            width: Math.max(0, root.paneWidth - 12)
            height: parent.height - 4
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: root.monthLabel
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.s18
                    font.weight: Typography.semibold
                    renderType: Text.QtRendering
                }
                Text {
                    Layout.alignment: Qt.AlignBaseline
                    text: root.yearLabel
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.s12
                    font.weight: Typography.medium
                    renderType: Text.QtRendering
                }
                Item { Layout.fillWidth: true }

                Item {
                    implicitWidth: 24
                    implicitHeight: 24
                    SvgIcon {
                        anchors.centerIn: parent
                        iconName: "chevron.left"
                        color: Colors.textPrimary
                        implicitWidth: 12
                        implicitHeight: 12
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showMonth(-1)
                    }
                }
                Item {
                    implicitWidth: 24
                    implicitHeight: 24
                    SvgIcon {
                        anchors.centerIn: parent
                        iconName: "chevron.right"
                        color: Colors.textPrimary
                        implicitWidth: 12
                        implicitHeight: 12
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showMonth(1)
                    }
                }
            }

            // Weekday header (very short symbols, locale order).
            Row {
                Layout.fillWidth: true
                Repeater {
                    model: root.weekdayOrder
                    delegate: Text {
                        required property string modelData
                        width: parent.width / 7
                        text: modelData
                        horizontalAlignment: Text.AlignHCenter
                        color: Colors.textTertiary
                        font.family: Typography.family
                        font.pixelSize: Typography.s11
                        font.weight: Typography.semibold
                        renderType: Text.QtRendering
                    }
                }
            }

            // Month grid, scrolling with fade hints at the edges.
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    id: grid
                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: gridColumn.height
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: gridColumn
                        width: grid.width

                        Repeater {
                            model: root.weeks
                            delegate: Row {
                                id: weekRow
                                required property var modelData
                                width: gridColumn.width
                                height: root.cellHeight

                                Repeater {
                                    model: weekRow.modelData
                                    delegate: Item {
                                        id: dayCell
                                        required property var modelData
                                        width: gridColumn.width / 7
                                        height: root.cellHeight

                                        readonly property bool inMonth: dayCell.modelData.getMonth()
                                            === root.displayedMonth.getMonth()
                                        readonly property bool selected: root.sameDay(dayCell.modelData, root.selectedDate)
                                        readonly property bool today: root.sameDay(dayCell.modelData, new Date())

                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 28
                                            height: 28
                                            radius: 14
                                            visible: dayCell.selected
                                            color: Colors.accent
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            text: dayCell.modelData.getDate()
                                            color: dayCell.selected ? Colors.white
                                                 : (dayCell.inMonth
                                                    ? (dayCell.today ? Colors.accent : Colors.textPrimary)
                                                    : Qt.rgba(1, 1, 1, 0.35))
                                            font.family: Typography.family
                                            font.pixelSize: Typography.s12
                                            font.weight: dayCell.selected ? Typography.semibold : Typography.medium
                                            renderType: Text.QtRendering
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectedDate = dayCell.modelData
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 16
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.65) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 16
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.65) }
                    }
                }
            }
        }

        // ---- Right pane: the selected day ----
        Item {
            x: root.paneWidth + root.paneSpacing
            y: 0
            width: root.paneWidth
            height: parent.height

            Column {
                anchors.centerIn: parent
                spacing: 0
                visible: root.dayEvents.length === 0

                SvgIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    iconName: "calendar.badge.checkmark"
                    color: Colors.textSecondary
                    implicitWidth: 20
                    implicitHeight: 20
                }
                Item { width: 1; height: 7 }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.emptyTitle
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.s13
                    renderType: Text.QtRendering
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Enjoy your free time!"
                    color: Colors.textSecondary
                    font.family: Typography.family
                    font.pixelSize: Typography.s11
                    renderType: Text.QtRendering
                }
            }

            Flickable {
                anchors.fill: parent
                anchors.topMargin: 4
                clip: true
                contentWidth: width
                contentHeight: eventsColumn.height
                boundsBehavior: Flickable.StopAtBounds
                visible: root.dayEvents.length > 0

                ColumnLayout {
                    id: eventsColumn
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.dayEvents
                        delegate: RowLayout {
                            id: ev
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 4
                                Layout.preferredHeight: 30
                                radius: 2
                                color: Colors.accent
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: ev.modelData.summary
                                    color: Colors.textPrimary
                                    font.family: Typography.family
                                    font.pixelSize: Typography.s12
                                    font.weight: Typography.semibold
                                    elide: Text.ElideRight
                                    renderType: Text.QtRendering
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: root.eventTime(ev.modelData)
                                    color: Colors.textSecondary
                                    font.family: Typography.family
                                    font.pixelSize: Typography.s11
                                    elide: Text.ElideRight
                                    renderType: Text.QtRendering
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
