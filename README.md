# Sesame

A keyboard-first application launcher for macOS, inspired by Launchpad and Vimium.

Full-screen app grid, fuzzy search, two-letter hint shortcuts, custom groups, and five
hand-picked color themes — all without leaving the keyboard.

English · [中文](README_zh.md)

> Sesame seeds are tiny but always arrive in a dense, ordered array. They don't
> grab attention like a main course — they coat the surface evenly so the whole
> structure becomes accessible, becomes an *entrance*. A Launchpad-style app is,
> at its core, an entry dispatcher: what users want isn't features, but a fast,
> low-friction way to reach them. **Sesame** is exactly that interface
> philosophy — lightweight, everywhere, never in the way.

---

## Features

### Launch & browse
- Full-screen Launchpad-style grid of installed applications
- Automatic scan of `/Applications`, `~/Applications`, and system app directories
- Live refresh on install / uninstall (debounced `DispatchSource` file watcher)
- Cached, asynchronously loaded application icons

### Find
- Real-time fuzzy filter as you type
- Alphabetical sections, or switch to **Custom Groups** view with a single click
- Manage which apps appear in the launcher via the **Hidden** tab

### Hint mode (the headline feature)
- Press the configured hotkey (default <kbd>⌘ K</kbd>) inside the launcher
- Every visible app gets a one- or two-letter badge
- Type the letters → app launches instantly; no mouse, no arrow keys

### Trigger
- **Hot corner** — hover any screen corner (top-left / top-right / bottom-left / bottom-right)
  for 0.24s to summon the launcher
- **Menu bar icon** — click the status item
- **Login item** — launches automatically on sign-in (toggleable)

### Personalization
- **5 color themes** — Sunset / Aurora / Peach / Ocean / Mono — change search field glow,
  toolbar buttons, and ambient background tints together
- **Languages** — 中文 / English, switched instantly at runtime
- **Font** — system default or any installed font family
- **Text size** — S / M / L (12 / 14 / 16pt) with auto-reflowing grid
- **Grid density** — adjustable background cell size 60–240px
- **Custom hotkey** — record any modifier combination to trigger hint mode

---

## Install

```sh
git clone https://github.com/BlackGoldenTicked/sesame.git
cd sesame
./scripts/build_app.sh
open build/Sesame.app
```

The script runs `swift build -c release`, packages a proper `.app` bundle, generates
`AppIcon.icns` from `Sources/Sesame/Resources/logo.png`, and writes `Info.plist`.

Drag `build/Sesame.app` into `/Applications` to keep it permanently.

**Requirements:** macOS 13+, Swift 5.9+, Xcode Command Line Tools.

---

## Usage

| Action | Shortcut |
|---|---|
| Show launcher | Hot corner · menu bar icon · <kbd>⌘ L</kbd> when focused |
| Hide launcher | <kbd>Esc</kbd> |
| Search | Just start typing |
| Enter hint mode | <kbd>⌘ K</kbd> (configurable) |
| Launch via hint | Type the 1–2 letter code on each app |
| Exit hint mode | <kbd>Esc</kbd> |
| Open settings | Gear button in the toolbar |
| Quit | <kbd>⌘ Q</kbd> while menu is focused |

The trigger corner runs inside the Sesame process, so the app must stay running
(it lives in the menu bar). Enable **Launch at login** in settings for hands-off setup.

---

## Settings

Four tabs in a Raycast-style sidebar layout:

- **General** — startup, language, hotkey, theme, font, text size, grid density
- **Hidden** — search-able list to toggle which apps appear in the launcher
- **Groups** — create / edit / delete named groups of apps
- **About** — version, copyright, link to website

---

## Tech

- Swift Package Manager, no third-party dependencies
- SwiftUI + AppKit interop (`NSWindow`, `NSStatusItem`, `NSSlider` wrapper, `NSEvent` monitors)
- Persistent settings via `UserDefaults` + JSON, with `v1 → v2` schema migration
- `ServiceManagement` (`SMAppService.mainApp`) for login-item support
- Build script generates `.icns` and bundle layout manually — no Xcode project required

### Project layout

```
Sources/Sesame/
  main.swift               # AppDelegate, window plumbing, hot corner monitor
  LauncherView.swift       # Full-screen grid, search field, hint badges, theming
  LauncherModel.swift      # App list, filtering, hint mode state machine
  SettingsView.swift       # Sidebar settings (General / Hidden / Groups / About)
  AppSettings.swift        # Persisted preferences + adaptive TileMetrics
  ColorTheme.swift         # 5-theme palette definitions
  HotkeyRecorder.swift     # NSEvent-based key combo capture
  LaunchAtLogin.swift      # SMAppService wrapper
  Localization.swift       # zh / en string dictionary
  ApplicationScanner.swift # Filesystem scan + file watcher
  AppIconCache.swift       # NSWorkspace icon cache
  TickedSlider.swift       # Native NSSlider with tick marks
  HintCoordinator.swift    # 1- and 2-letter code generation
  CustomGroupEditorView.swift # Drag-and-drop group editor
scripts/build_app.sh       # Build + package + iconset
```

---

## Roadmap

- [ ] **Polish the Groups settings page** — better drag-and-drop affordances,
  clearer empty / hover / selected states, smoother in-place editing of group
  names, and an interaction model that scales to dozens of groups.
- [ ] Spotlight / Raycast-style fuzzy ranking (currently substring match only)
- [ ] Quick-action plugins (web search, math, clipboard history)
- [ ] iCloud sync for groups + hidden lists

Contributions welcome — open an issue first to discuss larger changes.

---

## License

© Chaordex Technologies Ltd. 2024–2026. All rights reserved.

[chaordex.com](https://www.chaordex.com)
