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

    /// Every sample package, loaded once per test run.
    static let photomatorPackages: [String: LoadedPackage] = Dictionary(
        uniqueKeysWithValues: ["BW", "CF", "LS", "MF", "filmic"].map { name in
            // swiftlint:disable:next force_try
            (name, try! AdjustmentsPackage.load(from: photomatorPackage(name)))
        })

    /// The presets of `sample_presets_photomator/<package>.adjustments`.
    static func photomatorPresets(_ package: String) throws -> [PhotomatorPreset] {
        try #require(photomatorPackages[package]).presets
    }

    /// The preset named `presetName` from `sample_presets_photomator/<package>.adjustments`.
    static func photomatorPreset(_ package: String, _ presetName: String) throws -> PhotomatorPreset {
        try #require(try photomatorPresets(package).first { $0.name == presetName })
    }

    /// Decoded `ColorAdjustmentData` of a sample preset.
    static func photomatorAdjustments(_ package: String, _ presetName: String) throws -> PhotomatorAdjustments {
        try #require(try photomatorPreset(package, presetName).adjustments)
    }

    static func nitroPreset(_ name: String) -> URL {
        repositoryRoot.appending(path: "nitro_sample_presets/\(name).nitropreset")
    }
}
