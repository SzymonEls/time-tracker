// swift-tools-version: 6.0
import PackageDescription

// One executable, no dependencies. The .app bundle around this binary is
// assembled by the Makefile - SwiftPM only ever produces the binary itself.
let package = Package(
    name: "TimeTracker",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "TimeTracker", path: "Sources/TimeTracker")
    ]
)
