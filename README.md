# Atoll for Linux 🏝️

An ultra-lightweight, high-performance, exact Linux replica of the **Atoll Dynamic Island** experience for macOS.

Built with **Quickshell (QML / Qt6)**, hardware-accelerated fluid spring physics, glassmorphic UI design, native D-Bus MPRIS media integration, system metrics monitoring, notifications, and interactive productivity utilities.

---

## 🔎 Reference source (spec of record)

This port mirrors the upstream **Atoll** Swift/SwiftUI app. The reference tree
lives in `Atoll-dev/` (a full clone of <https://github.com/Ebullioscopic/Atoll>,
newer than the 2.3.3 release). It is **reference only** — macOS/Swift, not built
or run here. Geometry, colours, fonts and icons are lifted verbatim from it into
`theme/Atoll.qml`; views should reference those tokens rather than invent sizes.

Key files consulted: `DynamicIsland/sizing/matters.swift`,
`DynamicIsland/models/Constants.swift`,
`DynamicIsland/components/Notch/{NotchShape,DynamicIslandHeader,NotchHomeView,HoverButton}.swift`,
`DynamicIsland/components/Tabs/TabSelectionView.swift`,
`DynamicIsland/components/Settings/SettingsView.swift`, and the UI screenshots in
`DynamicIslandSamples/` (`media.png` is the Home/media baseline).

---

## 🌟 Key Features

* **Dynamic Morphing Pill**: Sleek, floating top-center notch that smoothly expands into interactive Live Activity cards on hover or notification alerts.
* **MPRIS Media Player Card**: Native track info, album artwork with a coloured glow, source-app badge, progress slider, shuffle / prev / play / next / repeat controls, and per-player colour tinting (Spotify, Firefox, Chrome, VLC, mpv, Strawberry, …).
* **System Insights & Metrics**: Real-time CPU usage percentage, RAM usage graph, battery level & charging animation.
* **Desktop Notifications Integration**: Seamlessly intercept and display desktop notification popups right inside the notch.
* **Timer & Stopwatch Utility**: Countdown timer and stopwatch controls built into the island.
* **Quick Tools Launcher**: One-click color picker, screenshot, and terminal launcher.
* **Ultra-Lightweight & Fast**: ~20MB RAM consumption, 0% idle CPU usage, and 60–140 FPS butter-smooth spring animations.

---

## 🚀 Quick Start

### Running Atoll
To start Atoll in foreground or background:

```bash
# Launch directly using the included launcher script
./bin/atoll start

# Check status
./bin/atoll status

# Stop Atoll
./bin/atoll stop
```

Or run via Quickshell CLI:
```bash
quickshell -p shell.qml
```

---

## 📂 Project Structure

