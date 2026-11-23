/// Photomator Selective Color (`ca`, 8 ranges) → Nitro HSL (9 colours). See `docs/mapping.md` §2.2.
///
/// The ranges map one to one (violet → purple). Nitro's extra `lightBlue` swatch gets the
/// mean of cyan and blue. Nitro's per-colour `range` stays at its default (0). Values are
/// clamped to Nitro's ranges (hue ±60°, the rest ±1). The scale factors are not calibrated yet
/// (`MappingConstants`).
enum SelectiveColorMapper: BlockMapper {
    static let block = PhotomatorBlock.selectiveColor

    /// Nitro colour for each Photomator range, in Photomator's storage (= UI) order.
    static let colors: [NitroHSLColor] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .magenta]

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        guard adjustments.enabledBlock(block) != nil else { return [] }
        guard let ranges = adjustments.selectiveColor else {
            context.report(.skipped, block, "the colour ranges (`a`) are missing or not an array")
            return []
        }
        if ranges.count != colors.count {
            context.report(.skipped, block, "expected \(colors.count) colour ranges, found \(ranges.count)")
            return []
        }

        var hsl = NitroHSL()
        var clamped: [String] = []
        for (color, range) in zip(colors, ranges) {
            hsl[color] = values(for: range, context: context, clamped: &clamped)
        }
        if !clamped.isEmpty {
            let fields = ["hue", "saturation", "brightness"].filter(clamped.contains)
            context.report(.approximated, block,
                           "\(listed(fields)) \(fields.count == 1 ? "was" : "were") clamped to Nitro's range for some colours")
        }
        hsl[.lightBlue] = .average(hsl[.cyan], hsl[.blue])

        guard !isNeutral(hsl) else { return [] }
        context.reportUncalibrated(block, "hue, saturation and brightness")
        return [.hsl(hsl)]
    }

    static func isNeutral(_ hsl: NitroHSL) -> Bool {
        NitroHSLColor.allCases.allSatisfy { color in
            let values = hsl[color]
            return [values.hueDelta, values.saturationDelta, values.lumaDelta, values.range]
                .allSatisfy { isNearlyEqual($0, 0) }
        }
    }

    /// Nitro's HSL ranges (N-3): hue in degrees, the other fields ±1.
    static let hueRange = -60.0...60.0, deltaRange = -1.0...1.0

    /// One Nitro swatch, clamped to Nitro's ranges; appends the names of clamped fields.
    static func values(for range: SelectiveColorRange, context: MappingContext,
                       clamped: inout [String]) -> NitroHSL.Values {
        typealias Scale = MappingConstants.SelectiveColor
        func limit(_ value: Double, _ bounds: ClosedRange<Double>, _ name: String) -> Double {
            let limited = min(max(value, bounds.lowerBound), bounds.upperBound)
            if abs(limited - value) > MappingContext.tolerance { clamped.append(name) }
            return limited
        }
        return NitroHSL.Values(
            hueDelta: limit(context.blend(0, range.hue * Scale.hueDegreesPerUnit), hueRange, "hue"),
            saturationDelta: limit(context.blend(0, range.saturation * Scale.saturationScale), deltaRange, "saturation"),
            lumaDelta: limit(context.blend(0, range.brightness * Scale.brightnessScale), deltaRange, "brightness"))
    }
}
