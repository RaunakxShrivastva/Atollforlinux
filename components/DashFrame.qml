import QtQuick

// Dashed rounded-rectangle stroke, the shelf panels' border (macOS Atoll
// draws the same [10]-dash capsule-stroked rounded rects on both panels and
// lights them up with the accent colour while a drag is over them).
Canvas {
    id: root

    property real radius: 12
    property real lineWidth: 2.5
    property color strokeColor: Qt.rgba(1, 1, 1, 0.1)
    // Dash pattern length, in px (macOS StrokeStyle(lineWidth: 3, dash: [10])).
    property real dashLength: 10

    antialiasing: true
    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.lineWidth = root.lineWidth;
        ctx.strokeStyle = root.strokeColor;
        ctx.lineCap = "round";
        ctx.setLineDash([root.dashLength, root.dashLength * 0.9]);

        // The stroke is centred on the path, so a path on the canvas edge
        // loses half its width to clipping — dashes render chopped. Inset by
        // half the line width (+ AA pad) so the full stroke stays inside.
        var pad = root.lineWidth / 2 + 1;
        var w = width - pad * 2, h = height - pad * 2;
        // Degenerate sizes appear for a frame mid-collapse (anchored children
        // can go negative); a negative radius makes arcTo throw.
        if (w <= 0 || h <= 0) return;
        var r = Math.max(0, Math.min(root.radius, Math.min(w, h) / 2));
        ctx.translate(pad, pad);
        ctx.beginPath();
        ctx.moveTo(r, 0);
        ctx.lineTo(w - r, 0);
        ctx.arcTo(w, 0, w, r, r);
        ctx.lineTo(w, h - r);
        ctx.arcTo(w, h, w - r, h, r);
        ctx.lineTo(r, h);
        ctx.arcTo(0, h, 0, h - r, r);
        ctx.lineTo(0, r);
        ctx.arcTo(0, 0, r, 0, r);
        ctx.closePath();
        ctx.stroke();
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onStrokeColorChanged: requestPaint()
    onRadiusChanged: requestPaint()
    onLineWidthChanged: requestPaint()
    onDashLengthChanged: requestPaint()
}
