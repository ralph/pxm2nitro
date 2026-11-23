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
        // ColorWheelField's raw values are Nitro's channel keys.
        let channels: [ColorWheelField] = [.red, .green, .blue]
        if channels.contains(where: { !isNearlyEqual(context.blend(0, filter[$0]), 0) }) {
            // Tilt each Rec. 601 weight, then normalise so the weights still sum to 1.
            let weights = channels.map { channel in
                nitro[channel.rawValue] * context.multiplier(filter[channel], scale: MappingConstants.BlackAndWhite.filterScale,
                                                             block, "the \(channel.rawValue) filter")
            }
            let total = weights.reduce(0, +)
            if total > MappingContext.tolerance {
                for (channel, weight) in zip(channels, weights) { nitro[channel.rawValue] = weight / total }
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
