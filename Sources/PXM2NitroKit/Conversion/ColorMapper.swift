/// Photomator Color (`hS`) → Nitro Enhance. See `docs/mapping.md` §1.
///
/// Saturation becomes Enhance's saturation multiplier and vibrance its vibrancy. Nitro has
/// no global hue rotation (HSL shifts single colours), so hue is skipped with a diagnostic.
/// Saturation is calibrated; vibrance is still a placeholder (`MappingConstants`).
enum ColorMapper: BlockMapper {
    static let block = PhotomatorBlock.hueSaturation

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        guard let color: PhotomatorColor = context.sliders(block, in: adjustments) else { return [] }
        context.reportDropped(color, .hue, block, "hue was dropped; Nitro has no global hue shift")

        typealias Scale = MappingConstants.Color
        var enhance = NitroSliders(.enhance), notes = ScaleNotes()
        context.set(&enhance, "saturation", context.factor(color[.saturation], scale: Scale.saturationScale),
                    block, "saturation", .close, notes: &notes)
        context.set(&enhance, "vibrancy", context.blend(0, color[.vibrancy] * Scale.vibrancyScale),
                    block, "vibrance", .placeholder, notes: &notes)
        guard !enhance.isNoOp else { return [] }
        context.report(notes, block)
        return [.sliders(enhance)]
    }
}
