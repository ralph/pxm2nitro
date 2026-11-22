import Foundation

/// Sample presets checked into the repository root.
enum Fixtures {
    static let repositoryRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()   // PXM2NitroKitTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // repository root

    static func photomatorPackage(_ name: String) -> URL {
        repositoryRoot.appending(path: "sample_presets_photomator/\(name).adjustments")
    }

    static func nitroPreset(_ name: String) -> URL {
        repositoryRoot.appending(path: "nitro_sample_presets/\(name).nitropreset")
    }
}
