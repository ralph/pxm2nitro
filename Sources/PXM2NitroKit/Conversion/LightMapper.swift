/// Photomator Light (`l`) → Nitro Tone, Enhance and Detail. See `docs/mapping.md` §2.7.
///
/// - exposure → Tone `exposure` (EV)
/// - highlights → Tone `highlights` (neutral 1; only recovering, i.e. lowering, has a counterpart)
/// - shadows → Tone `shadows`
/// - brightness → Tone `midtones` (neutral 1)
/// - black point → Tone `blackPointDelta` (Nitro's Black slider, see `docs/mapping.md` §2.7)
/// - contrast → Enhance `contrast` (neutral 1); merged with Color's Enhance by the converter
/// - clarity → Detail `clarity`; merged with Sharpen's Detail by the converter
///
/// Texture has no counterpart. Every value is clamped to Nitro's slider range. Exposure and
/// black point match closely; highlights, shadows, brightness and contrast are matched by
/// measurement but Nitro's tone curves differ, so they are reported as approximated; clarity
/// is still a placeholder (`MappingConstants`).
enum LightMapper: BlockMapper {
    static let block = PhotomatorBlock.light

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        guard let light: PhotomatorLight = context.sliders(block, in: adjustments) else { return [] }
        typealias Scale = MappingConstants.Light

        /// How closely a slider's Nitro counterpart matches.
        enum Match { case close, curveDiffers, placeholder }
        // Sets a slider (clamped to Nitro's range) and remembers its Photomator name if it moved,
        // for the approximated and uncalibrated notes.
        var approximate: [String] = [], uncalibrated: [String] = []
        func set(_ sliders: inout NitroSliders, _ key: String, _ value: Double, as name: String, _ match: Match) {
            context.set(&sliders, key, value, block, name)
            guard !isNearlyEqual(sliders[key], sliders.kind.defaults[key] ?? 0) else { return }
            switch match {
            case .close: break
            case .curveDiffers: approximate.append(name)
            case .placeholder: uncalibrated.append(name)
            }
        }

        var tone = NitroSliders(.tone), enhance = NitroSliders(.enhance), detail = NitroSliders(.detail)
        set(&tone, "exposure", context.blend(0, light[.exposure] * Scale.exposureEVPerUnit), as: "exposure", .close)
        set(&tone, "highlights", context.factor(min(light[.highlights], 0), scale: Scale.highlightsScale),
            as: "highlights", .curveDiffers)
        set(&tone, "shadows", context.blend(0, light[.shadows] * Scale.shadowsScale), as: "shadows", .curveDiffers)
        set(&tone, "blackPointDelta", context.blend(0, light[.blackPoint] * Scale.blackPointScale),
            as: "black point", .close)
        set(&tone, "midtones", context.factor(light[.brightness], scale: Scale.brightnessScale),
            as: "brightness", .curveDiffers)
        set(&enhance, "contrast", context.factor(light[.contrast], scale: Scale.contrastScale),
            as: "contrast", .curveDiffers)
        set(&detail, "clarity", context.blend(0, light[.clarity] * Scale.clarityScale), as: "clarity", .placeholder)

        context.reportDropped(max(light[.highlights], 0), block,
                              "raised highlights were dropped; Nitro can only recover highlights")
        context.reportDropped(light, .texture, block, "texture was dropped; Nitro has no texture slider")

        if !approximate.isEmpty {
            context.report(.approximated, block, "\(listed(approximate)): Nitro's tone curve differs from Photomator's")
        }
        context.reportUncalibrated(block, uncalibrated)
        return [tone, enhance, detail].filter { !$0.isNoOp }.map(NitroAdjustment.Content.sliders)
    }
}
