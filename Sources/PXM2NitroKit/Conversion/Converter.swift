/// The result of converting one Photomator preset.
public struct ConversionResult: Sendable {
    /// The Nitro preset, or `nil` if nothing could be converted.
    public let preset: NitroPreset?
    public let diagnostics: [ConversionDiagnostic]
}

/// Converts Photomator / Pixelmator Pro presets to Nitro presets. See `docs/mapping.md`.
///
/// Only adjustments with a direct Nitro counterpart are converted; every other enabled
/// adjustment is skipped with a diagnostic.
public enum Converter {
    /// The block mappers, in the order their Nitro adjustments are written.
    static var mappers: [any BlockMapper.Type] {
        [LevelsMapper.self, CurvesMapper.self, ChannelMixerMapper.self]
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
            return ConversionResult(preset: nil, diagnostics: context.diagnostics)
        }
        var context = MappingContext(intensity: adjustments.intensity)
        let contents = mappers.flatMap { $0.map(adjustments, context: &context) }

        let supported = supportedBlocks
        for block in adjustments.enabledBlocks where !supported.contains(block) {
            context.report(.skipped, block, "no Nitro equivalent is implemented yet")
        }
        reportOtherProperties(&context)

        let nitroPreset = contents.isEmpty ? nil : NitroPreset(
            name: nitroName(for: preset),
            adjustments: contents.map { NitroAdjustment($0) })
        return ConversionResult(preset: nitroPreset, diagnostics: context.diagnostics)
    }
}
