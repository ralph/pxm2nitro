/// Scale factors for mappings whose units have not been calibrated against both apps yet.
/// Mappers that use them must call `MappingContext.reportUncalibrated`. See `docs/mapping.md`
/// §3 and `docs/sample-requests.md` for how to calibrate them.
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
        /// Saturation (±1 = ±100 %) → `saturation` multiplier `1 + scale · s`. Placeholder.
        static let saturationScale = 1.0
        /// Vibrance (±1 = ±100 %) → `vibrancy`. Placeholder.
        static let vibrancyScale = 1.0
    }

    /// Photomator Light (`l`) → Nitro Tone and Enhance. Stored as UI percent / 100 unless noted.
    enum Light {
        /// Exposure (±1 = ±100 %, UI range ±400 %) → `exposure` in EV. Placeholder: 100 % = 1 EV.
        static let exposureEVPerUnit = 1.0
        /// Highlights (stored ±2 = UI ±100 %, negative = recover) → `highlights` = 1 + scale · h
        /// (Nitro's neutral is 1). Placeholder: UI 100 % = 1.
        static let highlightsScale = 0.5
        /// Shadows (stored ±2 = UI ±100 %) → `shadows`. Placeholder: UI 100 % = 1.
        static let shadowsScale = 0.5
        /// Brightness (±1 = ±100 %) → `midtones` = 1 + scale · b (Nitro's neutral is 1). Placeholder.
        static let brightnessScale = 1.0
        /// Contrast (±1 = ±100 %) → Enhance `contrast` = 1 + scale · c. Placeholder.
        static let contrastScale = 1.0
        /// Clarity (±1 = ±100 %) → Detail `clarity`. Placeholder.
        static let clarityScale = 1.0
        /// Black point (±1 = ±100 %, range ±2) → Tone `blackPointDelta` (Nitro's Black slider,
        /// range ±1). Negative because the signs are opposite (`docs/mapping.md` §2.7); the
        /// magnitude 0.5 maps range onto range (Photomator +100 % looked weaker than Nitro −1).
        static let blackPointScale = -0.5
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
