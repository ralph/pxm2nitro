import Foundation

/// Converts presets and writes them as `.nitropreset` files into one folder.
/// Shared by the CLI and (later) the app.
public struct PresetExporter {
    public enum Outcome: Sendable, Equatable {
        case written(URL)
        /// The file exists and `overwrite` is off; nothing was written.
        case fileExists(URL)
        /// No adjustment of the preset could be converted; nothing was written.
        case nothingToConvert
    }

    public struct Entry: Sendable {
        public let preset: PhotomatorPreset
        public let diagnostics: [ConversionDiagnostic]
        public let outcome: Outcome
    }

    public let outputDirectory: URL
    public var overwrite: Bool
    /// Lower-cased file names used so far, to keep names unique within one export.
    private var usedFileNames = Set<String>()

    public init(outputDirectory: URL, overwrite: Bool = false) {
        self.outputDirectory = outputDirectory
        self.overwrite = overwrite
    }

    /// Converts `preset` and writes it unless there is nothing to convert or the file
    /// exists (and `overwrite` is off).
    public mutating func export(_ preset: PhotomatorPreset) throws -> Entry {
        let result = Converter.convert(preset)
        guard let nitro = result.preset else {
            return Entry(preset: preset, diagnostics: result.diagnostics, outcome: .nothingToConvert)
        }
        let file = outputDirectory.appending(path: uniqueFileName(for: nitro.name))
        if !overwrite, FileManager.default.fileExists(atPath: file.path) {
            return Entry(preset: preset, diagnostics: result.diagnostics, outcome: .fileExists(file))
        }
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        try nitro.encoded().write(to: file, options: .atomic)
        return Entry(preset: preset, diagnostics: result.diagnostics, outcome: .written(file))
    }

    /// `<name>.nitropreset` with path separators replaced.
    public static func fileName(for presetName: String) -> String {
        let safe = presetName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        return "\(safe).\(NitroPreset.fileExtension)"
    }

    /// Appends " 2", " 3", … if another preset of this export already used the name.
    private mutating func uniqueFileName(for presetName: String) -> String {
        var candidate = Self.fileName(for: presetName)
        var counter = 2
        while !usedFileNames.insert(candidate.lowercased()).inserted {
            candidate = Self.fileName(for: "\(presetName) \(counter)")
            counter += 1
        }
        return candidate
    }
}
