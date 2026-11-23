// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PXM2Nitro",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "PXM2NitroKit", targets: ["PXM2NitroKit"]),
        .executable(name: "pxm2nitro", targets: ["pxm2nitro"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .target(name: "PXM2NitroKit"),
        .executableTarget(
            name: "pxm2nitro",
            dependencies: [
                "PXM2NitroKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(name: "PXM2NitroKitTests", dependencies: ["PXM2NitroKit"]),
    ]
)
