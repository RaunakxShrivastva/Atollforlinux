import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"

// Port of Atoll's `CalendarView` (components/Calendar/DynamicIslandCalendar.swift),
// i.e. the calendar that lives *inside the Home tab* — not the big standalone
// month grid. Its shape is:
//
//   header row   |  month + year label, next to the date wheel
//   events area  |  the day's events, or the "No events today" empty state
//
// The reference home tab keeps the month label, the week strip and the events
// visible at once (no collapsed one-line state); the wheel can still be
// collapsed by setting expanded: false.
//
// The date wheel is a horizontally snapping strip of {weekday, day} cells; the
// selected cell carries an accent pill and today's number sits in an accent
// circle (WheelPicker / dateButton in the Swift source).
ColumnLayout {
    id: root

    property var events: []            // CalendarService.upcoming (ts + summary + allDay)
    property date selectedDate: new Date()
    // The reference home tab shows the month label, the week strip and the
    // day's events all the time - it does not collapse to a one-line header.
    property bool expanded: true

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
        Layout.preferredHeight: root.expanded ? 48 : 22

        Behavior on Layout.preferredHeight {
            NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic }
        }

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
                    // Line the month up with the wheel's weekday row instead
                    // of floating mid-strip (the old vertical centring left a
                    // visible gap between "Oct" and the dates).
                    anchors.top: parent.top
                    anchors.topMargin: 4
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

                // The blue point: the old today-circle shape (small, hugging
                // the day NUMBER), but fixed at the strip's centre row. Dates
                // scroll past it; whichever date sits under it turns
                // white-on-blue and zooms, then shrinks and fades as it
                // leaves. y matches the Column's number row (~weekday + gap).
                Rectangle {
                    x: parent.width / 2 - width / 2
                    y: parent.height / 2 + 11 - height / 2
                    width: 22
                    height: 22
                    radius: 11
                    color: Colors.accent
                }

                ListView {
                    id: wheel
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    model: root.cells
                    boundsBehavior: Flickable.StopAtBounds
                    snapMode: ListView.NoSnap
                    cacheBuffer: 400
                    spacing: 0

                    // Manual, eased snap-to-centre (the blue point). The
                    // "selected" day is whichever cell rests on the point.
                    readonly property real snapOffset: width / 2 - cellWidth / 2
                    function snapX(index) {
                        return Math.max(0, Math.min(contentWidth - width,
                            index * cellWidth - snapOffset));
                    }
                    function settle() {
                        if (cellWidth <= 0 || contentWidth <= 0) return;
                        var idx = Math.round((contentX + snapOffset) / cellWidth);
                        idx = Math.max(0, Math.min(root.cells.length - 1, idx));
                        snapAnim.to = snapX(idx);
                        snapAnim.start();
                        if (root.cells[idx]
                            && !root.sameDay(root.cells[idx].date, root.selectedDate))
                            root.selectedDate = root.cells[idx].date;
                    }
                    onMovementEnded: {
                        userMoved = true;
                        settle();
                    }
                    NumberAnimation {
                        id: snapAnim
                        target: wheel
                        property: "contentX"
                        duration: Motion.base
                        easing.type: Easing.OutCubic
                    }

                    // Never cram seven cells into a narrow column (the mirror
                    // can leave the calendar ~200pt): below 30pt the weekday
                    // and day labels overlap, so let the strip scroll instead.
                    readonly property real cellWidth: Math.max(30, width / root.cellVisible)

                    // Open with TODAY parked on the blue point (centre).
                    // Re-parks on every width change until the user takes
                    // over: the first layout passes can run with a stub width
                    // whose snapOffset is wrong, and a one-shot lock would
                    // leave the strip parked three cells off.
                    property bool userMoved: false
                    function positionWeek() {
                        if (userMoved) return;
                        if (width < cellWidth * 3 || cellWidth <= 0) return;
                        contentX = snapX(root.todayIndex);
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

                        // Proximity to the fixed blue point: dates zoom in and
                        // brighten as they scroll under it, shrink and dim as
                        // they leave (continuous, driven by contentX).
                        readonly property real centerDist: Math.abs(
                            cell.x + cell.width / 2 - (wheel.contentX + wheel.width / 2))
                        readonly property real prox: Math.max(0, 1 - cell.centerDist / (wheel.cellWidth * 1.6))
                        readonly property bool atCenter: cell.centerDist < wheel.cellWidth * 0.45
                        readonly property real zoom: Settings.reduceMotionEnabled
                            ? 1 : (0.86 + 0.32 * cell.prox)

                        // Pivot on the day-number row: the zooming number
                        // stays glued to the static blue circle.
                        transform: Scale {
                            origin.x: wheel.cellWidth / 2
                            origin.y: wheel.height / 2 + 11
                            xScale: cell.zoom
                            yScale: cell.zoom
                        }
                        opacity: 0.7 + 0.3 * cell.prox

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: cell.modelData.weekday
                                color: cell.atCenter ? Colors.white : Colors.textTertiary
                                font.family: Typography.family
                                font.pixelSize: Typography.s11
                                renderType: Text.QtRendering
                                // The colour crossfades as a date enters/leaves
                                // the blue point.
                                Behavior on color { ColorAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }
                            }

                            Item {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: 20
                                height: 20

                                Text {
                                    anchors.centerIn: parent
                                    text: cell.modelData.day
                                    color: cell.atCenter ? Colors.white
                                         : (cell.modelData.isToday ? Colors.accent : Colors.textSecondary)
                                    font.family: Typography.family
                                    font.pixelSize: Typography.s13
                                    font.weight: Typography.medium
                                    renderType: Text.QtRendering
                                    Behavior on color { ColorAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wheel.userMoved = true;
                                root.selectedDate = cell.modelData.date;
                                snapAnim.to = wheel.snapX(cell.index);
                                snapAnim.start();
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
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // Empty state (EmptyEventsView)
        Column {
            // Centre under the date wheel / blue point, not the raw pane:
            // the label block pushes the wheel centre (labelWidth + 8) / 2
            // to the right of the pane centre.
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: (root.labelWidth + 8) / 2
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -6
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
