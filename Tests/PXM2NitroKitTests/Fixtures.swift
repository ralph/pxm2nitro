import Foundation
@testable import PXM2NitroKit
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
    /// A load error is kept so it fails the tests that use the package instead of crashing the run.
    static let photomatorPackages: [String: Result<LoadedPackage, any Error>] = Dictionary(
        uniqueKeysWithValues: ["BW", "CF", "LS", "MF", "filmic"].map { name in
            (name, Result { try AdjustmentsPackage.load(from: photomatorPackage(name)) })
        })

    /// The presets of `sample_presets_photomator/<package>.adjustments`.
    static func photomatorPresets(_ package: String) throws -> [PhotomatorPreset] {
        try #require(photomatorPackages[package]).get().presets
    }

    /// The preset named `presetName` from `sample_presets_photomator/<package>.adjustments`.
    static func photomatorPreset(_ package: String, _ presetName: String) throws -> PhotomatorPreset {
        try #require(try photomatorPresets(package).first { $0.name == presetName })
    }

    /// A preset outside any collection, built in code.
    static func preset(_ name: String, _ adjustments: PhotomatorAdjustments?) -> PhotomatorPreset {
        PhotomatorPreset(id: "x", name: name, collectionName: nil, adjustments: adjustments, otherPropertyKeys: [])
    }

    /// Decoded `ColorAdjustmentData` of a sample preset.
    static func photomatorAdjustments(_ package: String, _ presetName: String) throws -> PhotomatorAdjustments {
        try #require(try photomatorPreset(package, presetName).adjustments)
    }

    static func nitroPreset(_ name: String) -> URL {
        repositoryRoot.appending(path: "nitro_sample_presets/\(name).nitropreset")
    }
}

/// Pattern-match shortcuts for tests.
extension NitroAdjustment.Content {
    var levelsCurves: NitroLevelsCurves? { if case .levelsCurves(let value) = self { value } else { nil } }
    var channelMixer: NitroChannelMixer? { if case .channelMixer(let value) = self { value } else { nil } }
    var hsl: NitroHSL? { if case .hsl(let value) = self { value } else { nil } }
}
