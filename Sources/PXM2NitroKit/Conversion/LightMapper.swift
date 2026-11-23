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
        guard adjustments.enabledBlock(block) != nil else { return [] }
        guard let light = adjustments.light else {
            context.report(.skipped, block, "a value is not a number")
            return []
        }
        typealias Scale = MappingConstants.Light
        let highlights = context.blend(0, light.highlights)

        var tone = NitroSliders(.tone)
        tone["exposure"] = context.blend(0, light.exposure * Scale.exposureEVPerUnit)
        tone["highlights"] = max(0, 1 + min(highlights, 0) * Scale.highlightsScale)
        tone["shadows"] = context.blend(0, light.shadows * Scale.shadowsScale)
        tone["midtones"] = max(0, 1 + context.blend(0, light.brightness) * Scale.brightnessScale)
        var enhance = NitroSliders(.enhance)
        enhance["contrast"] = max(0, 1 + context.blend(0, light.contrast) * Scale.contrastScale)

        if highlights > MappingContext.tolerance {
            context.report(.skipped, block, "raised highlights were dropped; Nitro can only recover highlights")
        }
        let dropped = [
            (light.blackPoint, "black point was dropped; Nitro's Black slider works on RAW files only"),
            (light.clarity, "clarity is not converted yet"),
            (light.texture, "texture was dropped; Nitro has no texture slider"),
        ]
        for (value, message) in dropped where !isNearlyEqual(context.blend(0, value), 0) {
            context.report(.skipped, block, message)
        }

        let contents = [tone, enhance].filter { !$0.isDefault }.map(NitroAdjustment.Content.sliders)
        if !contents.isEmpty {
            context.reportUncalibrated(block, "exposure, highlights, shadows, brightness and contrast")
        }
        return contents
    }
}
