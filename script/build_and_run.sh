#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="AppleAppsControl"
BUNDLE_ID="com.callummatthews.apple-apps-mcp"
BUNDLE_VERSION="${BUNDLE_VERSION:-0.1.1}"
BUNDLE="$ROOT/dist/$APP_NAME.app"
HELPER_BUNDLE="$ROOT/dist/AppleAppsHelper.app"
CONTENTS="$BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
EXECUTABLE="$MACOS/$APP_NAME"
HELPER_EXECUTABLE="$MACOS/AppleAppsHelper"
INFO_PLIST="$CONTENTS/Info.plist"
HELPER_CONTENTS="$HELPER_BUNDLE/Contents"
HELPER_MACOS="$HELPER_CONTENTS/MacOS"
HELPER_APP_EXECUTABLE="$HELPER_MACOS/AppleAppsHelper"
HELPER_INFO_PLIST="$HELPER_CONTENTS/Info.plist"

cd "$ROOT"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

if [[ ! -d node_modules ]]; then
  npm install
fi
npm run build
swift build
BUILD_EXECUTABLE="$(swift build --show-bin-path)/$APP_NAME"
BUILD_HELPER="$(swift build --show-bin-path)/AppleAppsHelper"

rm -rf "$BUNDLE"
mkdir -p "$MACOS" "$CONTENTS/Resources"
cp "$BUILD_EXECUTABLE" "$EXECUTABLE"
cp "$BUILD_HELPER" "$HELPER_EXECUTABLE"
chmod +x "$EXECUTABLE"
chmod +x "$HELPER_EXECUTABLE"

ICON_SRC="$ROOT/Swift/App/Resources/AppIcon.png"
if [[ -f "$ICON_SRC" ]]; then
  cp "$ICON_SRC" "$CONTENTS/Resources/AppIcon.png"
  ICONSET="$(mktemp -d)/AppIcon.iconset"
  mkdir -p "$ICONSET"
  for sz in 16 32 128 256 512; do
    sips -z "$sz" "$sz" "$ICON_SRC" --out "$ICONSET/icon_${sz}x${sz}.png" >/dev/null 2>&1
    sips -z "$((sz*2))" "$((sz*2))" "$ICON_SRC" --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null 2>&1
  done
  iconutil -c icns "$ICONSET" -o "$CONTENTS/Resources/AppIcon.icns" >/dev/null 2>&1 || true
  rm -rf "$(dirname "$ICONSET")"
fi
cat > "$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>Apple Apps MCP</string>
  <key>CFBundleDisplayName</key>
  <string>Apple Apps MCP</string>
  <key>CFBundleVersion</key>
  <string>$BUNDLE_VERSION</string>
  <key>CFBundleShortVersionString</key>
  <string>$BUNDLE_VERSION</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSCalendarsFullAccessUsageDescription</key>
  <string>Apple Apps MCP needs calendar access to expose Calendar tools to your selected AI apps.</string>
  <key>NSRemindersFullAccessUsageDescription</key>
  <string>Apple Apps MCP needs reminders access to expose Reminders tools to your selected AI apps.</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>Apple Apps MCP uses Automation to control Apple apps you enable, including Notes, Mail, Music, and Shortcuts.</string>
</dict>
</plist>
PLIST

rm -rf "$HELPER_BUNDLE"
mkdir -p "$HELPER_MACOS" "$HELPER_CONTENTS/Resources"
cp "$BUILD_HELPER" "$HELPER_APP_EXECUTABLE"
chmod +x "$HELPER_APP_EXECUTABLE"
cat > "$HELPER_INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>AppleAppsHelper</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID.helper</string>
  <key>CFBundleName</key>
  <string>Apple Apps MCP Helper</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>LSBackgroundOnly</key>
  <true/>
  <key>NSCalendarsFullAccessUsageDescription</key>
  <string>Apple Apps MCP Helper needs calendar access so MCP clients can read and create Calendar events.</string>
  <key>NSRemindersFullAccessUsageDescription</key>
  <string>Apple Apps MCP Helper needs reminders access so MCP clients can read and create reminders.</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>Apple Apps MCP Helper uses Automation for enabled Apple app tools.</string>
</dict>
</plist>
PLIST

open_app() {
  /usr/bin/open -n "$BUNDLE"
}

case "$MODE" in
  run)
    open_app
    echo "Launched $BUNDLE"
    ;;
  --debug|debug)
    lldb -- "$EXECUTABLE"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    /usr/bin/open -n "$BUNDLE"
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    echo "$APP_NAME is running"
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
