#!/bin/zsh
# Builds ColorPick.app (menu bar only, no Dock icon) in this folder.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
APP=ColorPick.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/ColorPick "$APP/Contents/MacOS/ColorPick"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>ColorPick</string>
  <key>CFBundleIdentifier</key><string>com.lorenzo.colorpick</string>
  <key>CFBundleExecutable</key><string>ColorPick</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST
codesign --force --sign - "$APP"
echo "Built $PWD/$APP"
