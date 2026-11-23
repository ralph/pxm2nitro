import Foundation
import PXM2NitroKit

/// One preset of a loaded package and what converting it does.
public struct PresetSummary: Identifiable, Sendable {
    public let preset: PhotomatorPreset
    public let result: ConversionResult
    /// Adjustments that carry over (exactly first, then approximately) and those left out.
    public let converted: [BlockOutcome], leftOut: [BlockOutcome]
    /// What changed beyond the left-out adjustments: approximations and dropped preset properties.
    public let notes: [String]
    /// Why each left-out adjustment was left out, one line per diagnostic.
    public let leftOutReasons: [PhotomatorBlock: String]

    init(_ preset: PhotomatorPreset) {
        self.preset = preset
        result = Converter.convert(preset)
        (converted, leftOut) = result.blocks.partitionedByConversion()
        let approximated = Set(result.blocks.filter { $0.status == .approximated }.map(\.block))
        notes = result.diagnostics
            .filter { $0.block.map(approximated.contains) ?? true }
            .map { [$0.block?.displayName, $0.message].compactMap { $0 }.joined(separator: ": ") }
        leftOutReasons = reasons(for: leftOut, result.diagnostics)
    }

    public var id: String { preset.id }
    /// Whether a Nitro preset can be written at all.
    public var isConvertible: Bool { result.preset != nil }
    /// The file name the Nitro preset gets. An export appends " 2", " 3", … if several
    /// presets of one export share a name.
    public var nitroFileName: String? {
        result.preset.map { PresetExporter.fileName(for: $0.name) }
    }
}

/// One dropped `.adjustments` package.
public struct PackageSummary: Identifiable, Sendable {
    public let url: URL
    public let presets: [PresetSummary]
    /// Preset files inside the package that could not be read.
    public let failures: [PresetLoadFailure]
    /// Collection names in package order, without duplicates.
    public let collectionNames: [String]
    /// Every adjustment used by the package's presets, in Photomator's order, with the least
    /// favourable status it got in any preset.
    public let blocks: [BlockOutcome]
    /// `blocks` split like `PresetSummary.converted` / `leftOut`.
    public let converted: [BlockOutcome], leftOut: [BlockOutcome]
    /// Why each left-out adjustment was left out, merged across presets.
    public let leftOutReasons: [PhotomatorBlock: String]
    public let convertibleCount: Int
    public let losslessCount: Int

    init(url: URL, package: LoadedPackage) {
        self.url = url
        presets = package.presets.map(PresetSummary.init)
        failures = package.failures
        collectionNames = package.presets.compactMap(\.collectionName).uniqued()
        let worst = Dictionary(presets.flatMap(\.result.blocks).map { ($0.block, $0.status) },
                               uniquingKeysWith: max)
        blocks = PhotomatorBlock.allCases.compactMap { block in worst[block].map { BlockOutcome(block, $0) } }
        (converted, leftOut) = blocks.partitionedByConversion()
        leftOutReasons = reasons(for: leftOut, presets.flatMap(\.result.diagnostics))
        convertibleCount = presets.count(where: \.isConvertible)
        losslessCount = presets.count(where: \.result.isLossless)
    }

    public var id: URL { url }
    public var fileName: String { url.lastPathComponent }
}

/// The distinct diagnostic messages for each of `outcomes`' blocks, one per line.
private func reasons(for outcomes: [BlockOutcome], _ diagnostics: [ConversionDiagnostic]) -> [PhotomatorBlock: String] {
    Dictionary(uniqueKeysWithValues: outcomes.map { outcome in
        (outcome.block, diagnostics.filter { $0.block == outcome.block }.map(\.message).uniqued().joined(separator: "\n"))
    })
}

extension Sequence where Element: Hashable {
    /// The elements in order, without repeats.
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension [BlockOutcome] {
    /// The adjustments with the given status, in order.
    public func blocks(_ status: BlockOutcome.Status) -> [PhotomatorBlock] {
        filter { $0.status == status }.map(\.block)
    }

    /// Converted outcomes (carried over before approximated, otherwise in order) and left-out ones.
    func partitionedByConversion() -> (converted: [BlockOutcome], leftOut: [BlockOutcome]) {
        (filter { $0.status != .leftOut }.sorted { $0.status < $1.status }, filter { $0.status == .leftOut })
    }
}
