// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "ColorPick",
  platforms: [.macOS(.v14)],
  targets: [
    .executableTarget(name: "ColorPick", path: "Sources")
  ]
)
