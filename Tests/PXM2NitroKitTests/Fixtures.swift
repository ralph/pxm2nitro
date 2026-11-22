import Foundation
import PXM2NitroKit
import Testing

/// Sample presets checked into the repository root.
enum Fixtures {
    static let repositoryRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()   // PXM2NitroKitTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // repository root

    static func photomatorPackage(_ name: String) -> URL {
        repositoryRoot.appending(path: "sample_presets_photomator/\(name).adjustments")
    }

    /// The preset named `presetName` from `sample_presets_photomator/<package>.adjustments`.
    static func photomatorPreset(_ package: String, _ presetName: String) throws -> PhotomatorPreset {
        try #require(try AdjustmentsPackage.load(from: photomatorPackage(package))
            .presets.first { $0.name == presetName })
    }

    /// Decoded `ColorAdjustmentData` of a sample preset.
    static func photomatorAdjustments(_ package: String, _ presetName: String) throws -> PhotomatorAdjustments {
        try #require(try photomatorPreset(package, presetName).adjustments)
    }

    static func nitroPreset(_ name: String) -> URL {
        repositoryRoot.appending(path: "nitro_sample_presets/\(name).nitropreset")
    }
}
