# Homebrew

Justty ships via the [0x96f Forge tap](https://github.com/0x96f/homebrew-forge).

## Install

```bash
brew install --cask 0x96f/forge/justty
```

The cask clears Gatekeeper quarantine in `postflight_steps`, so brew users should not need the manual `xattr` step. Builds are still self-signed — verify the leaf SHA-256 fingerprint (see [SIGNING.md](SIGNING.md)).

## Maintainer: auto-bump on release

The [release workflow](../.github/workflows/release.yml) updates `Casks/justty.rb` (`version` + `sha256`) after each `v*` tag when this secret is set:

| Secret               | Purpose                                                                           |
| -------------------- | --------------------------------------------------------------------------------- |
| `HOMEBREW_TAP_TOKEN` | PAT (classic or fine-grained) with **contents: write** on `0x96f/homebrew-forge` |

Create a fine-grained token scoped to that repo only, then:

```bash
gh secret set HOMEBREW_TAP_TOKEN --repo 0x96f/justty
```

If the secret is missing, the release still publishes the zip and skips the cask bump with a warning.
