// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "ScreenshotLibrary", platforms: [.macOS(.v13)], products: [.executable(name: "ScreenshotLibrary", targets: ["ScreenshotLibrary"])], targets: [.executableTarget(name: "ScreenshotLibrary")])
