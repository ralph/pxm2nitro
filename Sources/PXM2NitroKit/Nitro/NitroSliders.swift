/// Nitro adjustments that are plain sliders (`numeric`) plus a few fixed keys.
/// See `docs/nitro-format.md` §3.
public enum NitroSliderKind: String, CaseIterable, Sendable {
    case tone = "Tone"
    case enhance = "Enhance"
    case detail = "Detail"
    case vignette = "Vignette"
    case blackAndWhite = "BlackAndWhite"

    /// Every slider with its default value, as Nitro writes them. A default is not always
    /// a no-op: Nitro's default B&W and Vignette still change the image.
    public var defaults: [String: Double] {
        switch self {
        case .tone: Self.toneDefaults
        case .enhance: Self.enhanceDefaults
        case .detail: Self.detailDefaults
        case .vignette: Self.vignetteDefaults
        case .blackAndWhite: Self.blackAndWhiteDefaults
        }
    }

    private static let toneDefaults: [String: Double] = [
        "exposure": 0, "highlights": 1, "shadows": 0, "midtones": 1, "recovery": 0, "boost": 1,
        "boostShadowSliderValue": 0.9, "blackPointDelta": 0, "whitePointDelta": 0, "toneMap": 0,
    ]
    private static let enhanceDefaults: [String: Double] = [
        "deepen": 0, "lighten": 0, "contrast": 1, "saturation": 1, "vibrancy": 0,
    ]
    /// As in Nitro's own saved Detail presets: noise sliders at 0, so applying the preset sets
    /// noise reduction to 0 just like a clarity preset saved in Nitro does.
    private static let detailDefaults: [String: Double] = [
        "clarity": 0, "sharpen": 0, "lumaNoise": 0, "colorNoise": 0, "noiseDetail": 0, "blur": 0,
        "jpegNoise": 0, "grainIntensity": 0, "grainDensity": 0.5,
    ]
    private static let vignetteDefaults: [String: Double] = ["intensity": 0.5, "radius": 0.5]
    /// Rec. 601 luma weights.
    private static let blackAndWhiteDefaults: [String: Double] = ["red": 0.299, "green": 0.587, "blue": 0.114]

    /// The range of each slider in Nitro's UI (N-3, `docs/nitro-format.md` §3). Mappers clamp
    /// to it so a preset never holds a value Nitro's own sliders cannot produce. Sliders not
    /// listed (B&W weights, unused keys) are not clamped.
    var ranges: [String: ClosedRange<Double>] {
        switch self {
        case .tone: Self.toneRanges
        case .enhance: Self.enhanceRanges
        case .detail: Self.detailRanges
        case .vignette: Self.vignetteRanges
        case .blackAndWhite: [:]
        }
    }

    private static let toneRanges: [String: ClosedRange<Double>] = [
        "exposure": -3...3, "highlights": 0...1, "shadows": -1...1, "midtones": 0.5...1.5,
        "recovery": -1...1, "boost": 0...1, "boostShadowSliderValue": 0...1,
        "blackPointDelta": -1...1, "whitePointDelta": -1...1,
    ]
    private static let enhanceRanges: [String: ClosedRange<Double>] = [
        "deepen": 0...2, "lighten": 0...2, "contrast": 0...2, "saturation": 0...2, "vibrancy": -1...1,
    ]
    private static let detailRanges: [String: ClosedRange<Double>] = [
        "clarity": -1...1, "sharpen": -1...1, "lumaNoise": 0...1,
    ]
    private static let vignetteRanges: [String: ClosedRange<Double>] = ["intensity": -1...1, "radius": 0...1]

    /// Slider values at which the adjustment changes nothing. Usually the defaults, but Nitro's
    /// default vignette still darkens the edges, so only zero intensity is neutral there, and
    /// black & white always changes the image (`nil`). Never use `[:]`: it would mean "always
    /// a no-op".
    var neutral: [String: Double]? {
        switch self {
        case .vignette: ["intensity": 0]
        case .blackAndWhite: nil
        default: defaults
        }
    }

