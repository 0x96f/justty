# Signing

Release builds are signed with a **stable self-signed identity** called `Justty Self-Signed`. It is not an Apple Developer ID (no paid Apple account). The same identity is used on every CI release so users can verify the signature:

```bash
codesign -dv --verbose=4 Justty.app
# expect Authority=Justty Self-Signed
codesign --verify --verbose=4 Justty.app
```

You create this identity **once**, then export it into two GitHub secrets the release workflow imports.

## Quick path

From the repo root:

```bash
./Script/setup-signing.sh
```

That creates the identity if missing and prints `gh secret set` commands (or runs them if `gh` is authed for the repo).

## 1. Create the identity (once)

```sh
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -keyout /tmp/justty-key.pem -out /tmp/justty-cert.pem \
  -subj "/CN=Justty Self-Signed" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning"

# OpenSSL 3 defaults break macOS `security import` — use classic PBE.
openssl pkcs12 -export -inkey /tmp/justty-key.pem -in /tmp/justty-cert.pem \
  -name "Justty Self-Signed" -out /tmp/justty.p12 -passout pass:justty \
  -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1

security import /tmp/justty.p12 -k ~/Library/Keychains/login.keychain-db \
  -P justty -A -T /usr/bin/codesign

rm -f /tmp/justty-key.pem /tmp/justty-cert.pem /tmp/justty.p12
```

Verify:

```sh
security find-identity -p codesigning | grep "Justty Self-Signed"
```

## 2. GitHub secrets for CI

```sh
P12_PASSWORD="$(openssl rand -hex 24)"; echo "password: $P12_PASSWORD"

security export -t identities -f pkcs12 \
  -k ~/Library/Keychains/login.keychain-db \
  -P "$P12_PASSWORD" -o /tmp/signing.p12
base64 -i /tmp/signing.p12 | tr -d '\n' > /tmp/signing.p12.base64
rm -f /tmp/signing.p12

gh secret set SIGNING_P12_BASE64 < /tmp/signing.p12.base64
gh secret set SIGNING_P12_PASSWORD --body "$P12_PASSWORD"
rm -f /tmp/signing.p12.base64
```

If you lose the secrets but still have the identity in your keychain, re-export (this section). If you lose the identity entirely, recreate it (step 1) and re-do secrets; the Authority string stays `Justty Self-Signed`, but it is a new key.

## Quarantine

Self-signing does not satisfy Gatekeeper for downloads. Homebrew clears quarantine in cask `postflight` — see [HOMEBREW.md](HOMEBREW.md). Manual installs: [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
