/// Scale factors for mappings whose units have not been calibrated against both apps yet.
/// Mappers that use them must call `MappingContext.reportUncalibrated`. See `docs/mapping.md`
/// §3 and `docs/sample-requests.md` for how to calibrate them.
enum MappingConstants {
    /// Photomator Selective Color (UI values stored as percent / 100) → Nitro HSL.
    enum SelectiveColor {
        /// Hue (±1 = ±100 %, range ±4) → `hueDelta` in degrees. Placeholder.
        static let hueDegreesPerUnit = 30.0
        /// Saturation (±1 = ±100 %) → `saturationDelta`. Placeholder.
        static let saturationScale = 1.0
        /// Brightness (±1 = ±100 %) → `lumaDelta`. Placeholder.
        static let brightnessScale = 1.0
    }

    /// Photomator Color (`hS`, UI values stored as percent / 100) → Nitro Enhance.
    enum Color {
        /// Saturation (±1 = ±100 %) → `saturation` multiplier `1 + scale · s`. Placeholder.
        static let saturationScale = 1.0
        /// Vibrance (±1 = ±100 %) → `vibrancy`. Placeholder.
        static let vibrancyScale = 1.0
    }

    /// Photomator Light (`l`, UI values stored as percent / 100) → Nitro Tone and Enhance.
    enum Light {
        /// Exposure (±1 = ±100 %) → `exposure` in EV. Placeholder: 100 % = 1 EV.
        static let exposureEVPerUnit = 1.0
        /// Highlights (negative = recover) → `highlights` = 1 + scale · h (Nitro's neutral is 1). Placeholder.
        static let highlightsScale = 1.0
        /// Shadows (±1 = ±100 %) → `shadows`. Placeholder.
        static let shadowsScale = 1.0
        /// Brightness (±1 = ±100 %) → `midtones` = 1 + scale · b (Nitro's neutral is 1). Placeholder.
        static let brightnessScale = 1.0
        /// Contrast (±1 = ±100 %) → Enhance `contrast` = 1 + scale · c. Placeholder.
        static let contrastScale = 1.0
    }
}
