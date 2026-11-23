/// Photomator Color (`hS`) → Nitro Enhance. See `docs/mapping.md` §1.
///
/// Saturation becomes Enhance's saturation multiplier and vibrance its vibrancy. Nitro has
/// no global hue rotation (HSL shifts single colours), so hue is skipped with a diagnostic.
/// The scale factors are not calibrated yet (`MappingConstants`).
enum ColorMapper: BlockMapper {
    static let block = PhotomatorBlock.hueSaturation

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        guard adjustments.enabledBlock(block) != nil else { return [] }
        guard let color = adjustments.color else {
            context.report(.skipped, block, "a value is not a number")
            return []
        }
        if !isNearlyEqual(color.hue, 0) {
            context.report(.skipped, block, "hue was dropped; Nitro has no global hue shift")
        }

        typealias Scale = MappingConstants.Color
        var enhance = NitroSliders(.enhance)
        enhance["saturation"] = context.blend(1, max(0, 1 + color.saturation * Scale.saturationScale))
        enhance["vibrancy"] = context.blend(0, color.vibrancy * Scale.vibrancyScale)
        guard !enhance.isDefault else { return [] }
        context.reportUncalibrated(block, "saturation and vibrance")
        return [.sliders(enhance)]
    }
}
