# Justty features

Justty is a minimal native macOS terminal (SwiftUI + [libghostty](https://github.com/Lakr233/libghostty-spm)). It targets quick commands, not full Ghostty parity. Requires macOS 15.6+.

## Windows & tabs

- **New window** - ⌘N opens another main window.
- **Tab bar** - Titles, per-tab close, **+** (new tab), gear (Settings). Background is draggable (hidden title bar).
- **Shortcuts** - ⌘T new tab, ⌘W close tab, ⌘⇧] / ⌘⇧[ next / previous tab.
- **Titles** - Tab titles follow the shell / program title from the terminal.
- **Close with running command** - Closing a tab that has a foreground process prompts for confirmation.
- **Last tab** - Closing the last tab closes the window. If the shell exits on the last tab, a new tab is opened instead.

## Terminal

- **Login shell** - Real PTY via Ghostty `.exec`; shell from the user account (`$SHELL` / passwd), launched as a login shell.
- **Rendering** - Metal surface from libghostty.
- **Bell** - System beep; dock bounce / attention when the app is inactive.
- **URLs** - Terminal URL requests open in the default browser.
- **Theme chrome** - Window / tab bar background and app appearance follow the selected color theme.

## Settings

Open with ⌘, or the tab-bar gear. Values persist in `UserDefaults` and refresh live sessions (theme, font, padding). Window size/position apply to **new** windows only.

| Section                | Controls                                                                                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Theme**              | GhosttyTheme catalog, grouped Light / Dark. Defaults: GitHub Light Default / GitHub Dark Default.                                                                   |
| **Font**               | Family (System or detected monospace), size 8–32 px (default 13), line height 0.8–2.0×, weight Regular / Medium / Semibold / Bold.                                  |
| **Window**             | Padding 0–64 px; starting X×Y from the top-left of the main screen (clamped to the visible frame); size as character grid (cols 20–500, rows 5–200; default 80×24). |
| **Keyboard Shortcuts** | Opens a read-only sheet (same list as below).                                                                                                                       |

## Keyboard shortcuts

Source of truth: `justty/Settings/ShortcutsCatalog.swift` (also drives Ghostty terminal keybinds after `keybind=clear`).

### Window & Tabs

| Action            | Keys |
| ----------------- | ---- |
| New Window        | ⌘N   |
| New Tab           | ⌘T   |
| Close Tab         | ⌘W   |
| Show Next Tab     | ⌘⇧]  |
| Show Previous Tab | ⌘⇧[  |

### Terminal

| Action               | Keys |
| -------------------- | ---- |
| Move Word Left       | ⌥←   |
| Move Word Right      | ⌥→   |
| Move to Line Start   | ⌘←   |
| Move to Line End     | ⌘→   |
| Delete to Line Start | ⌘⌫   |
| Copy                 | ⌘C   |
| Paste                | ⌘V   |
| Scroll to Top        | ⌘↖   |
| Scroll to Bottom     | ⌘↘   |
| Scroll Page Up       | ⌘⇞   |
| Scroll Page Down     | ⌘⇟   |

Window & tab shortcuts are handled by the app menus. Terminal shortcuts are Ghostty keybinds installed by the host.

## Fixed Ghostty behavior

Not exposed in Settings (host-owned defaults):

- Scrollback limit ~4 MB
- Scrollbar never shown
- Option key as Alt
- Clipboard: read ask, write allow, paste protection on
- Shell integration off
- Blinking block cursor
- `TERM=xterm-256color`, `COLORTERM=truecolor`, `TERM_PROGRAM=Justty` (+ version when available)

## Out of scope

Justty does not expose (among other Ghostty capabilities):

- Splits / panes
- Inspector
- Custom `ghostty.conf` / profiles
- Remappable shortcuts in the UI
- Sandboxed / in-memory backends (app sandbox stays off for real shells)
