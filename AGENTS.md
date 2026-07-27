# Justty

## Docs

- [docs/FEATURES.md](docs/FEATURES.md) - user-facing feature inventory (tabs, settings, shortcuts, fixed Ghostty options)
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Gatekeeper, submodules, DerivedData, sandbox
- [docs/SIGNING.md](docs/SIGNING.md) - stable self-signed release identity + CI secrets
- [docs/HOMEBREW.md](docs/HOMEBREW.md) - personal tap install + `HOMEBREW_TAP_TOKEN` for cask bumps

## Building

- Open `justty.xcodeproj` in Xcode 16+
- Select the **justty** scheme and run
- App sandbox is **off** so Ghostty `.exec` can spawn a real login shell
- Requires the `Vendor/libghostty-spm` git submodule (`git submodule update --init --recursive`)

## Testing

- Host unit tests live in `justtyTests/` (Swift Testing)
- Run: `xcodebuild -project justty.xcodeproj -scheme justty -destination 'platform=macOS' test`

## Code Conventions

- SwiftUI owns the app shell (windows, tabs, settings menus)
- The host owns tabs, settings, and chrome; libghostty owns VT parsing and Metal rendering
- Comment _why_ on host↔lib contracts (tab parking, keybind clear, sandbox off) - not just _what_
- Keep sources layered under `justty/{App,Terminal,Tabs,Settings,Window}`

### Source map

| Layer    | Path               | Owns                                             |
| -------- | ------------------ | ------------------------------------------------ |
| App      | `justty/App/`      | Entry, window group, menu commands, constants    |
| Terminal | `justty/Terminal/` | Sessions, Ghostty config/host views, parking     |
| Tabs     | `justty/Tabs/`     | TabManager, tab bar, content layout              |
| Settings | `justty/Settings/` | AppSettings, themes, fonts, shortcuts UI/catalog |
| Window   | `justty/Window/`   | Chrome, geometry, drag region                    |

### Host↔lib contracts

- **Sandbox off + `.exec`** - Real PTY login shells. Enabling the sandbox breaks spawning.
- **Host owns config** - Justty builds `TerminalConfiguration`; the controller does not load a separate Ghostty config file.
- **`keybind=clear` then catalog** - Clears Ghostty defaults so ⌘T / ⌘W stay with SwiftUI menus; terminal binds come from `ShortcutsCatalog`.
- **Tab parking** - Inactive tabs stay mounted off-screen (`TerminalParkingView`) so libghostty keeps draining exec events.

## Updating Libghostty

- Bump the `Vendor/libghostty-spm` submodule intentionally (pin a known tag/commit)
- Clean DerivedData / rebuild after bumps to avoid stale binary frameworks
