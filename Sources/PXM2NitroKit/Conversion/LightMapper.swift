/// Photomator Light (`l`) → Nitro Tone and Enhance. See `docs/mapping.md` §2.7.
///
/// - exposure → Tone `exposure` (EV)
/// - highlights → Tone `highlights` (neutral 1; only recovering, i.e. lowering, has a counterpart)
/// - shadows → Tone `shadows`
/// - brightness → Tone `midtones` (neutral 1)
/// - contrast → Enhance `contrast` (neutral 1); merged with Color's Enhance by the converter
///
/// Black point is skipped: Nitro's Black slider works on RAW files only. Clarity follows with
/// the Detail mapping; texture has no counterpart. The scale factors are not calibrated yet
/// (`MappingConstants`).
enum LightMapper: BlockMapper {
    static let block = PhotomatorBlock.light

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        guard let light: PhotomatorLight = context.sliders(block, in: adjustments) else { return [] }
        typealias Scale = MappingConstants.Light

        var tone = NitroSliders(.tone)
        tone["exposure"] = context.blend(0, light[.exposure] * Scale.exposureEVPerUnit)
        tone["highlights"] = context.multiplier(min(light[.highlights], 0), scale: Scale.highlightsScale)
        tone["shadows"] = context.blend(0, light[.shadows] * Scale.shadowsScale)
        tone["midtones"] = context.multiplier(light[.brightness], scale: Scale.brightnessScale)
        var enhance = NitroSliders(.enhance)
        enhance["contrast"] = context.multiplier(light[.contrast], scale: Scale.contrastScale)

        context.reportDropped(max(light[.highlights], 0), block,
                              "raised highlights were dropped; Nitro can only recover highlights")
        context.reportDropped(light[.blackPoint], block,
                              "black point was dropped; Nitro's Black slider works on RAW files only")
        context.reportDropped(light[.clarity], block, "clarity is not converted yet")
        context.reportDropped(light[.texture], block, "texture was dropped; Nitro has no texture slider")

        let contents = [tone, enhance].filter { !$0.isDefault }.map(NitroAdjustment.Content.sliders)
        if !contents.isEmpty {
            context.reportUncalibrated(block, "exposure, highlights, shadows, brightness and contrast")
        }
        return contents
    }
}
