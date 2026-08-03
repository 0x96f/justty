#!/usr/bin/env bash
# Create (if needed) the Justty Self-Signed identity and print/set CI secrets.
# See docs/SIGNING.md.
set -euo pipefail

IDENTITY="Justty Self-Signed"
KEYCHAIN="${HOME}/Library/Keychains/login.keychain-db"
P12_PASSWORD="$(openssl rand -hex 24)"
EXPORT_P12="$(mktemp)"
EXPORT_B64="$(mktemp)"
TMP=""

# OpenSSL 3 defaults (AES/PBKDF2/SHA256 MAC) break macOS `security import`.
# Force classic PBE so SecKeychainItemImport accepts the PKCS#12.
pkcs12_export() {
  local out="$1" pass="$2"
  openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
    -name "${IDENTITY}" -out "$out" -passout "pass:${pass}" \
    -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
}

cleanup() {
  rm -f "$EXPORT_P12" "$EXPORT_B64"
  [[ -n "$TMP" ]] && rm -rf "$TMP"
}

keep_exports() {
  # Leave P12/base64 for manual gh secret set; still remove openssl scratch.
  [[ -n "$TMP" ]] && rm -rf "$TMP"
  TMP=""
}

trap cleanup EXIT

print_fingerprint() {
  local cert_pem="$1"
  local fp
  fp="$(openssl x509 -in "$cert_pem" -noout -fingerprint -sha256 \
    | awk -F= '{print toupper($2)}' | tr -d ':')"
  echo "SHA-256 fingerprint: ${fp}"
  echo "If you rotated the identity, update the EXPECTED fingerprint in"
  echo ".github/workflows/release.yml and the docs (README / SIGNING.md)."
}

write_secrets_help() {
  base64 -i "$EXPORT_P12" | tr -d '\n' > "$EXPORT_B64"
  echo
  echo "Set these repo secrets:"
  echo "  SIGNING_P12_PASSWORD = (shown once below)"
  echo "  SIGNING_P12_BASE64   = contents of the base64 file"
  echo
  echo "password: ${P12_PASSWORD}"
  echo "base64 file: ${EXPORT_B64}"
  echo

  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    read -r -p "Push secrets to the current gh repo now? [y/N] " ans
    if [[ "${ans}" =~ ^[Yy]$ ]]; then
      gh secret set SIGNING_P12_BASE64 < "$EXPORT_B64"
      gh secret set SIGNING_P12_PASSWORD --body "$P12_PASSWORD"
      echo "Secrets set."
      exit 0
    fi
  fi

  echo "Manual:"
  echo "  gh secret set SIGNING_P12_BASE64 < ${EXPORT_B64}"
  echo "  gh secret set SIGNING_P12_PASSWORD --body '${P12_PASSWORD}'"
  echo
  echo "Delete ${EXPORT_P12} and ${EXPORT_B64} when done — they hold the private key."
  trap keep_exports EXIT
}

if ! security find-identity -p codesigning 2>/dev/null | grep -q "${IDENTITY}"; then
  echo "Creating ${IDENTITY}…"
  TMP="$(mktemp -d)"

  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
    -subj "/CN=${IDENTITY}" \
    -addext "basicConstraints=critical,CA:false" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning"

  print_fingerprint "$TMP/cert.pem"

  # CI P12 uses a random password; import copy uses a throwaway local password.
  pkcs12_export "$EXPORT_P12" "$P12_PASSWORD"
  LOCAL_P12_PASS="$(openssl rand -hex 12)"
  pkcs12_export "$TMP/justty.p12" "$LOCAL_P12_PASS"

  security import "$TMP/justty.p12" -k "$KEYCHAIN" \
    -P "$LOCAL_P12_PASS" -T /usr/bin/codesign

  echo "Imported into login keychain."
  write_secrets_help
  exit 0
fi

echo "Found existing identity: ${IDENTITY}"
CERT_PEM="$(mktemp)"
if security find-certificate -c "${IDENTITY}" -p >"$CERT_PEM" 2>/dev/null; then
  print_fingerprint "$CERT_PEM"
fi
rm -f "$CERT_PEM"

echo
echo "Refusing to bulk-export the login keychain (that can pack unrelated identities)."
echo "To refresh CI secrets, export only this identity:"
echo
echo "  1. Open Keychain Access → login → My Certificates"
echo "  2. Select \"${IDENTITY}\" → File → Export Items…"
echo "  3. Save as PKCS#12 (.p12), then:"
echo
echo "     P12_PASSWORD=\"\$(openssl rand -hex 24)\"; echo \"password: \$P12_PASSWORD\""
echo "     # use that password in the Keychain Access export dialog"
echo "     base64 -i /path/to/Justty.p12 | tr -d '\\n' > /tmp/signing.p12.base64"
echo "     gh secret set SIGNING_P12_BASE64 < /tmp/signing.p12.base64"
echo "     gh secret set SIGNING_P12_PASSWORD --body \"\$P12_PASSWORD\""
echo "     rm -f /tmp/signing.p12.base64 /path/to/Justty.p12"
echo
echo "Or keep the P12 produced when the identity was first created."
exit 1
