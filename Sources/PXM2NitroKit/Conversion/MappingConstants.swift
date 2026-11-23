/// Scale factors from Photomator's stored values to Nitro's. Values marked *measured* were
/// matched on screen (`docs/mapping.md` §3.1, `docs/sample-log.md` C-2); the rest are
/// placeholders, and mappers that use them must report them (`MappingContext.reportUncalibrated`,
/// or `ScaleMatch.placeholder` with `MappingContext.report(_:_:curveDiffers:)`).
enum MappingConstants {
    /// Photomator Selective Color → Nitro HSL. Storage scales differ per slider (sample `C`).
    enum SelectiveColor {
        /// Hue (stored ±4 = UI ±100 %) → `hueDelta` in degrees. Placeholder: UI 100 % = 30°.
        static let hueDegreesPerUnit = 7.5
        /// Saturation (stored ±1 = UI ±100 %) → `saturationDelta`. Placeholder.
        static let saturationScale = 1.0
        /// Brightness (stored ±4 = UI ±200 %) → `lumaDelta`. Placeholder: UI 100 % = 1.
        static let brightnessScale = 0.5
    }

    /// Photomator Color (`hS`, UI values stored as percent / 100) → Nitro Enhance.
    enum Color {
        /// Saturation (±1 = ±100 %) → `saturation` multiplier `1 + scale · s`. Measured:
        /// +50 % raises saturation 1.41×, Nitro's multiplier acts 1:1.
        static let saturationScale = 0.8
        /// Vibrance (±1 = ±100 %) → `vibrancy`. Placeholder: Nitro's vibrance boosts muted
        /// colours far more and saturated ones far less than Photomator's, so no factor fits.
        static let vibrancyScale = 1.0
    }

    /// Photomator Light (`l`) → Nitro Tone and Enhance. Stored as UI percent / 100 unless noted.
    enum Light {
        /// Exposure (±1 = ±100 %, UI range ±400 %) → `exposure` in EV. Measured: 100 % ≈ 1.03 EV.
        static let exposureEVPerUnit = 1.0
        /// Highlights (stored ±2 = UI ±100 %, negative = recover) → `highlights` = 1 + scale · h
        /// (Nitro's neutral is 1). Measured on the bright tones: −50 % ≈ 0.75. Nitro also
        /// darkens the midtones more.
        static let highlightsScale = 0.25
        /// Shadows (stored ±2 = UI ±100 %) → `shadows`. Measured: +50 % ≈ 0.12; Nitro's slider
        /// is about four times as strong and reaches further into the midtones.
        static let shadowsScale = 0.12
        /// Brightness (±1 = ±100 %) → `midtones` = 1 + scale · b (Nitro's neutral is 1).
        /// Measured on the midtones: +50 % ≈ 1.25; Nitro lifts the shadows more.
        static let brightnessScale = 0.5
        /// Contrast (±1 = ±100 %) → Enhance `contrast` = 1 + scale · c. Measured by the slope of
        /// the tone curve: +50 % ≈ 1.15; Nitro also darkens the midtones and adds saturation.
        static let contrastScale = 0.3
        /// Clarity (±1 = ±100 %) → Detail `clarity`. Placeholder from a rough match: Nitro's
        /// clarity is a weak local effect, Photomator's acts like strong contrast, so Nitro's
        /// +1 only reaches about Photomator's +30 %.
        static let clarityScale = 3.0
        /// Black point (±1 = ±100 %, range ±2) → Tone `blackPointDelta` (Nitro's Black slider,
        /// range ±1). Negative because the signs are opposite (`docs/mapping.md` §2.7).
        /// Measured: +50 % ≈ −0.5, matching shadows, midtones and saturation.
        static let blackPointScale = -1.0
    }

    /// Photomator Sharpen (`S`) → Nitro Detail.
    enum Sharpen {
        /// Intensity (0…1, default 0.5) → `sharpen`. Placeholder.
        static let intensityScale = 1.0
    }

    /// Photomator Vignette (`v`) → Nitro Vignette.
    enum Vignette {
        /// Exposure (vignette strength, default 0.5) → `intensity` (Nitro's default 0.5). Placeholder.
        static let intensityScale = 1.0
    }

    /// Photomator Black & White (`b`) filter colour → Nitro BlackAndWhite channel weights.
    enum BlackAndWhite {
        /// A filter offset `o` (±1) scales a channel's Rec. 601 weight by `1 + scale · o` before
        /// the weights are normalised to sum 1. Placeholder.
        static let filterScale = 1.0
    }
}
