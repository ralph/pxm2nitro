/// Photomator Selective Color (`ca`, 8 ranges) → Nitro HSL (9 colours). See `docs/mapping.md` §2.2.
///
/// The ranges map one to one (violet → purple). Nitro's extra `lightBlue` swatch gets the
/// mean of cyan and blue. Nitro's per-colour `range` stays at its default (0). The scale
/// factors are not calibrated yet (`MappingConstants`).
enum SelectiveColorMapper: BlockMapper {
    static let block = PhotomatorBlock.selectiveColor

    /// Nitro colour for each Photomator range, in Photomator's storage (= UI) order.
    static let colors: [NitroHSLColor] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .magenta]

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        guard let ranges = adjustments.selectiveColor else { return [] }
        if ranges.count != colors.count {
            context.report(.skipped, block, "expected \(colors.count) colour ranges, found \(ranges.count)")
            return []
        }

        var hsl = NitroHSL()
        for (color, range) in zip(colors, ranges) {
            hsl[color] = values(for: range, context: context)
        }
        hsl[.lightBlue] = .average(hsl[.cyan], hsl[.blue])

        guard hsl != NitroHSL() else { return [] }
        context.reportUncalibrated(block, "hue, saturation and brightness")
        return [.hsl(hsl)]
    }

    static func values(for range: SelectiveColorRange, context: MappingContext) -> NitroHSL.Values {
        typealias Scale = MappingConstants.SelectiveColor
        return NitroHSL.Values(
            hueDelta: context.blend(0, range.hue * Scale.hueDegreesPerUnit),
            saturationDelta: context.blend(0, range.saturation * Scale.saturationScale),
            lumaDelta: context.blend(0, range.brightness * Scale.brightnessScale))
    }
}
