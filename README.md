<p align="center">
  <img src="images/logo.png" alt="JusTTY" width="64">
</p>
<h1 align="center">JusTTY</h1>

<p align="center">
  <img src="images/screenshot.png" alt="JusTTY" width="640">
</p>

A simple native macOS terminal built with Swift and [libghostty](https://github.com/egoist-labs/libghostty-spm). It’s intentionally minimal - meant for quick commands, not as a full-time replacement for your main terminal.

## Features

- Real PTY shells via Ghostty’s Metal renderer
- Tabs (⌘T / ⌘W, ⌘⇧[ / ⌘⇧])
- Color themes from the GhosttyTheme catalog
- Font family, size, weight, and line height
- Window padding, starting position, and character-grid size

## Requirements

- macOS 15.6+
- Xcode 16+ (with Swift 5 / macOS SDK)

## Setup

```bash
git clone --recurse-submodules <your-repo-url> justty
cd justty
open justty.xcodeproj
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

Build and run the **justty** scheme. App sandbox is **off** so Ghostty can spawn a real shell (`.exec`).

## License

MIT
