/// State shared by all block mappers during one conversion.
struct MappingContext {
    /// Values closer than this count as equal (e.g. "this channel is unchanged").
    static let tolerance = 1e-6

    /// Preset intensity (`in`), 0…1.
    let intensity: Double
    private(set) var diagnostics: [ConversionDiagnostic] = []

    init(intensity: Double) {
        self.intensity = min(max(intensity, 0), 1)
    }

    /// Applies the preset intensity: interpolates from `neutral` (0 %) to `value` (100 %).
    func blend(_ neutral: Double, _ value: Double) -> Double {
        neutral + (value - neutral) * intensity
    }

    mutating func report(_ kind: ConversionDiagnostic.Kind, _ block: PhotomatorBlock?, _ message: String) {
        diagnostics.append(ConversionDiagnostic(kind, block, message))
    }

    /// Call whenever a mapper emits values scaled by `MappingConstants` that are not calibrated yet.
    mutating func reportUncalibrated(_ block: PhotomatorBlock, _ what: String) {
        report(.uncalibrated, block, "\(what) use placeholder scale factors until calibrated")
    }
}

/// Maps one Photomator block to zero or more Nitro adjustments.
protocol BlockMapper {
    static var block: PhotomatorBlock { get }
    /// Returns nothing if the block is disabled or neutral.
    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content]
}

func isNearlyEqual(_ a: Double, _ b: Double) -> Bool {
    abs(a - b) < MappingContext.tolerance
}

/// Photomator's five Curves/Levels channels arranged in Nitro's layout: one master channel
/// (RGB or, if RGB is unchanged, luminance) plus red, green and blue. Unchanged channels are `nil`.
struct NitroChannelLayout<Value: Sendable & Equatable> {
    var master: Value?
    /// Whether `master` came from the luminance channel.
    var operateOnGray: Bool
    var red: Value?
    var green: Value?
    var blue: Value?

    /// `nil` if every channel is unchanged. Reports a dropped luminance channel when both
    /// RGB and luminance are edited.
    init?(_ channels: ColorChannels<Value>, isIdentity: (Value) -> Bool,
          block: PhotomatorBlock, context: inout MappingContext) {
        func edited(_ value: Value?) -> Value? { value.flatMap { isIdentity($0) ? nil : $0 } }
        let rgb = edited(channels.rgb), luminance = edited(channels.luminance)
        master = rgb ?? luminance
        operateOnGray = rgb == nil && luminance != nil
        red = edited(channels.red)
        green = edited(channels.green)
        blue = edited(channels.blue)
        guard master != nil || red != nil || green != nil || blue != nil else { return nil }
        if rgb != nil, luminance != nil {
            context.report(.skipped, block,
                           "the luminance channel was dropped; Nitro has one master channel and the RGB channel was used")
        }
    }

    /// The edited channels with their Nitro slot.
    var slots: [(name: String, value: Value, keyPath: WritableKeyPath<NitroLevelsCurves, [NitroCurvePoint]>)] {
        [("master", master, \.master), ("red", red, \.red), ("green", green, \.green), ("blue", blue, \.blue)]
            .compactMap { name, value, keyPath in value.map { (name, $0, keyPath) } }
    }
}
