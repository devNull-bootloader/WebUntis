// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UntisApp",
    platforms: [
        .iOS("17.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources"
        )
    ]
)
