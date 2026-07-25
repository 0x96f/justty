# Troubleshooting

## Gatekeeper blocks the app

Release builds are unsigned. On first open, macOS may refuse to launch the app.

**Recommended:** right-click (or Control-click) `Justty.app` → **Open** → **Open** again. Once is enough.

**Alternative:**

```bash
xattr -dr com.apple.quarantine /path/to/Justty.app
open /path/to/Justty.app
```

See also the Unsigned builds section in the [README](../README.md).

## Ghostty packages fail to resolve / missing submodule

The app depends on `Vendor/libghostty-spm`. After a clone without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

Then reopen `justty.xcodeproj` and build the **justty** scheme.

## Stale libghostty after a submodule bump

If the binary framework looks wrong after updating `Vendor/libghostty-spm`, clean DerivedData for the project (or Product → Clean Build Folder in Xcode) and rebuild.

## Shells fail / no PTY

App sandbox must stay **off** (`ENABLE_APP_SANDBOX = NO`). Justty uses Ghostty’s `.exec` backend to spawn a real login shell; enabling the sandbox breaks that.
