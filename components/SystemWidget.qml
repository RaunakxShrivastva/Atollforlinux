import QtQuick
import QtQuick.Layouts
import "../theme"

// Port of Atoll's NotchStatsView / UnifiedStatsCard: a smart grid of stat cards
// (CPU, Memory, GPU, Network, Disk) each with a header, a value row and a
// sparkline. 5 cards lay out 3-over-2; 4 cards lay out 2-over-2, matching
// NotchStatsView.statsGridLayout. Colours: CPU blue, Memory green, GPU purple,
// Network orange/red, Disk cyan/yellow (NotchStatsView.swift).
ColumnLayout {
    id: root

    property real cpuUsage: 0.0
    property real ramUsage: 0.0
    property int ramUsedMb: 0
    property int ramTotalMb: 16000
    property int batteryPercent: 100
    property bool isCharging: false

    property real gpuUsage: 0.0
    property bool hasGpu: false
    property real netDown: 0
    property real netUp: 0
    property real diskRead: 0
    property real diskWrite: 0

    property var cpuHistory: []
    property var memHistory: []
    property var gpuHistory: []
    property var netDownHistory: []
    property var netUpHistory: []
    property var diskReadHistory: []
    property var diskWriteHistory: []

    // Developer > Stats: which cards to show.
    property bool showCPU: true
    property bool showMemory: true
    property bool showGPU: true
    property bool showNetwork: true
    property bool showDisk: true

    anchors.fill: parent
    anchors.margins: 4
    spacing: Atoll.statsGridSpacing    // 12: gap between the two rows

    function fmtRate(bps) {
        if (bps >= 1048576) return (bps / 1048576).toFixed(1) + " MB/s";
        if (bps >= 1024) return (bps / 1024).toFixed(0) + " KB/s";
        return (bps || 0).toFixed(0) + " B/s";
    }

    readonly property var cards: {
        var c = [];
        if (showCPU) c.push({ icon: "cpu", title: "CPU", accent: Colors.systemBlue, dual: false,
                 value: Math.round(cpuUsage) + "%", data: cpuHistory });
        if (showMemory) c.push({ icon: "memorychip", title: "Memory", accent: Colors.systemGreen, dual: false,
                 value: Math.round(ramUsage) + "%", data: memHistory });
        if (hasGpu && showGPU) {
            c.push({ icon: "display", title: "GPU", accent: Colors.systemPurple, dual: false,
                     value: Math.round(gpuUsage) + "%", data: gpuHistory });
        }
        if (showNetwork) c.push({ icon: "network", title: "Network", accent: Colors.systemOrange, dual: true,
                 pos: "\u2193" + fmtRate(netDown), neg: "\u2191" + fmtRate(netUp),
                 negColor: Colors.systemRed, data: netDownHistory, data2: netUpHistory });
        if (showDisk) c.push({ icon: "internaldrive", title: "Disk", accent: Colors.systemCyan, dual: true,
                 pos: "R " + fmtRate(diskRead), neg: "W " + fmtRate(diskWrite),
                 negColor: Colors.systemYellow, data: diskReadHistory, data2: diskWriteHistory });
        return c;
    }

    readonly property bool threeUp: cards.length >= 5
    readonly property var topRow: threeUp ? cards.slice(0, 3) : cards.slice(0, 2)
    readonly property var bottomRow: threeUp ? cards.slice(3) : cards.slice(2)

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8
        Repeater {
            model: root.topRow
            delegate: StatCard { required property var modelData; card: modelData; Layout.fillWidth: true; Layout.fillHeight: true }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 8
        Repeater {
            model: root.bottomRow
            delegate: StatCard { required property var modelData; card: modelData; Layout.fillWidth: true; Layout.fillHeight: true }
        }
    }

    // ---- Single-line sparkline with gradient fill (Atoll MiniGraph) ----
    // Canvas-based: PathPolyline bindings do not refresh from `property var`
    // arrays reliably, so both graphs rasterise via Canvas.onPaint instead.
    component MiniGraph: Canvas {
        id: mg
        property var data: []
        property color color: "white"

        onDataChanged: requestPaint()
        onColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var n = data.length;
            if (n < 2) return;
            var m = 1;
            for (var i = 0; i < n; i++) if (data[i] > m) m = data[i];
            var stepX = width / (n - 1);
            function yAt(v) { return height * (1 - v / m); }

            var g = ctx.createLinearGradient(0, 0, 0, height);
            g.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 0.3));
            g.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0.1));
            ctx.beginPath();
            ctx.moveTo(0, yAt(data[0]));
            for (var j = 1; j < n; j++) ctx.lineTo(j * stepX, yAt(data[j]));
            ctx.lineTo(width, height);
            ctx.lineTo(0, height);
            ctx.closePath();
            ctx.fillStyle = g;
            ctx.fill();

            ctx.beginPath();
            ctx.moveTo(0, yAt(data[0]));
            for (var k = 1; k < n; k++) ctx.lineTo(k * stepX, yAt(data[k]));
            ctx.strokeStyle = color;
            ctx.lineWidth = 2;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            ctx.stroke();
        }
    }

    // ---- Two-line quadrant graph (Atoll DualQuadrantGraph) ----
    component DualGraph: Canvas {
        id: dg
        property var posData: []
        property var negData: []
        property color posColor: "orange"
        property color negColor: "red"

        onPosDataChanged: requestPaint()
        onNegDataChanged: requestPaint()
        onPosColorChanged: requestPaint()
        onNegColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        function drawLine(ctx, arr, sign, col, m, cy) {
            var n = arr.length;
            if (n < 2) return;
            var stepX = width / (n - 1);
            function yAt(v) { return cy - sign * (cy * (v / m)); }

            var g = ctx.createLinearGradient(0, sign > 0 ? 0 : cy, 0, sign > 0 ? cy : height);
            g.addColorStop(0, Qt.rgba(col.r, col.g, col.b, 0.3));
            g.addColorStop(1, Qt.rgba(col.r, col.g, col.b, 0.1));
            ctx.beginPath();
            ctx.moveTo(0, yAt(arr[0]));
            for (var j = 1; j < n; j++) ctx.lineTo(j * stepX, yAt(arr[j]));
            ctx.lineTo(width, cy);
            ctx.lineTo(0, cy);
            ctx.closePath();
            ctx.fillStyle = g;
            ctx.fill();

            ctx.beginPath();
            ctx.moveTo(0, yAt(arr[0]));
            for (var k = 1; k < n; k++) ctx.lineTo(k * stepX, yAt(arr[k]));
            ctx.strokeStyle = col;
            ctx.lineWidth = 2;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            ctx.stroke();
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var m = 1;
            for (var i = 0; i < posData.length; i++) if (posData[i] > m) m = posData[i];
            for (var q = 0; q < negData.length; q++) if (negData[q] > m) m = negData[q];
            var cy = height / 2;

            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.3);
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(0, cy);
            ctx.lineTo(width, cy);
            ctx.stroke();

            drawLine(ctx, posData, 1, posColor, m, cy);
            drawLine(ctx, negData, -1, negColor, m, cy);
        }
    }

    component StatCard: Rectangle {
        id: card
        property var card: ({})
        property bool hovered: cardMouse.containsMouse

        radius: Atoll.statsCardRadius
        color: Qt.rgba(1, 1, 1, Atoll.statsCardFill)
        border.color: Qt.rgba(1, 1, 1, hovered ? 0.45 : Atoll.statsCardStroke)
        border.width: 1
        scale: hovered ? 1.02 : 1.0
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

        MouseArea { id: cardMouse; anchors.fill: parent; hoverEnabled: true }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                SvgIcon {
                    iconName: card.card.icon || ""
                    color: card.card.accent || Colors.textSecondary
                    implicitWidth: 13
                    implicitHeight: 13
                }
                Text {
                    text: card.card.title || ""
                    color: Qt.rgba(1, 1, 1, 0.8)
                    font.family: Typography.family
                    font.pixelSize: Typography.s11
                    font.weight: Typography.medium
                }
                Item { Layout.fillWidth: true }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 20

                Text {
                    anchors.centerIn: parent
                    visible: !(card.card.dual === true)
                    text: card.card.value || ""
                    color: Colors.white
                    font.family: Typography.family
                    font.pixelSize: Typography.s20
                    font.weight: Typography.bold
                    font.letterSpacing: Typography.trackTight
                }

                RowLayout {
                    anchors.centerIn: parent
                    visible: card.card.dual === true
                    spacing: 5
                    Text {
                        text: card.card.pos || ""
                        color: card.card.accent
                        font.family: Typography.family
                        font.pixelSize: Typography.s12
                        font.weight: Typography.semibold
                    }
                    Text {
                        text: "\u2022"
                        color: Qt.rgba(1, 1, 1, 0.45)
                        font.pixelSize: Typography.s10
                    }
                    Text {
                        text: card.card.neg || ""
                        color: card.card.negColor || Colors.textSecondary
                        font.family: Typography.family
                        font.pixelSize: Typography.s12
                        font.weight: Typography.semibold
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: Atoll.statsGraphHeight

                MiniGraph {
                    anchors.fill: parent
                    visible: !(card.card.dual === true)
                    data: card.card.data || []
                    color: card.card.accent || Colors.accent
                }
                DualGraph {
                    anchors.fill: parent
                    visible: card.card.dual === true
                    posData: card.card.data || []
                    negData: card.card.data2 || []
                    posColor: card.card.accent || Colors.systemOrange
                    negColor: card.card.negColor || Colors.systemRed
                }
            }
        }
    }
}
