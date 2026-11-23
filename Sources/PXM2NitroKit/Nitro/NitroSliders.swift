/// Nitro adjustments that are plain sliders (`numeric`) plus a few fixed keys.
/// See `docs/nitro-format.md` §3.
public enum NitroSliderKind: String, CaseIterable, Sendable {
    case enhance = "Enhance"

    /// Every slider with its neutral value, as Nitro writes them.
    public var neutral: [String: Double] {
        switch self {
        case .enhance: ["deepen": 0, "lighten": 0, "contrast": 1, "saturation": 1, "vibrancy": 0]
        }
    }

    /// Keys besides `numeric`, `enabled` and `disclosed` that Nitro writes for this adjustment.
    var fixedKeys: [String: JSONValue] {
        switch self {
        case .enhance: [:]
        }
    }
}

/// One slider adjustment. New values start from the neutral template, so the written key set
/// is always one Nitro writes itself (`docs/mapping.md` §0.3).
public struct NitroSliders: Sendable, Equatable {
    public let kind: NitroSliderKind
    /// Slider values, including ones that were read but are not in `kind.neutral`.
    public private(set) var numeric: [String: Double]
    /// Non-slider keys, from the template or as read.
    var otherKeys: [String: JSONValue]

    /// The adjustment with every slider at its neutral value.
    public init(_ kind: NitroSliderKind) {
        self.kind = kind
        numeric = kind.neutral
        otherKeys = kind.fixedKeys
    }

    public subscript(key: String) -> Double {
        get { numeric[key] ?? kind.neutral[key] ?? 0 }
        set {
            assert(kind.neutral[key] != nil, "\(kind.rawValue) has no slider \(key)")
            numeric[key] = newValue
        }
    }

    /// Whether every slider is at its neutral value.
    public var isNeutral: Bool {
        kind.neutral.allSatisfy { key, neutral in isNearlyEqual(self[key], neutral) }
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
        object["enabled"] = nil
        object["disclosed"] = nil
        self.kind = kind
        self.numeric = numeric
        otherKeys = object
    }
}
