#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Apple MCP"
EXECUTABLE_NAME="AppleAppsControl"
HELPER_NAME="AppleAppsHelper"
BUNDLE_ID="com.callummatthews.apple-mcp"
VERSION="${VERSION:-0.1.0}"
DIST_DIR="$ROOT/dist"
PACKAGE_DIR="$DIST_DIR/package"
APP_BUNDLE="$PACKAGE_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
DMG_ROOT="$DIST_DIR/dmg-root"
DMG_PATH="$DIST_DIR/Apple-MCP-$VERSION.dmg"

cd "$ROOT"

rm -rf "$PACKAGE_DIR" "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$MACOS" "$RESOURCES"

npm install
npm run build
swift build -c release

BUILD_BIN="$(swift build -c release --show-bin-path)"
cp "$BUILD_BIN/$EXECUTABLE_NAME" "$MACOS/$EXECUTABLE_NAME"
cp "$BUILD_BIN/$HELPER_NAME" "$MACOS/$HELPER_NAME"
chmod +x "$MACOS/$EXECUTABLE_NAME" "$MACOS/$HELPER_NAME"

cp "$ROOT/Swift/App/Resources/AppIcon.icns" "$RESOURCES/AppIcon.icns"
mkdir -p "$RESOURCES/dist"
cp -R "$ROOT/dist/"{adapters,config,mcp,services} "$RESOURCES/dist/"

# Bundle a PRODUCTION-ONLY node_modules. The dev tree ships unsigned native
# binaries (esbuild, rolldown, lightningcss, fsevents) that fail notarization
# and aren't needed at runtime. Stage a clean prod install instead.
PRODSTAGE="$DIST_DIR/prod-deps"
rm -rf "$PRODSTAGE"
mkdir -p "$PRODSTAGE"
cp "$ROOT/package.json" "$ROOT/package-lock.json" "$PRODSTAGE/"
( cd "$PRODSTAGE" && npm ci --omit=dev --ignore-scripts )
cp -R "$PRODSTAGE/node_modules" "$RESOURCES/dist/node_modules"
rm -rf "$PRODSTAGE"

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$EXECUTABLE_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>26.0</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSCalendarsFullAccessUsageDescription</key>
  <string>Apple MCP needs calendar access to expose Calendar tools to your selected AI apps.</string>
  <key>NSRemindersFullAccessUsageDescription</key>
  <string>Apple MCP needs reminders access to expose Reminders tools to your selected AI apps.</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>Apple MCP uses Automation to control Apple apps you enable, including Notes, Mail, Music, and Shortcuts.</string>
</dict>
</plist>
PLIST

# ---------------------------------------------------------------------------
# Code signing
#
# Notarization requires a "Developer ID Application" certificate. Override the
# auto-detected identity with SIGN_IDENTITY if you have multiple.
# ---------------------------------------------------------------------------
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
if [[ -z "$SIGN_IDENTITY" ]] && security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  SIGN_IDENTITY="$(security find-identity -v -p codesigning | awk -F'\"' '/Developer ID Application/ { print $2; exit }')"
fi

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "Signing with: $SIGN_IDENTITY"
  # Sign every embedded Mach-O binary (native .node addons, dylibs, helper
  # executables in node_modules) inside-out before signing the bundle.
  while IFS= read -r -d '' f; do
    if file "$f" | grep -q "Mach-O"; then
      codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$f"
    fi
  done < <(find "$RESOURCES" -type f \( -name "*.node" -o -name "*.dylib" -o -perm -u+x \) -print0)

  # Sign inner executables, then the bundle (inside-out).
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$MACOS/$HELPER_NAME"
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$MACOS/$EXECUTABLE_NAME"
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_BUNDLE"
else
  echo "WARNING: No 'Developer ID Application' certificate found." >&2
  echo "         Falling back to ad-hoc signing. This build CANNOT be notarized." >&2
  echo "         Create a Developer ID Application cert (Xcode > Settings > Accounts" >&2
  echo "         > Manage Certificates > + Developer ID Application) to enable notarization." >&2
  codesign --force --deep --sign - "$APP_BUNDLE"
fi

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
spctl --assess --type execute --verbose "$APP_BUNDLE" || true

# ---------------------------------------------------------------------------
# Notarization
#
# Provide credentials via ONE of:
#   - NOTARY_PROFILE=<keychain-profile-name>   (created with `notarytool store-credentials`)
#   - NOTARY_APPLE_ID + NOTARY_PASSWORD + NOTARY_TEAM_ID  (app-specific password)
#
# We notarize the signed .app (zipped), staple it, then build & notarize the
# DMG, and staple that too — so both the app and the DMG pass Gatekeeper offline.
# ---------------------------------------------------------------------------
notarytool_creds() {
  if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    echo "--keychain-profile" "$NOTARY_PROFILE"
  elif [[ -n "${NOTARY_APPLE_ID:-}" && -n "${NOTARY_PASSWORD:-}" && -n "${NOTARY_TEAM_ID:-}" ]]; then
    echo "--apple-id" "$NOTARY_APPLE_ID" "--password" "$NOTARY_PASSWORD" "--team-id" "$NOTARY_TEAM_ID"
  else
    echo ""
  fi
}

CREDS="$(notarytool_creds)"
NOTARIZE=0
if [[ -n "$SIGN_IDENTITY" && -n "$CREDS" ]]; then
  NOTARIZE=1
fi

if [[ "$NOTARIZE" == "1" ]]; then
  echo "Notarizing app bundle..."
  APP_ZIP="$DIST_DIR/$APP_NAME.zip"
  rm -f "$APP_ZIP"
  /usr/bin/ditto -c -k --keepParent "$APP_BUNDLE" "$APP_ZIP"
  xcrun notarytool submit "$APP_ZIP" $CREDS --wait
  xcrun stapler staple "$APP_BUNDLE"
  rm -f "$APP_ZIP"
else
  echo "Skipping notarization (no credentials and/or no Developer ID identity)." >&2
fi

mkdir -p "$DMG_ROOT"
cp -R "$APP_BUNDLE" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

if [[ "$NOTARIZE" == "1" ]]; then
  echo "Notarizing DMG..."
  xcrun notarytool submit "$DMG_PATH" $CREDS --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
  echo "Notarized & stapled: $DMG_PATH"
fi

echo "$DMG_PATH"
