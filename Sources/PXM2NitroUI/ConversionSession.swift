import Foundation
import Observation
import PXM2NitroKit

/// A file that could not be added.
public struct LoadError: Error, Identifiable, Sendable {
    public let id = UUID()
    public let url: URL
    public let message: String
}

/// What one export wrote.
public struct ExportReport: Sendable {
    public struct Failure: Sendable {
        public let presetTitle: String
        public let message: String
    }

    public let folder: URL
    public internal(set) var written: [URL] = []
    /// Files not written because they exist and replacing was off.
    public internal(set) var existing: [URL] = []
    /// Presets without a convertible adjustment.
    public internal(set) var nothingToConvert = 0
    public internal(set) var failures: [Failure] = []
    /// Written presets that lost or approximated at least one adjustment.
    public internal(set) var writtenWithLosses = 0

    init(folder: URL) {
        self.folder = folder
    }
}

/// The app's state: the packages the user added and the export to an output folder.
/// Platform-independent, so a later iOS/iPadOS app can share it with the macOS app.
/// Reading and writing files runs off the main actor; only the state lives on it.
@MainActor @Observable
public final class ConversionSession {
    public private(set) var packages: [PackageSummary] = []
    /// Files from the last `add` that could not be read.
    public private(set) var loadErrors: [LoadError] = []
    /// Replace `.nitropreset` files that already exist in the output folder.
    public var replaceExisting = false
    /// The result of the last export; `nil` until something was exported.
    public private(set) var lastExport: ExportReport?
    /// Whether packages are being loaded or presets written.
    public var isBusy: Bool { activeOperations > 0 }
    /// Loads and exports in flight; several can overlap since each awaits work off the actor.
    private var activeOperations = 0
    /// Bumped by `reset`, so a load that was in flight does not bring packages back.
    private var generation = 0
    /// The most recent export; the next one waits for it, so two exports never race on
    /// the "file exists" check in the same folder.
    private var exportTask: Task<ExportReport, Never>?

    public init() {}

    public var presetCount: Int { packages.reduce(0) { $0 + $1.presets.count } }
    public var convertibleCount: Int { packages.reduce(0) { $0 + $1.convertibleCount } }

    /// Loads packages. A package added again replaces the earlier copy in place.
    public func add(_ urls: [URL]) async {
        activeOperations += 1
        defer { activeOperations -= 1 }
        let startGeneration = generation
        let results = await Task.detached { urls.map(Self.load) }.value
        guard generation == startGeneration else { return }
        loadErrors = []
        for result in results {
            switch result {
            case .success(let summary):
                if let index = packages.firstIndex(where: { $0.id == summary.id }) {
                    packages[index] = summary
                } else {
                    packages.append(summary)
                }
            case .failure(let error):
                loadErrors.append(error)
            }
        }
    }

    public func remove(_ id: PackageSummary.ID) {
        packages.removeAll { $0.id == id }
    }

    /// Starts over: no packages, no errors, no export.
    public func reset() {
        generation += 1
        packages = []
        loadErrors = []
        lastExport = nil
    }

    /// Writes every convertible preset of every package into `folder`. Failures of single
    /// presets are collected in the report; nothing is thrown.
    @discardableResult
    public func export(to folder: URL) async -> ExportReport {
        activeOperations += 1
        defer { activeOperations -= 1 }
        let startGeneration = generation
        let presets = packages.flatMap(\.presets)
        let replace = replaceExisting
        let previous = exportTask
        let task = Task.detached {
            _ = await previous?.value
            return Self.write(presets, to: folder, replacing: replace)
        }
        exportTask = task
        let report = await task.value
        if generation == startGeneration { lastExport = report }
        return report
    }

    nonisolated static func load(_ url: URL) -> Result<PackageSummary, LoadError> {
        do {
            let package = try withSecurityScopedAccess(to: url) { try AdjustmentsPackage.load(from: url) }
            // One form per folder, whether or not the received URL ends in a slash.
            let id = URL(filePath: url.standardizedFileURL.path(percentEncoded: false), directoryHint: .isDirectory)
            return .success(PackageSummary(url: id, package: package))
        } catch {
            return .failure(LoadError(url: url, message: message(for: error, url: url)))
        }
    }

    nonisolated static func write(_ presets: [PresetSummary], to folder: URL, replacing: Bool) -> ExportReport {
        var exporter = PresetExporter(outputDirectory: folder, overwrite: replacing)
        var report = ExportReport(folder: folder)
        withSecurityScopedAccess(to: folder) {
            for summary in presets {
                do {
                    switch try exporter.export(summary.preset, result: summary.result).outcome {
                    case .written(let file):
                        report.written.append(file)
                        if !summary.result.isLossless { report.writtenWithLosses += 1 }
                    case .fileExists(let file):
                        report.existing.append(file)
                    case .nothingToConvert:
                        report.nothingToConvert += 1
                    }
                } catch {
                    report.failures.append(.init(presetTitle: summary.preset.title,
                                                 message: error.localizedDescription))
                }
            }
        }
        return report
    }

    nonisolated static func message(for error: any Error, url: URL) -> String {
        if case PhotomatorError.notAPackage = error {
            return "\(url.lastPathComponent) is not a Photomator or Pixelmator Pro preset file."
        }
        return "\(url.lastPathComponent) could not be read: \(error.localizedDescription)"
    }
}

/// Runs `body` with access to a security-scoped URL (from a file picker or drop in a sandboxed
/// app). Pass the URL exactly as received: a rebuilt URL may not carry the access grant.
/// URLs that are not security-scoped are used as they are.
func withSecurityScopedAccess<T>(to url: URL, _ body: () throws -> T) rethrows -> T {
    let didStart = url.startAccessingSecurityScopedResource()
    defer { if didStart { url.stopAccessingSecurityScopedResource() } }
    return try body()
}
