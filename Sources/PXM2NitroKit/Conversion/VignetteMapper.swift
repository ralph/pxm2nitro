/// Photomator Vignette (`v`) → Nitro Vignette. See `docs/mapping.md` §1.
///
/// Exposure (the vignette's strength) becomes Nitro's `intensity`, clamped to at most 1
/// (Nitro's range is ±1, `docs/nitro-format.md` §3.12). A negative, brightening vignette is
/// not converted. Nitro's `radius` is a
/// different control from Photomator's softness, so it stays at Nitro's default and a
/// non-default softness is reported, as is the black point. The scale factor is not
/// calibrated yet (`MappingConstants`).
enum VignetteMapper: BlockMapper {
    static let block = PhotomatorBlock.vignette

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        guard let vignette: PhotomatorVignette = context.sliders(block, in: adjustments) else { return [] }
        context.reportDropped(vignette, .softness, block, "softness was dropped; Nitro's vignette has a radius instead")
        context.reportDropped(vignette, .blackPoint, block, "black point was dropped; Nitro's vignette has none")

        let strength = context.blend(0, vignette[.exposure] * MappingConstants.Vignette.intensityScale)
        if strength < -MappingContext.tolerance {
            context.report(.skipped, block, "a brightening (negative) vignette is not converted")
            return []
        }
        if strength > 1 + MappingContext.tolerance {
            context.report(.approximated, block, "the strength was clamped to Nitro's maximum")
        }
        var nitro = NitroSliders(.vignette)
        nitro["intensity"] = min(strength, 1)
        return context.uncalibrated(nitro, block, "strength")
    }
}
