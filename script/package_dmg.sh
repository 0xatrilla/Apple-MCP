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
cp -R "$ROOT/node_modules" "$RESOURCES/dist/node_modules"

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

if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  IDENTITY="$(security find-identity -v -p codesigning | awk -F'\"' '/Developer ID Application/ { print $2; exit }')"
  codesign --force --options runtime --timestamp --sign "$IDENTITY" "$MACOS/$HELPER_NAME"
  codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP_BUNDLE"
else
  codesign --force --deep --sign - "$APP_BUNDLE"
fi

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
spctl --assess --type execute --verbose "$APP_BUNDLE" || true

mkdir -p "$DMG_ROOT"
cp -R "$APP_BUNDLE" "$DMG_ROOT/$APP_NAME.app"
ln -s /Applications "$DMG_ROOT/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "$DMG_PATH"
