/// Photomator Sharpen (`S`) → Nitro Detail `sharpen`. See `docs/mapping.md` §1.
///
/// Nitro's sharpening has no radius, so a radius other than Photomator's default is reported.
/// The scale factor is not calibrated yet (`MappingConstants`).
enum SharpenMapper: BlockMapper {
    static let block = PhotomatorBlock.sharpen

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        guard let sharpen: PhotomatorSharpen = context.sliders(block, in: adjustments) else { return [] }
        var detail = NitroSliders(.detail)
        // Missing fields are at Photomator's defaults, which (unlike other blocks) are not 0.
        let intensity = sharpen.values[.intensity] ?? SharpenField.defaultIntensity
        let radius = sharpen.values[.radius] ?? SharpenField.defaultRadius
        detail["sharpen"] = context.blend(0, intensity * MappingConstants.Sharpen.intensityScale)
        let contents = context.uncalibrated(detail, block, "sharpening")
        if !contents.isEmpty {
            context.reportDropped(radius, neutral: SharpenField.defaultRadius, block,
                                  "the radius was dropped; Nitro's sharpening has no radius")
        }
        return contents
    }
}
