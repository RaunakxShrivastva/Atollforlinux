.pragma library

// Pure lyric parsing and timing helpers, ported from Atoll's
// managers/MusicManager.swift (LyricLine, lyricWindow, currentLyricIndex,
// currentLyricSweepProgress) and components/Music/SyncedLyricsList.swift
// (SyncedLyricsRows, PinnedLyricsContextRows).
//
// Kept free of Quickshell imports so dev harnesses can import it under plain
// `qml6`.

var INSTRUMENTAL_THRESHOLD = 5.0;

// One timestamp: [mm:ss], [mm:ss.xx] or [mm:ss.xxx].
var TIME_RE = /\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]/g;

function seconds(mm, ss, frac) {
    var fracS = 0;
    if (frac !== undefined && frac !== "") {
        fracS = parseInt(frac, 10) / Math.pow(10, frac.length);
    }
    return parseInt(mm, 10) * 60 + parseInt(ss, 10) + fracS;
}

// Splits an untimed body into the lines it is written as.
function untimedLines(body) {
    if (!body) return [];
    var raw = body.split("\n");
    var out = [];
    for (var i = 0; i < raw.length; i++) {
        var t = raw[i].trim();
        if (t !== "") out.push({ t: 0, text: t, timed: false });
    }
    return out;
}

// Parses an LRC body into { t, text, timed } lines, sorted by time. The
// [offset:±ms] tag shifts every timestamp. Multiple timestamps on one line all
// carry the same text. Lines with no timestamp (plain text) are dropped.
function parseLrc(body) {
    if (!body) return [];
    var offset = 0;
    var pending = [];
    var raw = body.split("\n");
    for (var i = 0; i < raw.length; i++) {
        var line = raw[i];
        var offMatch = line.match(/^\[offset:\s*([+-]?\d+)\s*\]/i);
        if (offMatch) {
            offset = parseInt(offMatch[1], 10) / 1000.0;
            continue;
        }
        TIME_RE.lastIndex = 0;
        var stamps = [];
        var m;
        var lastEnd = 0;
        while ((m = TIME_RE.exec(line)) !== null) {
            stamps.push(seconds(m[1], m[2], m[3]));
            lastEnd = TIME_RE.lastIndex;
        }
        if (stamps.length === 0) continue;
        var text = line.substring(lastEnd).trim();
        for (var s = 0; s < stamps.length; s++) {
            pending.push({ t: stamps[s] + offset, text: text, timed: true });
        }
    }
    pending.sort(function (a, b) { return a.t - b.t; });
    return pending;
}

// A resolved lyrics body.
//   lines        - [{ t, text, timed }]
//   availability - "unavailable" | "timed" | "plain" | "instrumental"
function resolve(synced, plain, instrumental) {
    if (instrumental === true) {
        return { lines: [], availability: "instrumental" };
    }
    var lines = parseLrc(synced);
    if (lines.length > 0) return { lines: lines, availability: "timed" };
    var untimed = untimedLines(plain);
    if (untimed.length > 0) return { lines: untimed, availability: "plain" };
    return { lines: [], availability: "unavailable" };
}

function hasTimed(lines) {
    for (var i = 0; i < lines.length; i++) if (lines[i].timed) return true;
    return false;
}

// The stretch of the track the line at `index` is on screen for. `index` -1 is
// the run-up to the first line (an intro), matching MusicManager.lyricWindow.
function lyricWindow(lines, index, duration) {
    if (index < 0) {
        if (lines.length === 0 || lines[0].t <= 0) return null;
        return { start: 0, end: lines[0].t };
    }
    if (index >= lines.length) return null;
    var start = lines[index].t;
    var end;
    if (index + 1 < lines.length) end = lines[index + 1].t;
    else if (duration > start) end = duration;
    else return null;
    if (end <= start) return null;
    return { start: start, end: end };
}

// The index of the line being sung at `position`, or -1 before the first line.
function currentIndex(lines, position, lead) {
    if (!hasTimed(lines)) return -1;
    var p = position + (lead || 0);
    var idx = -1;
    for (var i = 0; i < lines.length; i++) {
        if (p >= lines[i].t) idx = i; else break;
    }
    return idx;
}

