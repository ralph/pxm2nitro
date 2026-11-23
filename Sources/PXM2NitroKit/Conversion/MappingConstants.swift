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
}
