# Justty

## Building

- Open `justty.xcodeproj` in Xcode 16+
- Select the **justty** scheme and run
- App sandbox is **off** so Ghostty `.exec` can spawn a real login shell
- Requires the `Vendor/libghostty-spm` git submodule (`git submodule update --init --recursive`)

## Code Conventions

- SwiftUI owns the app shell (windows, tabs, settings menus)
- The host owns tabs, settings, and chrome; libghostty owns VT parsing and Metal rendering
- Comment _why_ on host↔lib contracts (tab parking, keybind clear, sandbox off) - not just _what_
- Keep sources layered under `justty/{App,Terminal,Tabs,Settings,Window}`

## Updating Libghostty

- Bump the `Vendor/libghostty-spm` submodule intentionally (pin a known tag/commit)
- Clean DerivedData / rebuild after bumps to avoid stale binary frameworks
