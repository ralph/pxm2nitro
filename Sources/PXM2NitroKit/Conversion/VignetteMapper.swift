/// Photomator Vignette (`v`) → Nitro Vignette. See `docs/mapping.md` §1.
///
/// Exposure (the vignette's strength) becomes Nitro's `intensity`. Nitro's `radius` is a
/// different control from Photomator's softness, so it stays at Nitro's default and a
/// non-default softness is reported, as is the black point. The scale factor is not
/// calibrated yet (`MappingConstants`).
enum VignetteMapper: BlockMapper {
    static let block = PhotomatorBlock.vignette

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        guard let vignette: PhotomatorVignette = context.sliders(block, in: adjustments) else { return [] }
        var nitro = NitroSliders(.vignette)
        nitro["intensity"] = context.blend(0, vignette[.exposure] * MappingConstants.Vignette.intensityScale)
        let contents = context.uncalibrated(nitro, block, "strength")
        if !contents.isEmpty {
            context.reportDropped(vignette, .softness, block, "softness was dropped; Nitro's vignette has a radius instead")
            context.reportDropped(vignette, .blackPoint, block, "black point was dropped; Nitro's vignette has none")
        }
        return contents
    }
}
