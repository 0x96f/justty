# Signing

Release builds are signed with a **stable self-signed identity** called `Justty Self-Signed`. It is not an Apple Developer ID (no paid Apple account). The same identity is used on every CI release so users can verify the signature.

**Do not trust the Authority string alone** — anyone can mint a cert with CN `Justty Self-Signed`. Always check the leaf certificate SHA-256 fingerprint:

```bash
codesign -dv --verbose=4 Justty.app
# expect Authority=Justty Self-Signed
codesign --verify --verbose=4 Justty.app

codesign -d --extract-certificates=/tmp/justty-cert Justty.app
openssl x509 -inform DER -in /tmp/justty-cert0 -noout -fingerprint -sha256
# expect SHA256 Fingerprint=82:9B:F9:9F:A6:C3:28:64:98:C3:57:24:04:3A:F2:CD:71:4B:35:BD:D1:C2:88:B7:D8:86:B6:C2:DD:E2:2C:11
rm -f /tmp/justty-cert*
```

You create this identity **once**, then export it into two GitHub secrets the release workflow imports. CI verifies the same fingerprint (hardcoded `EXPECTED` in [`.github/workflows/release.yml`](../.github/workflows/release.yml)).

## Quick path

From the repo root:

```bash
./Script/setup-signing.sh
```

That creates the identity if missing and prints `gh secret set` commands (or runs them if `gh` is authed for the repo). If the identity already exists, the script prints the fingerprint and instructions to export **only** that identity (it will not bulk-export the keychain).

## 1. Create the identity (once)

Prefer `./Script/setup-signing.sh`. Manual equivalent:

```sh
TMP="$(mktemp -d)"
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
  -subj "/CN=Justty Self-Signed" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning"

openssl x509 -in "$TMP/cert.pem" -noout -fingerprint -sha256
# If rotating: update EXPECTED in .github/workflows/release.yml and the fingerprint
# shown in the README / this doc.

# OpenSSL 3 defaults break macOS `security import` — use classic PBE.
LOCAL_PASS="$(openssl rand -hex 12)"
openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
  -name "Justty Self-Signed" -out "$TMP/justty.p12" -passout "pass:${LOCAL_PASS}" \
  -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1

security import "$TMP/justty.p12" -k ~/Library/Keychains/login.keychain-db \
  -P "$LOCAL_PASS" -T /usr/bin/codesign

rm -rf "$TMP"
```

Verify:

```sh
security find-identity -p codesigning | grep "Justty Self-Signed"
```

## 2. GitHub secrets for CI

Export **only** the Justty identity (Keychain Access → select `Justty Self-Signed` → File → Export Items… as PKCS#12). Do **not** run `security export -t identities` on the whole login keychain — that can pack unrelated private keys into the secret.

```sh
P12_PASSWORD="$(openssl rand -hex 24)"; echo "password: $P12_PASSWORD"
# Use $P12_PASSWORD in the Keychain Access export dialog, then:
base64 -i /path/to/Justty.p12 | tr -d '\n' > /tmp/signing.p12.base64
rm -f /path/to/Justty.p12

gh secret set SIGNING_P12_BASE64 < /tmp/signing.p12.base64
gh secret set SIGNING_P12_PASSWORD --body "$P12_PASSWORD"
rm -f /tmp/signing.p12.base64
```

If you lose the secrets but still have the identity in your keychain, re-export **that identity only** (this section). If you lose the identity entirely, recreate it (step 1), update the fingerprint in the release workflow / README / this doc, then re-do secrets — the Authority string stays `Justty Self-Signed`, but it is a new key.

## Quarantine

Self-signing does not satisfy Gatekeeper for downloads. Homebrew clears quarantine in cask `postflight` — see [HOMEBREW.md](HOMEBREW.md). Manual installs: [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
