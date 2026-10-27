import AppKit

// MARK: - History

@MainActor
final class ColorHistory {
  private let key = "history"
  private let maxCount = 20

  var colors: [String] {
    get { UserDefaults.standard.stringArray(forKey: key) ?? [] }
    set { UserDefaults.standard.set(newValue, forKey: key) }
  }

  /// Puts the color on top, removing any previous copy of it.
  func add(_ hex: String) {
    var list = colors.filter { $0 != hex }
    list.insert(hex, at: 0)
    colors = Array(list.prefix(maxCount))
  }

  func clear() { colors = [] }
}

// MARK: - Color helpers

extension NSColor {
  /// "#RRGGBB" in sRGB, which is what the web and design tools expect.
  var hexString: String? {
    guard let c = usingColorSpace(.sRGB) else { return nil }
    func byte(_ v: CGFloat) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
    return String(format: "#%02X%02X%02X", byte(c.redComponent), byte(c.greenComponent), byte(c.blueComponent))
  }

  convenience init?(hex: String) {
    guard let v = UInt32(hex.dropFirst(), radix: 16), hex.count == 7 else { return nil }
    self.init(
      srgbRed: CGFloat((v >> 16) & 0xFF) / 255,
      green: CGFloat((v >> 8) & 0xFF) / 255,
      blue: CGFloat(v & 0xFF) / 255,
      alpha: 1)
  }
}

func swatch(_ color: NSColor) -> NSImage {
  let image = NSImage(size: NSSize(width: 14, height: 14), flipped: false) { rect in
    let path = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 3, yRadius: 3)
    color.setFill()
    path.fill()
    NSColor.black.withAlphaComponent(0.25).setStroke()
    path.lineWidth = 1
    path.stroke()
    return true
  }
  image.isTemplate = false
  return image
}

func copyToClipboard(_ text: String) {
  NSPasteboard.general.clearContents()
  NSPasteboard.general.setString(text, forType: .string)
}

// MARK: - App

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  private let history = ColorHistory()
  private let sampler = NSColorSampler()

  func applicationDidFinishLaunching(_ notification: Notification) {
    statusItem.button?.image = NSImage(systemSymbolName: "eyedropper", accessibilityDescription: "Color Pick")
    let menu = NSMenu()
    menu.delegate = self
    statusItem.menu = menu
  }

  // Rebuilt every time it opens, so it always reflects the latest history.
  func menuNeedsUpdate(_ menu: NSMenu) {
    menu.removeAllItems()

    let pick = NSMenuItem(title: "Pick Color", action: #selector(pickColor), keyEquivalent: "p")
    pick.image = NSImage(systemSymbolName: "eyedropper", accessibilityDescription: nil)
    pick.target = self
    menu.addItem(pick)
    menu.addItem(.separator())

    let colors = history.colors
    if colors.isEmpty {
      let empty = NSMenuItem(title: "No colors yet", action: nil, keyEquivalent: "")
      empty.isEnabled = false
      menu.addItem(empty)
    } else {
      for (index, hex) in colors.enumerated() {
        let item = NSMenuItem(
          title: hex, action: #selector(copyColor(_:)),
          keyEquivalent: index < 9 ? "\(index + 1)" : "")
        item.representedObject = hex
        item.target = self
        if let color = NSColor(hex: hex) { item.image = swatch(color) }
        menu.addItem(item)
      }
      menu.addItem(.separator())
      let clear = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
      clear.target = self
      menu.addItem(clear)
    }

    menu.addItem(.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
  }

  @objc private func pickColor() {
    // Let the menu close before the loupe appears.
    DispatchQueue.main.async { [self] in
      sampler.show { [weak self] color in
        guard let color, let hex = color.hexString else { return }
        DispatchQueue.main.async {
          copyToClipboard(hex)
          self?.history.add(hex)
          self?.flash(color)
        }
      }
    }
  }

  @objc private func copyColor(_ sender: NSMenuItem) {
    guard let hex = sender.representedObject as? String else { return }
    copyToClipboard(hex)
    history.add(hex)
  }

  @objc private func clearHistory() { history.clear() }

  /// Briefly shows the picked color in the menu bar as confirmation of the copy.
  private func flash(_ color: NSColor) {
    guard let button = statusItem.button else { return }
    let original = button.image
    button.image = swatch(color)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { button.image = original }
  }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
