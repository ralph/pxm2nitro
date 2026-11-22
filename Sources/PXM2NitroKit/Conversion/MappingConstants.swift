/// Scale factors for mappings whose units have not been calibrated against both apps yet.
/// Mappers that use them report an `.uncalibrated` diagnostic. See `docs/mapping.md` §3 and
/// `docs/sample-requests.md` (P-2) for how to calibrate them.
enum MappingConstants {
    /// Photomator Selective Color hue (stored ±1 = ±100 % in the UI, range ±4) → Nitro HSL
    /// `hueDelta` in degrees. Placeholder until calibrated.
    static let selectiveColorHueDegreesPerUnit = 30.0
    /// Photomator Selective Color saturation (±1 = ±100 %) → Nitro `saturationDelta`.
    static let selectiveColorSaturationScale = 1.0
    /// Photomator Selective Color brightness (±1 = ±100 %) → Nitro `lumaDelta`.
    static let selectiveColorBrightnessScale = 1.0
}
