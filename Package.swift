// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PXM2Nitro",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "PXM2NitroKit", targets: ["PXM2NitroKit"]),
        .library(name: "PXM2NitroUI", targets: ["PXM2NitroUI"]),
        .executable(name: "pxm2nitro", targets: ["pxm2nitro"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(name: "PXM2NitroKit"),
        // App model shared by the macOS app and a later iOS/iPadOS app.
        .target(name: "PXM2NitroUI", dependencies: ["PXM2NitroKit"]),
        .target(name: "PXM2NitroTestSupport", path: "Tests/Support"),
        .executableTarget(
            name: "pxm2nitro",
            dependencies: [
                "PXM2NitroKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(name: "PXM2NitroKitTests", dependencies: ["PXM2NitroKit", "PXM2NitroTestSupport"]),
        .testTarget(name: "PXM2NitroUITests", dependencies: ["PXM2NitroUI", "PXM2NitroTestSupport"]),
    ]
)
