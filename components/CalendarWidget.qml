import QtQuick
import QtQuick.Layouts
import "../theme"

// Port of Atoll's `CalendarView` (components/Calendar/DynamicIslandCalendar.swift),
// i.e. the calendar that lives *inside the Home tab* — not the big standalone
// month grid. Its shape is:
//
//   header row   |  collapsed: one small "Wed, Dec 24" line
//                |  hovered  : month + year label, next to a date wheel
//   events area  |  the day's events, or the "No events today" empty state
//
// The date wheel is a horizontally snapping strip of {weekday, day} cells; the
// selected cell carries an accent pill and today's number sits in an accent
// circle (WheelPicker / dateButton in the Swift source).
ColumnLayout {
    id: root

    property var events: []            // CalendarService.upcoming (ts + summary + allDay)
    property date selectedDate: new Date()
    property bool expanded: false      // hover expands the date wheel

    spacing: 0
    anchors.fill: parent
    anchors.margins: 0

    readonly property int pastDays: 7
    readonly property int futureDays: 14
    readonly property int labelWidth: 72
    readonly property int cellVisible: 7

    readonly property var anchorDate: new Date()
    readonly property var dayShort: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    readonly property var monthShort: ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                       "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    function startOfDay(d) {
        return new Date(d.getFullYear(), d.getMonth(), d.getDate());
    }

    function buildCells() {
        var base = root.startOfDay(root.anchorDate);
        var out = [];
        for (var i = -root.pastDays; i <= root.futureDays; i++) {
            var d = new Date(base.getFullYear(), base.getMonth(), base.getDate() + i);
            out.push({ date: d, day: d.getDate(), weekday: root.dayShort[d.getDay()], isToday: i === 0 });
        }
        return out;
    }

    readonly property var cells: buildCells()
    readonly property int todayIndex: root.pastDays

    // Index of the Monday that opens today's week — the cell the strip parks on.
    readonly property int weekStartIndex: {
        var d = root.startOfDay(root.anchorDate);
        var back = (d.getDay() + 6) % 7;   // days elapsed since Monday
        return Math.max(0, root.pastDays - back);
    }

    function indexOfDate(d) {
        var base = root.startOfDay(root.anchorDate).getTime();
        var diff = Math.round((root.startOfDay(d).getTime() - base) / 86400000);
        return Math.max(0, Math.min(root.cells.length - 1, diff + root.pastDays));
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }

    readonly property string monthLabel: root.monthShort[root.selectedDate.getMonth()]
    readonly property string yearLabel: String(root.selectedDate.getFullYear())
    readonly property string compactLabel: root.dayShort[root.selectedDate.getDay()] + ", "
                                          + root.monthShort[root.selectedDate.getMonth()] + " "
                                          + root.selectedDate.getDate()

    readonly property var agenda: root.events.slice(0, 3)

    // ---- Row 1: date header ----
    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: root.expanded ? 54 : 22

        Behavior on Layout.preferredHeight {
            NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic }
        }

        HoverHandler { onHoveredChanged: root.expanded = hovered }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.topMargin: 2
            spacing: 8

            // Left label: one compact line, or month over year once expanded.
            Item {
                Layout.preferredWidth: root.labelWidth
                Layout.fillHeight: true

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.compactLabel
                    visible: !root.expanded
                    color: Colors.textPrimary
                    font.family: Typography.family
                    font.pixelSize: Typography.s13
                    font.weight: Typography.medium
                    renderType: Text.QtRendering
                }

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1
                    visible: root.expanded

                    Text {
                        text: root.monthLabel
                        color: Colors.textPrimary
                        font.family: Typography.family
                        font.pixelSize: Typography.s18
                        font.weight: Typography.semibold
                        renderType: Text.QtRendering
                    }
                    Text {
                        text: root.yearLabel
                        color: Colors.textSecondary
                        font.family: Typography.family
                        font.pixelSize: Typography.s12
                        renderType: Text.QtRendering
                    }
                }
            }

            // Date wheel (only takes room while expanded).
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: root.expanded
                opacity: root.expanded ? 1 : 0

                ListView {
                    id: wheel
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    model: root.cells
                    boundsBehavior: Flickable.StopAtBounds
                    snapMode: ListView.SnapToItem
                    cacheBuffer: 400
                    spacing: 0

                    // Never cram seven cells into a narrow column (the mirror
                    // can leave the calendar ~200pt): below 30pt the weekday
                    // and day labels overlap, so let the strip scroll instead.
                    readonly property real cellWidth: Math.max(30, width / root.cellVisible)

                    // The reference opens on the week that holds today (Mon..Sun),
                    // not on a strip centred under it. Park the view on that
                    // Monday's cell as soon as the strip has a size.
                    property bool positioned: false
                    function positionWeek() {
                        if (positioned) return;
                        if (width <= 0 || cellWidth <= 0) return;
                        positioned = true;
                        positionViewAtIndex(root.weekStartIndex, ListView.Beginning);
                    }
                    Component.onCompleted: positionWeek()
                    onWidthChanged: positionWeek()
                    onContentWidthChanged: positionWeek()

                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index

                        width: wheel.cellWidth
                        height: wheel.height

                        readonly property bool selected: root.sameDay(cell.modelData.date, root.selectedDate)

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - 4
                            height: parent.height - 2
                            radius: 8
                            color: cell.selected ? Colors.accent : "transparent"
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: cell.modelData.weekday
                                color: cell.selected ? Colors.white : Colors.textSecondary
                                font.family: Typography.family
                                font.pixelSize: Typography.s11
                                renderType: Text.QtRendering
                            }

                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 20
                                height: 20

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: cell.modelData.isToday ? Colors.accent : "transparent"
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: cell.modelData.day
                                    color: cell.selected ? Colors.white
                                         : (cell.modelData.isToday ? Colors.white : Colors.textSecondary)
                                    font.family: Typography.family
                                    font.pixelSize: Typography.s13
                                    font.weight: Typography.medium
                                    renderType: Text.QtRendering
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedDate = cell.modelData.date;
                                wheel.currentIndex = cell.index;
                            }
                        }
                    }
                }

                // Edge fades: hint that the strip keeps scrolling (0.45 like Atoll).
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 16
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 16
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.45) }
                    }
                }
            }
        }
    }

    // ---- Row 2: the day's events, or the empty state ----
    // Collapsed (not hovered) the widget is just the one-line header, so the
    // agenda only takes part in the layout while expanded.
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.expanded

        // Empty state (EmptyEventsView)
        Column {
            anchors.centerIn: parent
            spacing: 0
            visible: root.agenda.length === 0

            SvgIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                iconName: "calendar.badge.checkmark"
                color: Colors.textSecondary
                implicitWidth: 22
                implicitHeight: 22
            }
            Item { width: 1; height: 7 }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No events today"
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

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 6
            spacing: 4
            visible: root.agenda.length > 0

            Repeater {
                model: root.agenda
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

    function eventTime(e) {
        if (e.allDay) return "All-day";
        var d = new Date(e.start);
        return (d.getHours() < 10 ? "0" : "") + d.getHours() + ":"
             + (d.getMinutes() < 10 ? "0" : "") + d.getMinutes();
    }
}
