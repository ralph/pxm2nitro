import Foundation

/// Paths of the sample presets checked into the repository, shared by all test targets.
public enum SampleFiles {
    public static let repositoryRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()   // Support
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // repository root

    /// `sample_presets_photomator/<name>.adjustments`
    public static func photomatorPackage(_ name: String) -> URL {
        repositoryRoot.appending(path: "sample_presets_photomator/\(name).adjustments")
    }

    /// `nitro_sample_presets/<name>.nitropreset`
    public static func nitroPreset(_ name: String) -> URL {
        repositoryRoot.appending(path: "nitro_sample_presets/\(name).nitropreset")
    }

    /// A new, not yet created folder in the temporary directory.
    public static func temporaryFolder() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "pxm2nitro-tests-\(UUID().uuidString)")
    }
}
