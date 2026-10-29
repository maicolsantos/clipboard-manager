// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Clips",
    platforms: [.macOS(.v15)],
    targets: [
        // Rules and data logic with no SwiftUI, so tests run without the app.
        .target(name: "ClipsKit"),
        .executableTarget(
            name: "Clips",
            dependencies: ["ClipsKit"]
        ),
        .testTarget(name: "ClipsKitTests", dependencies: ["ClipsKit"]),
    ]
)
