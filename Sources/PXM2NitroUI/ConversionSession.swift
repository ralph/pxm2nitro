import Foundation
import Observation
import PXM2NitroKit

/// A file that could not be added.
public struct LoadError: Identifiable, Sendable {
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
    public let written: [URL]
    /// Files not written because they exist and replacing was off.
    public let existing: [URL]
    /// Presets without a convertible adjustment.
    public let nothingToConvert: Int
    public let failures: [Failure]
    /// Written presets that lost or approximated at least one adjustment.
    public let writtenWithLosses: Int
}

/// The app's state: the packages the user added and the export to an output folder.
/// Platform-independent, so a later iOS/iPadOS app can share it with the macOS app.
@MainActor @Observable
public final class ConversionSession {
    public private(set) var packages: [PackageSummary] = []
    /// Files from the last `add` that could not be read.
    public private(set) var loadErrors: [LoadError] = []
    /// Replace `.nitropreset` files that already exist in the output folder.
    public var replaceExisting = false
    /// The result of the last export; `nil` until something was exported.
    public private(set) var lastExport: ExportReport?

    public init() {}

    public var presetCount: Int { packages.reduce(0) { $0 + $1.presets.count } }
    public var convertibleCount: Int { packages.reduce(0) { $0 + $1.convertibleCount } }

    /// Loads packages. A package added again replaces the earlier copy in place.
    public func add(_ urls: [URL]) {
        loadErrors = []
        for url in urls {
            let url = url.standardizedFileURL
            do {
                let loaded = try withSecurityScopedAccess(to: url) { try AdjustmentsPackage.load(from: url) }
                let summary = PackageSummary(url: url, package: loaded)
                if let index = packages.firstIndex(where: { $0.id == url }) {
                    packages[index] = summary
                } else {
                    packages.append(summary)
                }
            } catch {
                loadErrors.append(LoadError(url: url, message: Self.message(for: error, url: url)))
            }
        }
    }

    public func remove(_ id: PackageSummary.ID) {
        packages.removeAll { $0.id == id }
    }

    /// Starts over: no packages, no errors, no export.
    public func reset() {
        packages = []
        loadErrors = []
        lastExport = nil
    }

    /// Converts every preset of every package into `folder`. Failures of single presets
    /// are collected in the report; nothing is thrown.
    @discardableResult
    public func export(to folder: URL) -> ExportReport {
        var exporter = PresetExporter(outputDirectory: folder, overwrite: replaceExisting)
        var written: [URL] = [], existing: [URL] = [], failures: [ExportReport.Failure] = []
        var nothingToConvert = 0, writtenWithLosses = 0
        withSecurityScopedAccess(to: folder) {
            for summary in packages.flatMap(\.presets) {
                do {
                    switch try exporter.export(summary.preset).outcome {
                    case .written(let file):
                        written.append(file)
                        if !summary.isFullyConvertible { writtenWithLosses += 1 }
                    case .fileExists(let file):
                        existing.append(file)
                    case .nothingToConvert:
                        nothingToConvert += 1
                    }
                } catch {
                    failures.append(.init(presetTitle: summary.preset.title, message: error.localizedDescription))
                }
            }
        }
        let report = ExportReport(folder: folder, written: written, existing: existing,
                                  nothingToConvert: nothingToConvert, failures: failures,
                                  writtenWithLosses: writtenWithLosses)
        lastExport = report
        return report
    }

    static func message(for error: any Error, url: URL) -> String {
        if case PhotomatorError.notAPackage = error {
            return "\(url.lastPathComponent) is not a Photomator or Pixelmator Pro preset file."
        }
        return "\(url.lastPathComponent) could not be read: \(error.localizedDescription)"
    }
}

/// Runs `body` with access to a security-scoped URL (from a file picker or drop in a sandboxed
/// app). URLs that are not security-scoped are used as they are.
func withSecurityScopedAccess<T>(to url: URL, _ body: () throws -> T) rethrows -> T {
    let didStart = url.startAccessingSecurityScopedResource()
    defer { if didStart { url.stopAccessingSecurityScopedResource() } }
    return try body()
}
