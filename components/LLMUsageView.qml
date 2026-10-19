import QtQuick
import QtQuick.Layouts
import "../theme"

// Usage tab, ported from components/Notch/NotchLLMUsageView.swift.
//
// One card per enabled provider, each with a header (name + subscription-plan
// badge) and a body: quota gauges when the provider reports limits, token
// windows otherwise, and a plain reason string when the provider failed.
// `service` is the LLMUsageService singleton (or a stand-in in a harness) and is
// only read through `.results`; `providers` is the already-filtered
// [{ id, name }] list so the view needs no settings.
//
// Antigravity's Gemini/Claude pool switch and New API's per-account balance
// rows are not reproduced: their data sources (the macOS Antigravity app tree
// and a configured New API endpoint) do not exist here, so those cards always
// take the failure branch and show the reason instead of a dead control.
ColumnLayout {
    id: root

    anchors.fill: parent
    anchors.margins: 8

    property var service: null
    property var providers: []
    property bool featureEnabled: true

    // NB: not named `data` - that is QQuickItem's default property, and
    // redeclaring it stops child items being assigned to the item at all.
    readonly property var snapshots: root.service ? root.service.results : ({})

    spacing: 8

    // ------------------------------------------------------------ data utils --

    function snapshotFor(id) {
        var d = root.snapshots || {};
        var r = d[id];
        return r === undefined ? ({ status: "loading" }) : r;
    }

    function totalTokens(t) {
        return (t && t.input ? t.input : 0) + (t && t.output ? t.output : 0);
    }

    function hasLimits(snap) {
        return (snap.sessionLimit !== undefined && snap.sessionLimit !== null)
            || (snap.weekLimit !== undefined && snap.weekLimit !== null);
    }

    // Atoll's tokens(): 1.2M / 34.5k / 812.
    function tokensText(n) {
        if (n >= 1000000) return (n / 1000000).toFixed(1) + "M";
        if (n >= 1000) return (n / 1000).toFixed(1) + "k";
        return String(n);
    }

    function money(v) {
        return "$" + Number(v || 0).toFixed(2);
    }

    // Cost is an estimate from local token counts, not a subscription bill; an
    // unpriced model makes it partial ("+") or unknowable ("est. n/a") rather
    // than a misleading $0.00.
    function costLabel(t) {
        if (!t || t.unpriced !== true) return root.money(t ? t.cost : 0);
        return (t.cost > 0) ? (root.money(t.cost) + "+") : "est. n/a";
    }

    function displayValue(t) {
        if (t && t.pct === true) return root.totalTokens(t) + "%";
        return root.tokensText(root.totalTokens(t));
    }

    function percentLeft(t) {
        return Math.round(Math.max(0, Math.min(1, (t && t.cost ? t.cost : 0))) * 100);
    }

    function gaugeFraction(limit) {
        if (!limit || !limit.limit) return 0;
        return Math.min(limit.used / limit.limit, 1);
    }

    function gaugeTint(fraction) {
        if (fraction > 0.95) return Colors.systemRed;
        if (fraction > 0.9) return Colors.atollOrange;
        return Colors.accent;
    }

    function usedPercent(limit) {
        return Math.round(limit && limit.used ? limit.used : 0);
    }

    // Atoll's resetsIn(): "" when unset or already past, so the label is omitted.
    function resetsIn(epoch) {
        if (!epoch) return "";
        var seconds = Math.floor(Number(epoch) - Date.now() / 1000);
        if (seconds <= 0) return "";
        var days = Math.floor(seconds / 86400);
        var hours = Math.floor(seconds / 3600);
        var minutes = Math.floor((seconds % 3600) / 60);
        if (days > 0) return "resets in " + days + "d " + (hours % 24) + "h " + minutes + "m";
        return hours > 0 ? ("resets in " + hours + "h " + minutes + "m")
                         : ("resets in " + minutes + "m");
    }

    // -------------------------------------------------------------- disabled --

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !root.featureEnabled
        spacing: 8
        Item { Layout.fillHeight: true }
        SvgIcon {
            Layout.alignment: Qt.AlignHCenter
            iconName: "chart.bar.doc.horizontal"
            size: 28
            color: Colors.textSecondary
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "LLM usage monitoring is disabled"
            color: Colors.textSecondary
            font.family: Typography.family
            font.pixelSize: Typography.s12
            font.weight: Typography.medium
            renderType: Text.QtRendering
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Enable it in Settings → Stats"
            color: Colors.textTertiary
            font.family: Typography.family
            font.pixelSize: Typography.s10
            renderType: Text.QtRendering
        }
        Item { Layout.fillHeight: true }
    }

    // ----------------------------------------------------------------- cards --

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.featureEnabled
        spacing: 10

        Repeater {
            model: root.providers
            delegate: Rectangle {
                id: card
                required property var modelData

                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.06)

                readonly property var snap: root.snapshotFor(card.modelData.id)
                readonly property string status: card.snap.status
                readonly property bool isNewAPI: card.modelData.id === "newAPI"
                readonly property bool isCursor: card.modelData.id === "cursor"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    // ---- header: name + plan badge ----
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.name
                            color: Colors.textPrimary
                            elide: Text.ElideRight
                            font.family: Typography.family
                            font.pixelSize: Typography.s13
                            font.weight: Typography.semibold
                            renderType: Text.QtRendering
                        }

                        // Subscription plan badge ("Max 5x"); Claude only, so it
                        // renders only when a successful snapshot carries one.
                        Rectangle {
                            visible: card.status === "success" && card.snap.plan !== undefined
                                     && card.snap.plan !== null && card.snap.plan !== ""
                            implicitWidth: planLabel.implicitWidth + 10
                            implicitHeight: 14
                            radius: 7
                            color: Qt.rgba(1, 1, 1, 0.12)
                            Text {
                                id: planLabel
                                anchors.centerIn: parent
                                text: card.snap.plan || ""
                                color: Colors.textSecondary
                                font.family: Typography.family
                                font.pixelSize: Typography.s9
                                font.weight: Typography.semibold
                                renderType: Text.QtRendering
                            }
                        }

                    }

                    // ---- loading ----
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: card.status === "loading"
                        SvgIcon {
                            anchors.centerIn: parent
                            iconName: "progress_activity"
                            size: 14
                            color: Colors.textSecondary
                            RotationAnimation on rotation {
                                from: 0
                                to: 360
                                duration: 900
                                loops: Animation.Infinite
                                running: card.status === "loading"
                            }
                        }
                    }

                    // ---- failure ----
                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: card.status === "failure"
                        text: card.snap.reason ? card.snap.reason : "Unavailable"
                        color: Colors.textSecondary
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignTop
                        lineHeight: 1.15
                        font.family: Typography.family
                        font.pixelSize: Typography.s10
                        renderType: Text.QtRendering
                    }

                    // ---- success: quota gauges ----
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: card.status === "success" && root.hasLimits(card.snap)
                                     && !card.isNewAPI
                        spacing: 6

                        QuotaGauge {
                            Layout.fillWidth: true
                            visible: card.snap.sessionLimit !== null && card.snap.sessionLimit !== undefined
                            label: card.isCursor ? "Cursor Models" : "Session"
                            limit: card.snap.sessionLimit
                        }

                        QuotaGauge {
                            Layout.fillWidth: true
                            visible: card.snap.weekLimit !== null && card.snap.weekLimit !== undefined
                            label: card.isCursor ? "Other Models" : "Week"
                            limit: card.snap.weekLimit
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            visible: !card.isCursor
                            WindowRow { Layout.fillWidth: true; label: "Today"; totals: card.snap.today; compact: true }
                            WindowRow { Layout.fillWidth: true; label: "Week"; totals: card.snap.week; compact: true }
                        }
                    }

                    // ---- success: token windows (no limits; e.g. Claude) ----
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: card.status === "success" && !root.hasLimits(card.snap)
                                 && !card.isNewAPI && !card.isCursor
                        spacing: 6

                        WindowRow { Layout.fillWidth: true; label: "Today"; totals: card.snap.today; prominent: true }
                        WindowRow { Layout.fillWidth: true; label: "Week"; totals: card.snap.week }
                        WindowRow { Layout.fillWidth: true; label: "Session"; totals: card.snap.session }
                        Text {
                            Layout.fillWidth: true
                            text: "quota unavailable"
                            color: Colors.textSecondary
                            opacity: 0.7
                            font.family: Typography.family
                            font.pixelSize: Typography.s9
                            renderType: Text.QtRendering
                        }
                    }
                }
            }
        }
    }

    // ---------------------------------------------------------- micro-parts --

    // One label/value row: "Week   12.3k   $1.42" (Atoll's window()).
    component WindowRow: RowLayout {
        id: windowRow
        property string label: ""
        property var totals: null
        property bool prominent: false
        property bool compact: false
        spacing: 6

        Text {
            Layout.preferredWidth: windowRow.compact ? 56 : 48
            text: windowRow.label
            color: Colors.textSecondary
            elide: Text.ElideRight
            font.family: Typography.family
            font.pixelSize: Typography.s9
            renderType: Text.QtRendering
        }
        Text {
            text: root.displayValue(windowRow.totals)
            color: Colors.textPrimary
            font.family: Typography.familyRounded
            font.pixelSize: windowRow.compact ? 11 : (windowRow.prominent ? 17 : 13)
            font.weight: windowRow.prominent ? Typography.bold : Typography.semibold
            renderType: Text.QtRendering
        }
        Item { Layout.fillWidth: true }
        Text {
            text: (windowRow.totals && windowRow.totals.pct === true)
                  ? (root.percentLeft(windowRow.totals) + "% left")
                  : root.costLabel(windowRow.totals)
            color: Colors.textSecondary
            font.family: Typography.familyRounded
            font.pixelSize: Typography.s9
            renderType: Text.QtRendering
        }
    }

    // A limit bar: label + reset countdown, a capsule track/fill and the
    // used/left percentages (Atoll's quotaGauge()).
    component QuotaGauge: ColumnLayout {
        id: gauge
        property string label: ""
        property var limit: null
        spacing: 3

        readonly property real fraction: root.gaugeFraction(gauge.limit)

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                Layout.fillWidth: true
                text: gauge.label
                color: Colors.textSecondary
                elide: Text.ElideRight
                font.family: Typography.family
                font.pixelSize: Typography.s9
                font.weight: Typography.semibold
                renderType: Text.QtRendering
            }
            Text {
                text: root.resetsIn(gauge.limit ? gauge.limit.resetsAt : 0)
                color: Colors.textSecondary
                font.family: Typography.family
                font.pixelSize: Typography.s9
                renderType: Text.QtRendering
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.15)
            Rectangle {
                width: Math.max(4, parent.width * gauge.fraction)
                height: parent.height
                radius: 3
                color: root.gaugeTint(gauge.fraction)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                text: root.usedPercent(gauge.limit) + "% used"
                color: Colors.textPrimary
                font.family: Typography.familyRounded
                font.pixelSize: Typography.s9
                renderType: Text.QtRendering
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.max(0, 100 - root.usedPercent(gauge.limit)) + "% left"
                color: Colors.textSecondary
                font.family: Typography.familyRounded
                font.pixelSize: Typography.s9
                renderType: Text.QtRendering
            }
        }
    }
}
