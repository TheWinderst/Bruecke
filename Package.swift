// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Bruecke",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Bruecke",
            path: "Sources/Bruecke",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
