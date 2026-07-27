# Homebrew

Justty ships via the personal tap [`0x96f/homebrew-justty`](https://github.com/0x96f/homebrew-justty) (not official `homebrew-cask` — the app is self-signed / not notarized).

## Install

Homebrew 6+ requires trusting third-party taps before install:

```bash
brew trust --tap 0x96f/justty
brew tap 0x96f/justty
brew install --cask justty
```

The cask clears Gatekeeper quarantine in `postflight`, so brew users should not need the manual `xattr` step.

## Maintainer: auto-bump on release

The [release workflow](../.github/workflows/release.yml) updates `Casks/justty.rb` (`version` + `sha256`) after each `v*` tag when this secret is set:

| Secret               | Purpose                                                                           |
| -------------------- | --------------------------------------------------------------------------------- |
| `HOMEBREW_TAP_TOKEN` | PAT (classic or fine-grained) with **contents: write** on `0x96f/homebrew-justty` |

Create a fine-grained token scoped to that repo only, then:

```bash
gh secret set HOMEBREW_TAP_TOKEN --repo 0x96f/justty
```

If the secret is missing, the release still publishes the zip and skips the cask bump with a warning.
