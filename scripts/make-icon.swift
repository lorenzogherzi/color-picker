// Renders the app icon as a 1024×1024 PNG.
// Usage: swift scripts/make-icon.swift <output.png>
//
// A segmented color wheel with an eyedropper, colored with the SHAP
// `red_blue` colormap (blue #008BFB → red #FF0051).
import AppKit

let size: CGFloat = 1024
let output = CommandLine.arguments.dropFirst().first ?? "icon.png"

// MARK: - Palette

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
  CGColor(
    srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
    blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

/// SHAP red_blue colormap, sampled at 9 evenly spaced stops.
let shapStops: [UInt32] = [
  0x008BFB, 0x0078F3, 0x4B63E3, 0x7D48CB, 0x9C23AD, 0xC2009B, 0xE00085, 0xF6006C, 0xFF0051,
]

func shap(_ t: CGFloat) -> CGColor {
  let x = min(max(t, 0), 1) * CGFloat(shapStops.count - 1)
  let i = min(Int(x), shapStops.count - 2)
  let a = rgb(shapStops[i]).components!, b = rgb(shapStops[i + 1]).components!
  let f = x - CGFloat(i)
  return CGColor(
    srgbRed: a[0] + (b[0] - a[0]) * f, green: a[1] + (b[1] - a[1]) * f,
    blue: a[2] + (b[2] - a[2]) * f, alpha: 1)
}

func tint(_ c: CGColor, _ amount: CGFloat) -> CGColor {
  let p = c.components!
  return CGColor(
    srgbRed: p[0] + (1 - p[0]) * amount, green: p[1] + (1 - p[1]) * amount,
    blue: p[2] + (1 - p[2]) * amount, alpha: p[3])
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!

func gradient(_ colors: [CGColor]) -> CGGradient {
  CGGradient(colorsSpace: space, colors: colors as CFArray, locations: nil)!
}

// MARK: - Canvas (y-down coordinates)

let rep = NSBitmapImageRep(
  bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
  colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
ctx.translateBy(x: 0, y: size)
ctx.scaleBy(x: 1, y: -1)

/// Fills `path` with a linear gradient running across its bounds from top-left to bottom-right.
func fill(_ path: CGPath, _ g: CGGradient) {
  let box = path.boundingBox
  ctx.saveGState()
  ctx.addPath(path)
  ctx.clip()
  ctx.drawLinearGradient(
    g, start: CGPoint(x: box.minX, y: box.minY), end: CGPoint(x: box.maxX, y: box.maxY), options: [])
  ctx.restoreGState()
}

func withShadow(blur: CGFloat, dy: CGFloat, alpha: CGFloat, _ draw: () -> Void) {
  ctx.saveGState()
  // Context is flipped, so a positive dy here moves the shadow down on screen.
  ctx.setShadow(offset: CGSize(width: 0, height: -dy), blur: blur, color: rgb(0x1A1A40, alpha))
  ctx.beginTransparencyLayer(auxiliaryInfo: nil)
  draw()
  ctx.endTransparencyLayer()
  ctx.restoreGState()
}

// MARK: - Tile

// macOS icon grid: 824pt squircle centered on a 1024 canvas.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
withShadow(blur: 28, dy: 12, alpha: 0.25) {
  fill(tilePath, gradient([rgb(0xFFFFFF), rgb(0xEDEDF2)]))
}

// MARK: - Wheel

let center = CGPoint(x: tile.midX, y: tile.midY)
let outerR: CGFloat = 292
let innerR: CGFloat = 118
let segments = 8

withShadow(blur: 18, dy: 8, alpha: 0.12) {
  for i in 0..<segments {
    // Counter-clockwise from 12 o'clock: blue on the top-left, red ending on the top-right.
    let start = -CGFloat.pi / 2 - CGFloat(i) * 2 * .pi / CGFloat(segments)
    let end = start - 2 * .pi / CGFloat(segments)
    let path = CGMutablePath()
    path.addArc(center: center, radius: outerR, startAngle: start, endAngle: end, clockwise: true)
    path.addArc(center: center, radius: innerR, startAngle: end, endAngle: start, clockwise: false)
    path.closeSubpath()
    let base = shap(CGFloat(i) / CGFloat(segments - 1))
    fill(path, gradient([tint(base, 0.35), base]))
  }
}

// Keyhole: the center hole joined to a small well holding a drop of color.
let dropCenter = CGPoint(x: center.x, y: center.y + 168)
let hole = CGMutablePath()
hole.addEllipse(in: CGRect(x: center.x - innerR, y: center.y - innerR, width: innerR * 2, height: innerR * 2))
hole.addEllipse(in: CGRect(x: dropCenter.x - 56, y: dropCenter.y - 56, width: 112, height: 112))
hole.addRect(CGRect(x: center.x - 24, y: center.y, width: 48, height: 168))
ctx.addPath(hole)
ctx.setFillColor(rgb(0xFFFFFF))
ctx.fillPath()

let drop = CGPath(ellipseIn: CGRect(x: dropCenter.x - 34, y: dropCenter.y - 34, width: 68, height: 68), transform: nil)
fill(drop, gradient([tint(shap(0.85), 0.3), shap(1)]))

// MARK: - Eyedropper

// Drawn along +x from its tip, then rotated to point down-left into the hole.
let tip = CGPoint(x: center.x - 22, y: center.y + 22)
ctx.saveGState()
ctx.translateBy(x: tip.x, y: tip.y)
ctx.rotate(by: -.pi / 4)

withShadow(blur: 22, dy: 14, alpha: 0.28) {
  // Glass tube with a tapered nozzle.
  let tube = CGMutablePath()
  tube.move(to: CGPoint(x: 6, y: -15))
  tube.addLine(to: CGPoint(x: 74, y: -40))
  tube.addLine(to: CGPoint(x: 280, y: -40))
  tube.addLine(to: CGPoint(x: 280, y: 40))
  tube.addLine(to: CGPoint(x: 74, y: 40))
  tube.addLine(to: CGPoint(x: 6, y: 15))
  tube.addArc(tangent1End: CGPoint(x: 0, y: 0), tangent2End: CGPoint(x: 6, y: -15), radius: 15)
  tube.closeSubpath()
  fill(tube, gradient([rgb(0xE6F3FF), rgb(0xBFDDFB)]))

  // Liquid: the blue end of the scale.
  let liquid = CGMutablePath()
  liquid.move(to: CGPoint(x: 16, y: -8))
  liquid.addLine(to: CGPoint(x: 74, y: -28))
  liquid.addLine(to: CGPoint(x: 182, y: -28))
  liquid.addArc(tangent1End: CGPoint(x: 204, y: -28), tangent2End: CGPoint(x: 204, y: 0), radius: 22)
  liquid.addArc(tangent1End: CGPoint(x: 204, y: 28), tangent2End: CGPoint(x: 182, y: 28), radius: 22)
  liquid.addLine(to: CGPoint(x: 74, y: 28))
  liquid.addLine(to: CGPoint(x: 16, y: 8))
  liquid.closeSubpath()
  fill(liquid, gradient([tint(shap(0), 0.25), shap(0.25)]))

  // Collar and bulb: the red end of the scale.
  let collar = CGPath(
    roundedRect: CGRect(x: 268, y: -78, width: 56, height: 156), cornerWidth: 26, cornerHeight: 26, transform: nil)
  fill(collar, gradient([tint(shap(0.85), 0.2), shap(0.95)]))
  let bulb = CGPath(
    roundedRect: CGRect(x: 312, y: -66, width: 172, height: 132), cornerWidth: 66, cornerHeight: 66, transform: nil)
  fill(bulb, gradient([tint(shap(0.85), 0.35), shap(1)]))
}

// A drop of blue at the tip.
let dot = CGPath(ellipseIn: CGRect(x: -34, y: -19, width: 38, height: 38), transform: nil)
fill(dot, gradient([tint(shap(0), 0.2), shap(0.15)]))
ctx.restoreGState()

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
