import Foundation

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

    /// A Nitro multiplier whose neutral is 1: `1 + scale · value` after intensity, never below 0.
    /// Reports `what` as approximated when the value had to be clamped to 0.
    mutating func multiplier(_ value: Double, scale: Double, _ block: PhotomatorBlock, _ what: String) -> Double {
        let raw = factor(value, scale: scale)
        if raw < -MappingContext.tolerance {
            report(.approximated, block, "\(what) was clamped to Nitro's minimum")
        }
        return max(0, raw)
    }

    /// A factor whose neutral is 1: `1 + scale · value` after intensity, unclamped (`set`
    /// clamps it to the slider's range, `multiplier` to 0).
    func factor(_ value: Double, scale: Double) -> Double {
        1 + blend(0, value) * scale
    }

    /// `value` limited to `range`. Reports `what` as approximated when it had to be clamped.
    mutating func clamp(_ value: Double, to range: ClosedRange<Double>,
                        _ block: PhotomatorBlock, _ what: String) -> Double {
        let clamped = range.clamping(value)
        if !isNearlyEqual(clamped, value) {
            report(.approximated, block, String(format: "%@ was clamped to Nitro's range (%g to %g)",
                                                what, range.lowerBound, range.upperBound))
        }
        return clamped
    }

    /// Sets a slider, clamped to Nitro's range for it (`NitroSliderKind.ranges`).
    mutating func set(_ sliders: inout NitroSliders, _ key: String, _ value: Double,
                      _ block: PhotomatorBlock, _ what: String) {
        var value = value
        if let range = sliders.kind.ranges[key] { value = clamp(value, to: range, block, what) }
        sliders[key] = value
    }

    /// The fields of an enabled slider block or one of its sub-objects (`key`). Reports an
    /// enabled block that cannot be read.
    mutating func sliders<Field>(_ block: PhotomatorBlock, key: String? = nil,
                                 in adjustments: PhotomatorAdjustments) -> PhotomatorSliders<Field>? {
        guard adjustments.enabledBlock(block) != nil else { return nil }
        guard let sliders = adjustments.sliders(block, key: key, as: Field.self) else {
            report(.skipped, block, key.map { "the sub-object \($0) is malformed" } ?? "a value is not a number")
            return nil
        }
        return sliders
    }

    /// Reports a value that has no Nitro counterpart, unless it is at `neutral` (after intensity).
    mutating func reportDropped(_ value: Double, neutral: Double = 0, _ block: PhotomatorBlock, _ message: String) {
        if !isNearlyEqual(blend(neutral, value), neutral) { report(.skipped, block, message) }
    }

    /// Same for a Photomator field, which is neutral at its Photomator default.
    mutating func reportDropped<Field>(_ sliders: PhotomatorSliders<Field>, _ field: Field,
                                       _ block: PhotomatorBlock, _ message: String) {
        reportDropped(sliders[field], neutral: field.defaultValue, block, message)
    }

    /// Call whenever a mapper emits values scaled by `MappingConstants` that are not calibrated yet.
    mutating func reportUncalibrated(_ block: PhotomatorBlock, _ what: String) {
        report(.uncalibrated, block, "\(what): placeholder scale, not calibrated yet")
    }

    /// The sliders as Nitro content, with their placeholder scales reported; nothing if the
    /// adjustment changes nothing.
    mutating func uncalibrated(_ sliders: NitroSliders, _ block: PhotomatorBlock, _ what: String) -> [NitroAdjustment.Content] {
        guard !sliders.isNoOp else { return [] }
        reportUncalibrated(block, what)
        return [.sliders(sliders)]
    }

    /// Same for a list of converted sliders ("a, b and c"); reports nothing for an empty list.
    mutating func reportUncalibrated(_ block: PhotomatorBlock, _ sliders: [String]) {
        guard !sliders.isEmpty else { return }
        reportUncalibrated(block, listed(sliders))
    }

    /// Reports channels of an enabled Curves/Levels/Channel Mixer block whose raw payload
    /// could not be (fully) read, so the block is not mistaken for neutral.
    mutating func reportUnreadableChannels<Value>(
        _ channels: ColorChannels<Value>?, in adjustments: PhotomatorAdjustments, block: PhotomatorBlock,
        isUnreadable: (_ raw: JSONValue, _ parsed: Value?) -> Bool
    ) {
        guard let payload = adjustments.enabledBlock(block) else { return }
        let entries: [(key: String, name: String, parsed: Value?)] = [
            ("rgb", "RGB", channels?.rgb), ("r", "red", channels?.red), ("g", "green", channels?.green),
            ("b", "blue", channels?.blue), ("l", "luminance", channels?.luminance),
        ]
        for entry in entries {
            guard let raw = payload[entry.key], isUnreadable(raw, entry.parsed) else { continue }
            report(.skipped, block, "the \(entry.name) channel is malformed and could not be read completely")
        }
    }
}

/// Maps one Photomator block to zero or more Nitro adjustments.
protocol BlockMapper {
    static var block: PhotomatorBlock { get }
    /// Returns nothing if the block is disabled or neutral. An enabled block that changes the
    /// image but cannot be converted must report a diagnostic for `block`; otherwise it is
    /// treated as neutral (see `ConversionResult.blocks`).
    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content]
}

/// "a", "a and b", "a, b and c".
func listed(_ names: [String]) -> String {
    guard let last = names.last else { return "" }
    return names.count == 1 ? last : names.dropLast().joined(separator: ", ") + " and " + last
}

extension ClosedRange<Double> {
    /// `value` limited to the range.
    func clamping(_ value: Double) -> Double {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}

func isNearlyEqual(_ a: Double, _ b: Double) -> Bool {
    abs(a - b) < MappingContext.tolerance
}

/// Photomator's five Curves/Levels channels arranged in Nitro's layout: one master channel
/// (RGB or, if RGB is unchanged, luminance) plus red, green and blue. Unchanged channels are `nil`.
struct NitroChannelLayout<Value: Sendable & Equatable> {
    var master: Value?
    /// `false` only when `master` came from the luminance channel. Nitro's UI always saves `true`,
    /// which applies the master curve to each RGB channel; `false` renders like a brightness-only
    /// curve (`docs/nitro-format.md` §3.6).
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
        operateOnGray = !(rgb == nil && luminance != nil)
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
