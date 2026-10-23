pragma Singleton
import QtQuick

// Geometry spec lifted verbatim from the original Atoll Swift source
// (DynamicIsland/sizing/matters.swift, models/Constants.swift,
// components/Tabs/TabSelectionView.swift and components/Notch/DynamicIslandHeader.swift).
// Source of record: the `Atoll-dev` upstream clone (newer than the 2.3.3 release
// tarball). These are the numbers the macOS app actually renders with, so views
// should reference them instead of inventing sizes of their own.
//
// Two presentation modes exist, mirroring Atoll:
//   - "notch"  : the wide top-anchored panel that replaces a real macOS notch
//                (open 640x200, radii top19/bottom24).
//   - "island" : the floating Dynamic Island pill used on non-notched displays
//                (radius 16 closed / 24 open, floats 6px below the top edge).
QtObject {
    // ---- Closed pill (defaults: closedNotchWidth 150, nonNotchHeight 32) ----
    readonly property real closedWidth: 150
    // Collapsed Now Playing strip is content-sized (art + "Title • Artist" +
    // waveform capsule); Atoll grows the pill while a track is up.
    readonly property real closedMediaWidth: 330
    readonly property real closedHeight: 32
    readonly property real notchClosedTopRadius: 6
    readonly property real notchClosedBottomRadius: 14
    readonly property real islandClosedRadius: 16

    // ---- Open: notch mode (openNotchWidth 640, openNotchSize.height 200) ----
    readonly property real notchOpenWidth: 640
    readonly property real notchOpenHeight: 200
    readonly property real notchOpenTopRadius: 19
    readonly property real notchOpenBottomRadius: 24

    // Minimum widths by enabled tab count. Atoll: >=6 -> 770, >=5 -> 690, else 640.
    readonly property real notchOpenMinWidthFew: 640
    readonly property real notchOpenMinWidth5: 690
    readonly property real notchOpenMinWidth6: 770

    // ---- Open: island mode (minimalisticBaseOpenNotchSize, DI style) ----
    readonly property real islandOpenWidth: 420
    readonly property real islandOpenHeight: 180
    readonly property real islandOpenRadius: 24
    readonly property real islandTopOffset: 6

    // ---- Shadow ----
    readonly property real shadowPaddingStandard: 18
    readonly property real shadowPaddingMinimalistic: 12
    readonly property real islandShadowInset: 14
    readonly property real shadowBlurRadius: 10
    readonly property real shadowColorOpacity: 0.5

    // ---- Header / tabs (DynamicIslandHeader, TabSelectionView) ----
    readonly property real headerButton: 30      // action capsules: 30x30
    // Atoll dev: the action row's HStack(spacing: 8) ("30pt targets 8pt apart
    // read as one run of buttons"). The older 2.3.3 release used 4.
    readonly property real headerActionSpacing: 8
    readonly property real headerSpacing: 4      // generic small spacing
    readonly property real headerPadding: 8
    readonly property real tabSpacing: 24        // HStack(spacing: 24)
    readonly property real tabWidth: 24          // icon-only hit width (no 30pt pill like the actions)
    readonly property real tabHeight: 26         // .frame(height: 26)
    // Active-tab pill: a solid white capsule around the selected glyph, sized to
    // the header row (the reference notch renders ~56x30).
    readonly property real tabCapsuleHeight: 30
    readonly property real tabCapsuleWidth: 56
    readonly property real centerSpacerMax: 300  // black area masked by NotchShape

    // Header glyphs: Atoll renders each *action* symbol at its own point size
    // inside a 20pt box so a mixed row lands on a common ink height
    // (headerGlyphSizes); the default is the row size. Tab icons use the
    // inherited body size (~17pt) and are not optically adjusted.
    readonly property real headerGlyphBox: 20
    readonly property real headerActionGlyphSize: 16
    readonly property real tabIconSize: 19

    // Battery (DynamicIslandBatteryView passes batteryWidth 30; % is .callout)
    readonly property real batteryWidth: 30
    readonly property real batteryPercentFontSize: 15

    // ---- Inline lyrics / screen bleed (matters.swift, dev) ----
    readonly property real minimalisticLyricsExtraHeight: 50 // was 40 in 2.3.3
    readonly property real inlineLyricsLineHeight: 18
    readonly property real notchTopScreenBleed: 4

    // ---- Music artwork (MusicPlayerImageSizes) ----
    readonly property real albumOpen: 90
    readonly property real albumClosed: 20
    readonly property real albumOpenRadius: 13
    readonly property real albumClosedRadius: 4
    readonly property real albumArtRadiusInset: 13

    // ---- Home / media player (NotchHomeView) ----
    // MusicPlayerView = HStack(alignment: .top, spacing: 12).
    readonly property real mediaRowSpacing: 12
    // MusicControlsView subtitle indent (songInfoAndSlider .padding(.leading, 5)).
    readonly property real mediaInfoLeading: 5
    readonly property real mediaInfoTop: 10
    // CustomSlider(restingTrackHeight: 8, draggingTrackHeight: 14) inside a
    // 36pt frame; stacked labels sit 6pt below.
    readonly property real mediaSliderHeight: 6
    readonly property real mediaSliderFrame: 36
    readonly property real mediaTimeFontSize: 11
    // HoverButton: 30pt target for regular glyphs, 40pt for the large play
    // button; HStack(spacing: 8).
    readonly property real mediaTransportBox: 30
    readonly property real mediaTransportGlyph: 19
    readonly property real mediaPlayBox: 40
    readonly property real mediaPlayGlyph: 30
    readonly property real mediaTransportSpacing: 8
    // AlbumArtView.appIconOverlay: 36x36 at .bottomTrailing .offset(x: 10, y: 10).
    readonly property real mediaBadge: 36

    // ---- Side lyrics panel (NotchHomeView.sideLyricsContent) ----
    // An HStack(alignment: .top, spacing: 20) of player / LyricsSidePanelView /
    // optional camera preview. The player keeps a 380pt floor and the panel
    // takes Defaults[.lyricsPanelWidth] (280 by default).
    readonly property real sideLyricsMinPlayerWidth: 380
    readonly property real sideLyricsMinMirrorWidth: 220
    readonly property real sideLyricsSpacing: 20
    readonly property real sideLyricsCombinedInset: 40
    // LyricsSidePanelView background: Color.black.opacity(0.3), radius 4.
    readonly property real lyricsPanelRadius: 4
    readonly property real lyricsPanelHeaderTop: 10
    readonly property real lyricsPanelHeaderBottom: 6
    readonly property real lyricsPanelHeaderSide: 12
    // SyncedLyricsStyle defaults for the notch list.
    readonly property real lyricsListFontSize: 14
    readonly property real lyricsListCurrentFontSize: 14
    readonly property real lyricsListLineSpacing: 8
    readonly property real lyricsListInstrumentalFontSize: 12
    readonly property int lyricsListLineLimit: 2
    readonly property real lyricsListPaddingH: 12
    readonly property real lyricsListPaddingV: 4

    // ---- PinnedLyricsView (closed notch) ----
    readonly property real pinnedLyricsFontSize: 10
    readonly property real pinnedLyricsGap: 4
    // (ascender - descender + leading) rounded up + 1 for a 10pt medium face.
    readonly property real pinnedLyricsRowHeight: 15
    readonly property real pinnedLyricsPaddingH: 10

    // ---- MusicManager lyric timing ----
    // A quarter-second lead so the highlight lands with the voice.
    readonly property real lyricLeadTime: 0.25
    // Gaps shorter than this are breaths between lines, not instrumental breaks.
    readonly property real instrumentalBreakThreshold: 5
    readonly property real mediaBadgeOffset: 10
    // albumArtBackground glow: scaleEffect(x: 1.3, y: 1.4), opacity .5 playing.
    readonly property real mediaGlowScaleX: 1.3
    readonly property real mediaGlowScaleY: 1.4
    readonly property real mediaGlowOpacity: 0.5
    // Room around the glow for the blur to fade out; without it the blur
    // clips at the effect's own bounds and leaves hard rectangular corners.
    readonly property real mediaGlowBleed: 96

    // ---- Stats (NotchStatsView) ----
    readonly property real statsCardRadius: 8
    readonly property real statsGraphHeight: 36
    readonly property real statsGridSpacing: 12
    readonly property real statsCardFill: 0.08   // white @ 0.08
    readonly property real statsCardStroke: 0.18 // white @ 0.18

    // Height of each tab's content area (excludes the header strip). Shared by
    // the live container and the offline harness so they can't drift apart.
    function tabContentHeight(tab) {
        switch (tab) {
            case "HOME":      return 200; // media player (90pt art + transport) beside the calendar
            case "STATS":     return 198; // two rows of cards (3-over-2) need the room
            case "USAGE":     return 200; // one row of provider cards (gauges + windows)
            case "TIMER":     return 200;
            case "CLIPBOARD": return 200;
            case "CALENDAR":  return 278;
            case "NOTES":     return 200; // clipboard cards / note cards
            case "DOWNLOADS": return 180;
            case "SHELF":     return 130;
            // A guake-style terminal wants all the room it can get; Atoll sizes
            // it up to 40% of the screen height (terminalMaxHeightFraction).
            case "TERMINAL":  return 240;
            default:          return 140;
        }
    }
}
