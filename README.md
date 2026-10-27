<p align="center"><img src="Resources/AppIcon.png" width="160" alt="ColorPick icon"></p>

# ColorPick

A tiny macOS menu bar app: pick a color from anywhere on screen and its HEX code lands on your clipboard.

## Features

- **Pick Color**: opens the system magnifier; click any point on screen and the color is copied as `#RRGGBB` (sRGB).
- **History**: the last 20 colors are listed in the menu, each with a swatch. Click one to copy it to the clipboard. The first 9 have the 1–9 shortcuts.
- **Clear History** empties the list.

History is kept across launches.

## Requirements

- macOS 14 or later
- Xcode or the Command Line Tools (Swift 6)

## Build

```bash
./build.sh
open ColorPick.app
```

To start it at login, copy `ColorPick.app` to `/Applications` and add it under System Settings → General → Login Items.

## Icon

The icon is drawn in code by `scripts/make-icon.swift`, using the [SHAP](https://github.com/shap/shap) `red_blue` colormap. To regenerate it:

```bash
swift scripts/make-icon.swift Resources/AppIcon.png && ./build.sh
```

## Credits

Inspired by the [Color Picker](https://www.raycast.com/thomas/color-picker) extension for Raycast (MIT license).
