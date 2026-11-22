/// The result of converting one Photomator preset.
public struct ConversionResult: Sendable {
    /// The Nitro preset, or `nil` if nothing could be converted.
    public let preset: NitroPreset?
    public let diagnostics: [ConversionDiagnostic]
}

/// Converts Photomator / Pixelmator Pro presets to Nitro presets. See `docs/mapping.md`.
///
/// Only adjustments with a direct Nitro counterpart are converted (Curves, Levels,
/// Channel Mixer); every other enabled adjustment is skipped with a diagnostic.
public enum Converter {
    /// Photomator blocks this converter maps.
    public static let supportedBlocks: Set<PhotomatorBlock> = [.curves, .levels, .channelMixer]

    /// The Nitro preset name for a Photomator preset: "<Collection> <Name>".
    public static func nitroName(for preset: PhotomatorPreset) -> String {
        [preset.collectionName, preset.name].compactMap { $0 }.joined(separator: " ")
    }

    public static func convert(_ preset: PhotomatorPreset) -> ConversionResult {
        guard let adjustments = preset.adjustments else {
            return ConversionResult(preset: nil, diagnostics: [
                ConversionDiagnostic(.skipped, nil, "the preset has no colour adjustments"),
            ])
        }
        var diagnostics: [ConversionDiagnostic] = []
        let intensity = adjustments.intensity

        let nitroAdjustments: [NitroAdjustment.Content] = [
            adjustments.levels.flatMap { LevelsMapper.map($0, intensity: intensity, diagnostics: &diagnostics) },
            adjustments.curves.flatMap { CurvesMapper.map($0, intensity: intensity, diagnostics: &diagnostics) },
            adjustments.channelMixer.flatMap { ChannelMixerMapper.map($0, intensity: intensity) },
        ].compactMap { $0 }

        for block in adjustments.enabledBlocks where !supportedBlocks.contains(block) {
            diagnostics.append(ConversionDiagnostic(.skipped, block, "no Nitro equivalent is implemented yet"))
        }
        for key in preset.otherPropertyKeys {
            diagnostics.append(ConversionDiagnostic(.skipped, nil, "preset property \(key) is not converted"))
        }

        let nitroPreset = nitroAdjustments.isEmpty ? nil : NitroPreset(
            name: nitroName(for: preset),
            adjustments: nitroAdjustments.map { NitroAdjustment($0) })
        return ConversionResult(preset: nitroPreset, diagnostics: diagnostics)
    }
}

/// Linear interpolation from `neutral` (t = 0) to `value` (t = 1); applies preset intensity.
func blend(_ neutral: Double, _ value: Double, _ t: Double) -> Double {
    neutral + (value - neutral) * t
}
