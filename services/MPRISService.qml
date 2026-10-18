import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

QtObject {
    id: root

    // Active player reference - prioritize currently playing player
    readonly property MprisPlayer activePlayer: {
        let list = Mpris.players.values;
        for (let i = 0; i < list.length; i++) {
            if (list[i].playbackState === MprisPlaybackState.Playing) {
                return list[i];
            }
        }
        return list.length > 0 ? list[0] : null;
    }
    
    readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle !== "" || activePlayer.playbackState === MprisPlaybackState.Playing)
    readonly property bool isPlaying: activePlayer !== null && activePlayer.playbackState === MprisPlaybackState.Playing
    
    readonly property string trackTitle: activePlayer ? (activePlayer.trackTitle || "Unknown Track") : "No Media Playing"
    readonly property string trackArtist: activePlayer ? (activePlayer.trackArtist || "Unknown Artist") : "Atoll for Linux"
    readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""

    // ---- Player identity (for the album-art app badge + brand tint) ----
    readonly property string playerIdentity: activePlayer ? (activePlayer.identity || "") : ""
    readonly property string desktopEntry: activePlayer ? (activePlayer.desktopEntry || "") : ""

    // A stable lowercase key derived from the identity / desktop entry, used to
    // pick a brand colour and icon (Atoll draws the player's app icon here).
    readonly property string brandKey: {
        let s = (desktopEntry + " " + playerIdentity).toLowerCase();
        if (s.indexOf("spotify") !== -1) return "spotify";
        if (s.indexOf("apple") !== -1 || s.indexOf("music") !== -1) return "apple";
        if (s.indexOf("firefox") !== -1) return "firefox";
        if (s.indexOf("chromium") !== -1 || s.indexOf("chrome") !== -1) return "chrome";
        if (s.indexOf("youtube") !== -1 || s.indexOf("ytm") !== -1) return "youtube";
        if (s.indexOf("vlc") !== -1) return "vlc";
        if (s.indexOf("mpv") !== -1) return "mpv";
        if (s.indexOf("rhythmbox") !== -1) return "rhythmbox";
        if (s.indexOf("strawberry") !== -1) return "strawberry";
        return "";
    }

    readonly property color brandColor: {
        var base = "#0a84ff";
        switch (brandKey) {
            case "spotify":    base = "#1db954"; break;
            case "apple":      base = "#fa243c"; break;
            case "firefox":    base = "#ff7139"; break;
            case "chrome":     base = "#4285f4"; break;
            case "youtube":    base = "#ff0033"; break;
            case "vlc":        base = "#ff8800"; break;
            case "mpv":        base = "#8b5cf6"; break;
            case "strawberry": base = "#e8465a"; break;
            // Appearance > accent colour: tints the player when the app has no
            // known brand (Atoll falls back to the system accent too).
            default:           base = Settings.accent;
        }
        // Appearance > "Colour extraction": how vivid that tint is drawn.
        switch (Settings.colorExtractionMode) {
            case "muted":   return Qt.hsva(Qt.hsva(base).h, Qt.hsva(base).s * 0.55, Qt.hsva(base).v * 1.05, 1);
            case "average": return Qt.hsva(Qt.hsva(base).h, Qt.hsva(base).s * 0.15, Qt.hsva(base).v, 1);
            default:        return base;
        }
    }

    // Best-effort app icon from the desktop icon theme (may be empty).
    readonly property string appIconSource: desktopEntry !== ""
        ? Quickshell.iconPath(desktopEntry, "") : ""

    // ---- Shuffle / repeat (transport state) ----
    readonly property bool shuffleActive: activePlayer ? activePlayer.shuffle === true : false
    readonly property bool shuffleSupported: activePlayer ? activePlayer.shuffleSupported === true : false
    readonly property var loopState: activePlayer ? activePlayer.loopState : MprisLoopState.None
    readonly property bool loopSupported: activePlayer ? activePlayer.loopSupported === true : false
    readonly property bool looping: loopState !== MprisLoopState.None
    readonly property bool loopingOne: loopState === MprisLoopState.Track

    function toggleShuffle() {
        if (activePlayer && activePlayer.shuffleSupported) activePlayer.shuffle = !activePlayer.shuffle;
    }

    function cycleLoop() {
        if (!activePlayer || !activePlayer.loopSupported) return;
        if (activePlayer.loopState === MprisLoopState.None) activePlayer.loopState = MprisLoopState.Playlist;
        else if (activePlayer.loopState === MprisLoopState.Playlist) activePlayer.loopState = MprisLoopState.Track;
        else activePlayer.loopState = MprisLoopState.None;
    }

    property string persistentArtUrl: ""

    property Process artCacheProc: Process {
        stdout: SplitParser {
            onRead: data => {
                let p = data.trim();
                if (p !== "" && !p.startsWith("error")) {
                    root.persistentArtUrl = "file://" + p;
                }
            }
        }
    }

    onArtUrlChanged: {
        if (artUrl && artUrl !== "") {
            artCacheProc.command = ["python3", "-c", "import urllib.request, shutil, os, sys; url = sys.argv[1]; target = '/tmp/atoll_art_cache.png'; path = url[7:] if url.startswith('file://') else url; (os.path.exists(path) and shutil.copyfile(path, target)) or ((url.startswith('http://') or url.startswith('https://')) and urllib.request.urlretrieve(url, target)); print(target if os.path.exists(target) else '')", artUrl];
            artCacheProc.running = true;
        } else {
            root.persistentArtUrl = "";
        }
    }
    
    readonly property real position: activePlayer ? activePlayer.position : 0
    readonly property real length: activePlayer ? activePlayer.length : 1
    readonly property real progress: length > 0 ? Math.min(1.0, Math.max(0.0, position / length)) : 0.0

    property Process focusProc: Process {}

    function focusActivePlayer() {
        focusProc.command = ["python3", Quickshell.shellDir + "/bin/focus_player.py"];
        focusProc.running = true;
    }

    function playPause() {
        if (Settings.musicSource === "playerctl") { ctl("play-pause"); return; }
        if (activePlayer) {
            activePlayer.togglePlaying();
        }
    }

    function next() {
        if (Settings.musicSource === "playerctl") { ctl("next"); return; }
        if (activePlayer && activePlayer.canGoNext) {
            activePlayer.next();
        }
    }

    function previous() {
        if (Settings.musicSource === "playerctl") { ctl("previous"); return; }
        if (activePlayer && activePlayer.canGoPrevious) {
            activePlayer.previous();
        }
    }

    // Devices > "Music source": playerctl drives the transport directly.
    property Process ctlProc: Process {
        stderr: SplitParser { onRead: line => { if (line.trim() !== "") root.ctlError = line.trim(); } }
    }
    property string ctlError: ""
    function ctl(args) {
        ctlProc.command = ["bash", "-c", "playerctl " + args + " 2>&1 || true"];
        ctlProc.running = true;
    }

    // ---- Seeking (waveform scrubber, "seek" skip behaviour, gestures) ----
    function seek(fraction) {
        if (!activePlayer) return;
        var len = activePlayer.length;
        if (len > 0) activePlayer.position = Math.max(0, Math.min(len, fraction * len));
    }

    function seekBy(seconds) {
        if (!activePlayer) return;
        var len = activePlayer.length;
        var next = activePlayer.position + seconds;
        if (next < 0) next = 0;
        if (len > 0 && next > len) next = len;
        activePlayer.position = next;
    }

    // musicSkipBehavior "track" (default) skips the track, "seek" scrubs by the
    // configured step.
    function skipNext(stepSeconds) {
        if (Settings.musicSkipBehavior === "seek") seekBy(stepSeconds === undefined ? 10 : stepSeconds);
        else next();
    }

    function skipPrevious(stepSeconds) {
        if (Settings.musicSkipBehavior === "seek") seekBy(-(stepSeconds === undefined ? 10 : stepSeconds));
        else previous();
    }
}