    /// Keys besides `numeric`, `enabled` and `disclosed` that Nitro writes for this adjustment.
    var fixedKeys: [String: JSONValue] {
        switch self {
        // Leica M11 base points; Nitro keeps each image's own on apply (`docs/nitro-format.md` §3.2).
        case .tone: ["preserve": false, "defaultsUpdated": true, "baseBlackPoint": 5, "baseWhitePoint": 0.15,
                     "bpIsAbs": false, "wpIsAbs": false, "supportsBoost": true, "supportsToneMap": false]
        case .enhance: [:]
        // Nitro writes a random grain seed. A fixed one keeps the output reproducible; it only
        // matters with grain, which the converter does not write.
        case .detail: ["preserve": false, "defaultsUpdated": true, "grainSeed": 25.016823]
        case .vignette: ["center": [0.5, 0.5]]
        case .blackAndWhite: [:]
        }
    }
}

/// One slider adjustment. New values start from Nitro's defaults, so the written key set is
/// always one Nitro writes itself (`docs/mapping.md` §0.3).
public struct NitroSliders: Sendable, Equatable {
    public let kind: NitroSliderKind
    /// Slider values, including ones that were read but are not in `kind.defaults`.
    private(set) var numeric: [String: Double]
    /// Non-slider keys, from the template or as read.
    var otherKeys: [String: JSONValue]
    /// Sliders set through the subscript, i.e. by a mapper. Not part of equality.
    private var setKeys: Set<String> = []

    /// The adjustment with every slider at its default value.
    public init(_ kind: NitroSliderKind) {
        self.kind = kind
        numeric = kind.defaults
        otherKeys = kind.fixedKeys
    }

    public subscript(key: String) -> Double {
        get { numeric[key] ?? kind.defaults[key] ?? 0 }
        set {
            precondition(kind.defaults[key] != nil, "\(kind.rawValue) has no slider \(key)")
            numeric[key] = newValue
            setKeys.insert(key)
        }
    }

    /// Whether the adjustment changes nothing (see `NitroSliderKind.neutral`), so there is
    /// nothing to write.
    public var isNoOp: Bool {
        kind.neutral?.allSatisfy { key, value in isNearlyEqual(self[key], value) } ?? false
    }

    /// Takes over every slider `other` set. Two mappers writing the same adjustment must set
    /// different sliders; a collision is a programming error that needs an explicit rule.
    mutating func merge(_ other: NitroSliders) {
        precondition(kind == other.kind, "cannot merge \(other.kind.rawValue) into \(kind.rawValue)")
        for key in other.setKeys {
            precondition(!setKeys.contains(key), "two mappers set \(kind.rawValue) \(key)")
            self[key] = other[key]
        }
    }

    public static func == (lhs: NitroSliders, rhs: NitroSliders) -> Bool {
        lhs.kind == rhs.kind && lhs.numeric == rhs.numeric && lhs.otherKeys == rhs.otherKeys
    }

    var json: [String: JSONValue] {
        otherKeys.merging(["numeric": .object(numeric.mapValues { .number($0) })]) { $1 }
    }

    /// Parses an inner object; `nil` if `numeric` is missing or holds a non-number.
    init?(kind: NitroSliderKind, json: JSONValue) {
        guard var object = json.objectValue, let raw = object.removeValue(forKey: "numeric")?.objectValue
        else { return nil }
        let numeric = raw.compactMapValues(\.doubleValue)
        guard numeric.count == raw.count else { return nil }
        // `NitroAdjustment` owns these; dropping them keeps a parsed block equal to a built one.
        object["enabled"] = nil
        object["disclosed"] = nil
        self.kind = kind
        self.numeric = numeric
        otherKeys = object
    }
}
