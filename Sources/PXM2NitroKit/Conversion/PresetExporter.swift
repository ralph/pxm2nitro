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
        guard var nitro = result.preset else {
            return Entry(preset: preset, diagnostics: result.diagnostics, outcome: .nothingToConvert)
        }
        // Keep the name shown in Nitro in step with the (de-duplicated) file name.
        nitro.name = uniqueName(for: nitro.name)
        let file = outputDirectory.appending(path: Self.fileName(for: nitro.name))
        if !overwrite, FileManager.default.fileExists(atPath: file.path) {
            return Entry(preset: preset, diagnostics: result.diagnostics, outcome: .fileExists(file))
        }
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        try nitro.encoded().write(to: file, options: .atomic)
        return Entry(preset: preset, diagnostics: result.diagnostics, outcome: .written(file))
    }

    /// Longest file name stem in UTF-8 bytes, leaving room for the extension and a counter
    /// within the usual 255-byte file name limit.
    static let maxStemLength = 200

    /// `<name>.nitropreset` with path separators replaced. Leading dots (which would hide
    /// the file) are dropped, an empty name becomes "Untitled", and long names are shortened.
    public static func fileName(for presetName: String) -> String {
        var safe = presetName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        while safe.hasPrefix(".") { safe.removeFirst() }
        if safe.isEmpty { safe = "Untitled" }
        while safe.utf8.count > maxStemLength { safe.removeLast() }
        return "\(safe).\(NitroPreset.fileExtension)"
    }

    /// Appends " 2", " 3", … if another preset of this export already used the file name.
    private mutating func uniqueName(for presetName: String) -> String {
        var candidate = presetName
        var counter = 2
        while !usedFileNames.insert(Self.fileName(for: candidate).lowercased()).inserted {
            candidate = "\(presetName) \(counter)"
            counter += 1
        }
        return candidate
    }
}
