/// How one enabled Photomator adjustment fared in a conversion.
public struct BlockOutcome: Sendable, Equatable {
    public enum Status: String, Sendable {
        /// Converted exactly.
        case carriedOver
        /// Converted, but with diagnostics (approximated, uncalibrated or partly dropped).
        case approximated
        /// Not converted at all.
        case leftOut
    }

    public let block: PhotomatorBlock
    public let status: Status

    public init(_ block: PhotomatorBlock, _ status: Status) {
        self.block = block
        self.status = status
    }
}

/// The result of converting one Photomator preset.
public struct ConversionResult: Sendable {
    /// The Nitro preset, or `nil` if nothing could be converted.
    public let preset: NitroPreset?
    public let diagnostics: [ConversionDiagnostic]
    /// One entry per enabled Photomator adjustment, in Photomator's order. An enabled
    /// adjustment that changes nothing (e.g. Levels with every handle at its default) is
    /// left out of this list, since there is nothing to carry over.
    public let blocks: [BlockOutcome]
}

/// Converts Photomator / Pixelmator Pro presets to Nitro presets. See `docs/mapping.md`.
///
/// Only adjustments with a direct Nitro counterpart are converted; every other enabled
/// adjustment is skipped with a diagnostic.
public enum Converter {
    /// The block mappers, in the order their Nitro adjustments are written.
    static var mappers: [any BlockMapper.Type] {
        [LevelsMapper.self, CurvesMapper.self, ChannelMixerMapper.self, SelectiveColorMapper.self]
    }

    /// Photomator blocks this converter maps.
    public static var supportedBlocks: Set<PhotomatorBlock> {
        Set(mappers.map { $0.block })
    }

    /// The Nitro preset name for a Photomator preset: "<Collection> <Name>".
    public static func nitroName(for preset: PhotomatorPreset) -> String {
        preset.title(separator: " ")
    }

    public static func convert(_ preset: PhotomatorPreset) -> ConversionResult {
        func reportOtherProperties(_ context: inout MappingContext) {
            for key in preset.otherPropertyKeys {
                context.report(.skipped, nil, "preset property \(key) is not converted")
            }
        }
        guard let adjustments = preset.adjustments else {
            var context = MappingContext(intensity: 1)
            context.report(.skipped, nil, "the preset has no colour adjustments")
            reportOtherProperties(&context)
            return ConversionResult(preset: nil, diagnostics: context.diagnostics, blocks: [])
        }
        var context = MappingContext(intensity: adjustments.intensity)
        var contents: [NitroAdjustment.Content] = []
        var statuses: [PhotomatorBlock: BlockOutcome.Status] = [:]
        for mapper in mappers {
            let firstNewDiagnostic = context.diagnostics.endIndex
            let mapped = mapper.map(adjustments, context: &context)
            contents += mapped
            let reported = context.diagnostics[firstNewDiagnostic...].filter { $0.block == mapper.block }
            if !mapped.isEmpty {
                statuses[mapper.block] = reported.isEmpty ? .carriedOver : .approximated
            } else if !reported.isEmpty {
                statuses[mapper.block] = .leftOut
            }
        }

        let supported = supportedBlocks
        for block in adjustments.enabledBlocks where !supported.contains(block) {
            context.report(.skipped, block, "no Nitro equivalent is implemented yet")
            statuses[block] = .leftOut
        }
        reportOtherProperties(&context)

        let nitroPreset = contents.isEmpty ? nil : NitroPreset(
            name: nitroName(for: preset),
            adjustments: contents.map { NitroAdjustment($0) })
        let blocks = adjustments.enabledBlocks.compactMap { block in
            statuses[block].map { BlockOutcome(block, $0) }
        }
        return ConversionResult(preset: nitroPreset, diagnostics: context.diagnostics, blocks: blocks)
    }
}
