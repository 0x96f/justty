# Justty features

Justty is a minimal native macOS terminal (SwiftUI + [libghostty](https://github.com/Lakr233/libghostty-spm)). It targets quick commands, not full Ghostty parity. Requires macOS 15.6+.

## Windows & tabs

- **New window** - ⌘N opens another main window.
- **Tab bar** - Titles, per-tab close, **+** (new tab), gear (Settings). Overflowing tabs scroll with left/right arrows (and stay clear of the trailing buttons). Empty chrome is draggable (hidden title bar); double-click zooms the window.
- **Shortcuts** - ⌘T new tab, ⌘W close tab, ⌘⇧] / ⌘⇧[ next / previous tab, ⌘⇧← / ⌘⇧→ move tab left / right.
- **Titles** - Tab titles show the foreground command basename (e.g. `node` for `node index.js`), or a program OSC title while that command is running (e.g. Cursor Agent), and the login shell when idle. By default titles are prefixed with the cwd basename (`dir - node` / `dir - zsh`); toggle in Settings → Window.
- **New tab directory** - ⌘T / **+** open in the active tab’s working directory (usually the shell process cwd; OSC 7 when the shell emits it). New windows and replacement tabs after shell exit start in `$HOME`.
- **Close with running command** - Closing a tab that has a foreground process prompts for confirmation (toggle in Settings → Window).
- **Last tab** - Closing the last tab closes the window. If the shell exits on the last tab, a new tab is opened instead.

## Terminal

- **Login shell** - Real PTY via Ghostty `.exec`; shell from the user account (`$SHELL` / passwd), launched as a login shell.
- **Rendering** - Metal surface from libghostty.
- **Bell** - System beep; dock bounce / attention when the app is inactive.
- **URLs** - Terminal URL requests open in the default browser.
- **Find** - ⌘F opens a thin find bar; matches are highlighted in scrollback via Ghostty search. Next/previous from the bar; Esc closes.
- **Font zoom** - ⌘+ / ⌘− change the active tab’s size temporarily; ⌘0 resets to the Settings font size. Changing Settings (or Reload Configuration) also clears zoom and applies the new Settings size (not written to `config.yml`).
- **Theme chrome** - Window / tab bar background and app appearance follow the selected color theme.

## Settings

Open with ⌘, or the tab-bar gear. Values persist in `~/.config/justty/config.yml` (created with defaults on first launch). Changing Settings writes the file immediately; after editing the file by hand, use **File → Reload Configuration** (⌘⇧,). Window size/position apply to **new** windows only.

| Section                | Controls                                                                                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Theme**              | GhosttyTheme catalog, grouped Light / Dark. Defaults: GitHub Light Default / GitHub Dark Default.                                                                   |
| **Font**               | Family (System or detected monospace), size 8–32 px (default 13), line height 0.8–2.0×, weight Regular / Medium / Semibold / Bold.                                  |
| **Window**             | Confirm before closing tabs with a running command (default on); padding 0–64 px; starting X×Y from the top-left of the main screen (clamped to the visible frame); size as character grid (cols 20–500, rows 5–200; default 80×24). |
| **Keyboard Shortcuts** | Opens a read-only sheet (same list as below).                                                                                                                       |
| **Configuration**      | **Open Configuration…** opens `config.yml` in the default text editor (Ghostty-style).                                                                              |

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
| Move Tab Left     | ⌘⇧←  |
| Move Tab Right    | ⌘⇧→  |
| Find              | ⌘F   |
| Larger            | ⌘+   |
| Smaller           | ⌘−   |
| Actual Size       | ⌘0   |
| Reload Configuration | ⌘⇧, |

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