// 0...1 through the current line, for the sweep highlight.
function sweepProgress(lines, index, position, duration, lead) {
    var w = lyricWindow(lines, index, duration);
    if (!w) return 0;
    var elapsed = (position + (lead || 0)) - w.start;
    return Math.min(Math.max(elapsed / (w.end - w.start), 0), 1);
}

// Whether playback is in a stretch with no words long enough to mark.
function isInstrumentalBreak(lines, index, duration, threshold) {
    if (!lines || lines.length === 0) return false;
    var th = threshold === undefined ? INSTRUMENTAL_THRESHOLD : threshold;
    if (index < 0) return (lines[0].t || 0) >= th;
    if (index >= lines.length) return false;
    if (lines[index].text.trim() !== "") return false;
    var w = lyricWindow(lines, index, duration);
    return w !== null && (w.end - w.start) >= th;
}

// Builds display rows, inserting a blank-text instrumental marker wherever the
// track goes long enough without words (SyncedLyricsRows.rows).
function buildRows(lines, duration, threshold) {
    var th = threshold === undefined ? INSTRUMENTAL_THRESHOLD : threshold;
    var rows = [];
    if (!lines || lines.length === 0) return rows;

    if (lines[0].t >= th) rows.push({ index: -1, text: "", instrumental: true });

    for (var i = 0; i < lines.length; i++) {
        var isBlank = lines[i].text.trim() === "";
        if (isBlank) {
            var end = (i + 1 < lines.length) ? lines[i + 1].t : duration;
            if (end - lines[i].t >= th) rows.push({ index: i, text: "", instrumental: true });
            continue;
        }
        rows.push({ index: i, text: lines[i].text, instrumental: false });
    }
    return rows;
}

// Fixed slots around the current index for the closed-notch pin.
// PinnedLyricsContextRows.slots: `context` is 1, 3 or 5.
function pinnedSlots(lines, duration, index, context, threshold) {
    var rows = buildRows(lines, duration, threshold);
    var seen = {};
    var sung = [];
    for (var i = 0; i < rows.length; i++) {
        if (rows[i].instrumental) continue;
        var li = rows[i].index;
        var ts = lines[li].t;
        if (seen[ts] === true) continue;
        seen[ts] = true;
        sung.push({ index: li, t: ts, text: rows[i].text });
    }
    var radius = Math.floor(context / 2);
    var timestamp = (index >= 0 && index < lines.length) ? lines[index].t : null;

    var previous = [];
    for (var p = 0; p < sung.length; p++) {
        var before = timestamp === null ? sung[p].index < index : sung[p].t < timestamp;
        if (before) previous.push(sung[p]);
    }
    previous = previous.slice(Math.max(0, previous.length - radius));

    var next = [];
    for (var n = 0; n < sung.length; n++) {
        var after = timestamp === null ? sung[n].index > index : sung[n].t > timestamp;
        if (after) next.push(sung[n]);
    }
    next = next.slice(0, radius);

    var current = "";
    for (var c = 0; c < sung.length; c++) {
        if (timestamp !== null && sung[c].t === timestamp) { current = sung[c].text; break; }
    }
    var inGap = false;
    for (var g = 0; g < rows.length; g++) {
        if (rows[g].instrumental && rows[g].index === index) { inGap = true; break; }
    }

    var slots = [];
    for (var a = 0; a < radius - previous.length; a++) slots.push({ text: "", isCurrent: false });
    for (var b = 0; b < previous.length; b++) slots.push({ text: previous[b].text, isCurrent: false });
    slots.push({ text: current !== "" ? current : (inGap ? "\u266a" : ""), isCurrent: true });
    for (var d = 0; d < next.length; d++) slots.push({ text: next[d].text, isCurrent: false });
    for (var e = 0; e < radius - next.length; e++) slots.push({ text: "", isCurrent: false });
    return slots;
}

// Reserved height for the pinned strip: only when timed lyrics are on screen.
function pinnedReservedHeight(eligible, availability, context, rowHeight, gap) {
    if (!eligible || availability !== "timed") return 0;
    return rowHeight * context + gap;
}
