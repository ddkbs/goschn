#!/bin/bash
# Builds build/Goschn.app. Set SIGN_IDENTITY to choose a certificate.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --product Goschn
BIN="$(swift build -c release --show-bin-path)/Goschn"
APP="build/Goschn.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Goschn"
cp Resources/Info.plist "$APP/Contents/Info.plist"

swift scripts/make-icon.swift build/AppIcon.iconset
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

# A real certificate keeps the Accessibility permission across updates;
# "-" (ad hoc) works too, but macOS asks again after every rebuild.
if [[ -z "${SIGN_IDENTITY:-}" ]]; then
    SIGN_IDENTITY="$(security find-identity -v -p codesigning | awk '/[0-9]+\) /{print $2; exit}')"
fi
codesign --force --options runtime --sign "${SIGN_IDENTITY:--}" "$APP"
echo "Built $APP"
