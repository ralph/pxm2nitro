/// Photomator Black & White (`b`) → Nitro BlackAndWhite. See `docs/mapping.md` §1.
///
/// Photomator's filter colour (R/G/B offsets) tilts Nitro's red/green/blue weights away from
/// Rec. 601; the weights are normalised to sum 1 so overall brightness stays put. The scale is
/// not calibrated yet (`MappingConstants`). Nitro's black & white has no toning, intensity or
/// filter luminance/saturation, so those are reported. It always turns the image grey, so it is
/// written even with a neutral filter.
enum BlackAndWhiteMapper: BlockMapper {
    static let block = PhotomatorBlock.blackAndWhite

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        guard let bw: PhotomatorSliders<BlackAndWhiteField> = context.sliders(block, in: adjustments),
              let filter: PhotomatorSliders<ColorWheelField> = context.sliders(block, key: "b", in: adjustments)
        else { return [] }

        var nitro = NitroSliders(.blackAndWhite)
        let offsets = [("red", filter[.red]), ("green", filter[.green]), ("blue", filter[.blue])]
            .map { key, offset in (key, context.blend(0, offset)) }
        if offsets.contains(where: { !isNearlyEqual($0.1, 0) }) {
            // Tilt each Rec. 601 weight, then normalise so the weights still sum to 1.
            let weights = offsets.map { key, offset in
                nitro[key] * max(0, 1 + offset * MappingConstants.BlackAndWhite.filterScale)
            }
            let total = weights.reduce(0, +)
            if total > MappingContext.tolerance {
                for ((key, _), weight) in zip(offsets, weights) { nitro[key] = weight / total }
            }
            context.reportUncalibrated(block, "the filter colour")
        }
        context.reportDropped(bw, .tone, block, "toning was dropped; Nitro's black & white has no toning")
        context.reportDropped(bw, .intensity, block, "the intensity was dropped; Nitro's black & white is all or nothing")
        if context.intensity < 1 - MappingContext.tolerance {
            context.report(.approximated, block, "the preset intensity cannot weaken Nitro's black & white")
        }
        context.reportDropped(filter, .luminance, block, "the filter luminance was dropped")
        context.reportDropped(filter, .saturation, block, "the filter saturation was dropped")
        return [.sliders(nitro)]
    }
}