```
Atoll for linux/
├── shell.qml                     # Main Layer-Shell entrypoint (presentation: island|notch)
├── bin/
│   └── atoll                     # Executable launcher script (start|stop|restart|status)
├── theme/
│   ├── Atoll.qml                 # Geometry spec lifted from upstream (sizes, radii, tabs)
│   ├── Colors.qml                # Atoll color palette
│   ├── Metrics.qml               # Shared spacing/radius metrics
│   ├── Typography.qml            # Font hierarchy (Inter + bundled Nunito for SF Rounded)
│   ├── Motion.qml                # Springs / timing curves
│   └── Icons.qml                 # SF Symbol name -> Material Symbols ligature map
├── components/
│   ├── NotchContainer.qml        # Master morphing island container with spring physics
│   ├── NotchShape.qml            # Quad-curve notch path (notch mode)
│   ├── PillShape.qml             # Rounded pill (island mode)
│   ├── NotchHeaderBar.qml        # Tab strip + action capsules + battery
│   ├── CompactPill.qml           # Closed notch pill (Clock, Battery, Audio Wave)
│   ├── MediaWidget.qml           # Live Activity: Album art, track info, progress slider
│   ├── TransportButton.qml       # HoverButton port (shuffle/prev/play/next/repeat)
│   ├── SystemWidget.qml          # Live Activity: CPU, RAM, Battery metrics
│   ├── TimerWidget.qml           # Live Activity: Timer & Stopwatch
│   ├── CalendarWidget.qml        # Live Activity: Calendar
│   ├── NotificationWidget.qml    # Live Activity: D-Bus notification alerts
│   ├── QuickActionLauncher.qml   # Tools: Color picker, screenshot, terminal
│   ├── SettingsWindow.qml        # Atoll Settings (700x600 FloatingWindow, IPC "settings")
│   └── settings/                 # Form controls + one file per Settings tab
│       ├── FormSection.qml ... FormColorRow.qml
│       └── tabs/                 # 21 tabs (General, Appearance, Media, ... About)
├── services/
│   ├── MPRISService.qml          # Linux MPRIS media control service
│   ├── SystemMonitorService.qml  # Hardware usage reader
│   ├── NotificationService.qml   # D-Bus notification server
│   ├── TimerService.qml          # Countdown & stopwatch engine
│   └── Settings.qml              # Persisted settings store (~90 upstream keys)
├── fonts/
│   └── Nunito.ttf                # SF Rounded substitute for the header
├── dev/                          # Offline render harnesses (see below)
└── Atoll-dev/                    # Upstream Swift reference (not built)
```

### Offline preview harnesses

Rendered with plain `qml6` (headless), useful for checking geometry without a
running shell:

```bash
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 dev/mock.qml    # both modes, all tabs
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 dev/widgets.qml # widget gallery
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 dev/stats.qml   # system stats grid
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qml6 dev/media.qml   # media player card
```
PNGs are written to `/tmp/opencode/preview/`. Note: `MultiEffect` (blur/glow)
does **not** render under the software backend, so glow must be checked in a
live shell.

`dev/` also contains a fake MPRIS player for live media testing
(`/tmp/opencode/mpris_mock.py`, exposes `org.mpris.MediaPlayer2.mock`).

---

## ⚙️ Settings

Atoll Settings is a faithful port of the upstream `SettingsView.swift`:
a 700x600 window titled "Atoll Settings" with a searchable sidebar (8 groups,
21 tabs, gradient tab icons) and a grouped `Form` detail pane.

Open it with the gear in the island header, or:

```bash
./bin/atoll settings        # open
./bin/atoll close-settings  # close
```

Values persist to `$XDG_CONFIG_HOME/atoll/settings.json` (falling back to
`~/.config/atoll/settings.json`) and are read live by the shell through the
`Settings` singleton (~90 upstream `Defaults.Keys`). Currently honoured by the
island: window shadow, timer/clipboard tabs, color-picker action, battery
indicator and media card options (slider colour, player colour tinting).

The window is also scriptable over IPC:

```bash
quickshell -p shell.qml ipc call settings toggle
quickshell -p shell.qml ipc call settings tab media
quickshell -p shell.qml ipc call settings search "timer"
```

---

## 🎨 Controls & Shortcuts

| Action | Behavior |
| :--- | :--- |
| **Hover Notch** | Expands pill into active card (Media / System / Notification) |
| **Mouse Exit** | Auto-collapses back into sleek compact pill |
| **Tab Buttons** | Switch between Media, System, Timer, and Tools cards |
| **Collapse Button (`^`)** | Immediately collapses notch to compact state |
| **Gear (header)** | Opens Atoll Settings |

---

## 🧭 Known limitations

* Blur/glass is not available in Quickshell 0.3.1; on Hyprland add
  `layerrule = blur, atoll-notch` for a glassmorphic background.
* A fixed accent colour is used everywhere; `Settings` accent/alternate-accent
  values are not yet propagated into `theme/Colors.qml` (would make the theme
  depend on the services layer).
* macOS-only features are faithful stubs: Spotify web auth, Sparkle updater,
  extensions/RPC host, and the LLM Screen Assistant (disabled).

---

## 🛡️ License
Open source under GPL-3.0. Inspired by macOS Atoll.
