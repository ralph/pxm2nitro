/// Photomator Light (`l`) → Nitro Tone, Enhance and Detail. See `docs/mapping.md` §2.7.
///
/// - exposure → Tone `exposure` (EV)
/// - highlights → Tone `highlights` (neutral 1; only recovering, i.e. lowering, has a counterpart)
/// - shadows → Tone `shadows`
/// - brightness → Tone `midtones` (neutral 1)
/// - black point → Tone `blackPointDelta` (Nitro's Black slider; it acts on RAW files only,
///   Nitro's main use case)
/// - contrast → Enhance `contrast` (neutral 1); merged with Color's Enhance by the converter
/// - clarity → Detail `clarity`; merged with Sharpen's Detail by the converter
///
/// Texture has no counterpart. The scale factors, including the black point's sign, are not
/// calibrated yet (`MappingConstants`).
enum LightMapper: BlockMapper {
    static let block = PhotomatorBlock.light

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        guard let light: PhotomatorLight = context.sliders(block, in: adjustments) else { return [] }
        typealias Scale = MappingConstants.Light

        // Sets a slider and remembers its Photomator name if it moved, for the uncalibrated note.
        var converted: [String] = []
        func set(_ sliders: inout NitroSliders, _ key: String, _ value: Double, as name: String) {
            sliders[key] = value
            if !isNearlyEqual(value, sliders.kind.defaults[key] ?? 0) { converted.append(name) }
        }

        var tone = NitroSliders(.tone), enhance = NitroSliders(.enhance), detail = NitroSliders(.detail)
        set(&tone, "exposure", context.blend(0, light[.exposure] * Scale.exposureEVPerUnit), as: "exposure")
        set(&tone, "highlights", context.multiplier(min(light[.highlights], 0), scale: Scale.highlightsScale,
                                                    block, "highlights"), as: "highlights")
        set(&tone, "shadows", context.blend(0, light[.shadows] * Scale.shadowsScale), as: "shadows")
        set(&tone, "blackPointDelta", context.blend(0, light[.blackPoint] * Scale.blackPointScale), as: "black point")
        set(&tone, "midtones", context.multiplier(light[.brightness], scale: Scale.brightnessScale, block, "brightness"),
            as: "brightness")
        set(&enhance, "contrast", context.multiplier(light[.contrast], scale: Scale.contrastScale, block, "contrast"),
            as: "contrast")
        set(&detail, "clarity", context.blend(0, light[.clarity] * Scale.clarityScale), as: "clarity")

        context.reportDropped(max(light[.highlights], 0), block,
                              "raised highlights were dropped; Nitro can only recover highlights")
        context.reportDropped(light, .texture, block, "texture was dropped; Nitro has no texture slider")

        context.reportUncalibrated(block, converted)
        return [tone, enhance, detail].filter { !$0.isNoOp }.map(NitroAdjustment.Content.sliders)
    }
}
