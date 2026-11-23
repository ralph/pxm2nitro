import Foundation
import PXM2NitroKit

/// One preset of a loaded package and what converting it does.
public struct PresetSummary: Identifiable, Sendable {
    public let preset: PhotomatorPreset
    public let result: ConversionResult

    init(_ preset: PhotomatorPreset) {
        self.preset = preset
        result = Converter.convert(preset)
    }

    public var id: String { preset.id }
    public var name: String { preset.name }
    /// Whether a Nitro preset can be written at all.
    public var isConvertible: Bool { result.preset != nil }
    /// Whether every adjustment carries over exactly.
    public var isFullyConvertible: Bool {
        isConvertible && result.blocks.allSatisfy { $0.status == .carriedOver }
    }
    /// The file name the Nitro preset would get (before de-duplication within one export).
    public var nitroFileName: String? {
        result.preset.map { PresetExporter.fileName(for: $0.name) }
    }
    /// Adjustments of this preset with the given status, in Photomator's order.
    public func blocks(_ status: BlockOutcome.Status) -> [PhotomatorBlock] {
        result.blocks.filter { $0.status == status }.map(\.block)
    }
}

/// One dropped `.adjustments` package.
public struct PackageSummary: Identifiable, Sendable {
    /// The package's file URL.
    public let id: URL
    public let presets: [PresetSummary]
    /// Preset files inside the package that could not be read.
    public let failures: [PresetLoadFailure]

    init(url: URL, package: LoadedPackage) {
        id = url
        presets = package.presets.map(PresetSummary.init)
        failures = package.failures
    }

    public var url: URL { id }
    public var fileName: String { url.lastPathComponent }
    /// Collection names in package order, without duplicates.
    public var collectionNames: [String] {
        var seen = Set<String>()
        return presets.compactMap(\.preset.collectionName).filter { seen.insert($0).inserted }
    }
    public var convertibleCount: Int { presets.count(where: \.isConvertible) }
    public var fullyConvertibleCount: Int { presets.count(where: \.isFullyConvertible) }

    /// Every adjustment used by the package's presets, in Photomator's order, with the least
    /// favourable status it got in any preset (left out, then approximated, then carried over).
    public var blocks: [BlockOutcome] {
        var worst: [PhotomatorBlock: BlockOutcome.Status] = [:]
        for outcome in presets.flatMap(\.result.blocks) {
            if let current = worst[outcome.block], current.severity >= outcome.status.severity { continue }
            worst[outcome.block] = outcome.status
        }
        return PhotomatorBlock.allCases.compactMap { block in worst[block].map { BlockOutcome(block, $0) } }
    }

    /// Adjustments of the package with the given (least favourable) status.
    public func blocks(_ status: BlockOutcome.Status) -> [PhotomatorBlock] {
        blocks.filter { $0.status == status }.map(\.block)
    }
}

extension BlockOutcome.Status {
    /// Higher is worse.
    var severity: Int {
        switch self {
        case .carriedOver: 0
        case .approximated: 1
        case .leftOut: 2
        }
    }
}
