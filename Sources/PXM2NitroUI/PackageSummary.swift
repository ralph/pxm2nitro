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

    init(url: URL, package: LoadedPackage) {
        self.url = url
        presets = package.presets.map(PresetSummary.init)
        failures = package.failures
        var seen = Set<String>()
        collectionNames = package.presets.compactMap(\.collectionName).filter { seen.insert($0).inserted }
        let worst = Dictionary(presets.flatMap(\.result.blocks).map { ($0.block, $0.status) },
                               uniquingKeysWith: max)
        blocks = PhotomatorBlock.allCases.compactMap { block in worst[block].map { BlockOutcome(block, $0) } }
    }

    public var id: URL { url }
    public var fileName: String { url.lastPathComponent }
    public var convertibleCount: Int { presets.count(where: \.isConvertible) }
    public var losslessCount: Int { presets.count(where: \.result.isLossless) }
}

extension [BlockOutcome] {
    /// The adjustments with the given status, in order.
    public func blocks(_ status: BlockOutcome.Status) -> [PhotomatorBlock] {
        filter { $0.status == status }.map(\.block)
    }
}
