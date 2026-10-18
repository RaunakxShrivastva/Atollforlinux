pragma Singleton
import QtQuick

// Colour maths and format strings for the colour picker, ported from
// models/PickedColor.swift (hexString / rgbString / hslString / hsvString and
// the rgbToHsl / rgbToHsv helpers).
//
// Deliberately free of any Quickshell dependency so both ColorPickerService and
// the picker's views can use it — and so it can be rendered in an offscreen
// harness. A colour is { r, g, b, a } with each channel a 0..1 float, exactly
// like Atoll's PickedColor.
QtObject {
    id: root

    readonly property var defaultFormats: ["HEX", "RGB", "RGBA", "HSL", "HSLA", "HSV", "QML"]

    function parseHex(s) {
        var t = String(s || "").trim();
        if (t.length === 0) return null;
        if (t.charAt(0) === "#") t = t.substring(1);
        // Tolerate the 8-digit form ImageMagick prints.
        if (!/^[0-9a-fA-F]{3}([0-9a-fA-F]{3})?([0-9a-fA-F]{2})?$/.test(t)) return null;
        if (t.length === 3) t = t[0] + t[0] + t[1] + t[1] + t[2] + t[2];
        return {
            r: parseInt(t.substring(0, 2), 16) / 255,
            g: parseInt(t.substring(2, 4), 16) / 255,
            b: parseInt(t.substring(4, 6), 16) / 255,
            a: t.length === 8 ? parseInt(t.substring(6, 8), 16) / 255 : 1
        };
    }

    function channel(v) { return Math.round(Math.max(0, Math.min(1, v)) * 255); }
    function hx(v) { var s = root.channel(v).toString(16).toUpperCase(); return s.length < 2 ? "0" + s : s; }

    function toHex(c) {
        return "#" + root.hx(c.r) + root.hx(c.g) + root.hx(c.b)
             + (c.a < 1 ? root.hx(c.a) : "");
    }
    function toRgb(c) {
        return "rgb(" + root.channel(c.r) + ", " + root.channel(c.g) + ", " + root.channel(c.b) + ")";
    }
    function toRgba(c) {
        return "rgba(" + root.channel(c.r) + ", " + root.channel(c.g) + ", " + root.channel(c.b)
             + ", " + Number(c.a).toFixed(2) + ")";
    }

    function hslParts(c) {
        var max = Math.max(c.r, Math.max(c.g, c.b));
        var min = Math.min(c.r, Math.min(c.g, c.b));
        var l = (max + min) / 2;
        if (max === min) return { h: 0, s: 0, l: l };
        var d = max - min;
        var s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
        var h;
        if (max === c.r) h = (c.g - c.b) / d + (c.g < c.b ? 6 : 0);
        else if (max === c.g) h = (c.b - c.r) / d + 2;
        else h = (c.r - c.g) / d + 4;
        return { h: h * 60, s: s, l: l };
    }

    function hsvParts(c) {
        var max = Math.max(c.r, Math.max(c.g, c.b));
        var min = Math.min(c.r, Math.min(c.g, c.b));
        var d = max - min;
        var s = max === 0 ? 0 : d / max;
        if (d === 0) return { h: 0, s: 0, v: max };
        var h;
        if (max === c.r) h = (c.g - c.b) / d + (c.g < c.b ? 6 : 0);
        else if (max === c.g) h = (c.b - c.r) / d + 2;
        else h = (c.r - c.g) / d + 4;
        return { h: h * 60, s: s, v: max };
    }

    function toHsl(c) {
        var p = root.hslParts(c);
        return "hsl(" + Math.round(p.h) + ", " + Math.round(p.s * 100) + "%, " + Math.round(p.l * 100) + "%)";
    }
    function toHsla(c) {
        var p = root.hslParts(c);
        return "hsla(" + Math.round(p.h) + ", " + Math.round(p.s * 100) + "%, "
             + Math.round(p.l * 100) + "%, " + Number(c.a).toFixed(2) + ")";
    }
    function toHsv(c) {
        var p = root.hsvParts(c);
        return "hsv(" + Math.round(p.h) + ", " + Math.round(p.s * 100) + "%, " + Math.round(p.v * 100) + "%)";
    }
    // SwiftUI/UIColor have no Linux meaning; QML keeps the same "paste into your
    // code" role that those two formats play on macOS.
    function toQml(c) {
        return "Qt.rgba(" + Number(c.r).toFixed(3) + ", " + Number(c.g).toFixed(3)
             + ", " + Number(c.b).toFixed(3) + ", " + Number(c.a).toFixed(3) + ")";
    }

    // [{ name, value }] in Atoll's order (allFormats).
    function formatsFor(c) {
        if (!c) return [];
        return [
            { name: "HEX",  value: root.toHex(c) },
            { name: "RGB",  value: root.toRgb(c) },
            { name: "RGBA", value: root.toRgba(c) },
            { name: "HSL",  value: root.toHsl(c) },
            { name: "HSLA", value: root.toHsla(c) },
            { name: "HSV",  value: root.toHsv(c) },
            { name: "QML",  value: root.toQml(c) }
        ];
    }

    // The single format chosen in Settings, used for the clipboard copy.
    function formatColor(c, name) {
        if (!c) return "";
        switch (String(name || "hex").toLowerCase()) {
        case "rgb":  return root.toRgb(c);
        case "rgba": return root.toRgba(c);
        case "hsl":  return root.toHsl(c);
        case "hsv":  return root.toHsv(c);
        default:     return root.toHex(c);
        }
    }

    function colorOf(c) {
        if (!c) return Qt.rgba(0, 0, 0, 0);
        return Qt.rgba(c.r, c.g, c.b, c.a === undefined ? 1 : c.a);
    }

    function timeAgo(ts) {
        var interval = (Date.now() - Number(ts || 0)) / 1000;
        if (interval < 60) return "Just now";
        if (interval < 3600) return Math.floor(interval / 60) + "m ago";
        if (interval < 86400) return Math.floor(interval / 3600) + "h ago";
        return Math.floor(interval / 86400) + "d ago";
    }
}
