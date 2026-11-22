/// One entry of a Nitro edit version's `adjDataArr`. See `docs/nitro-format.md` §3.
///
/// Adjustments the converter writes are modelled explicitly; everything else is kept as
/// raw JSON (`.other`) so that reading and re-writing a preset is lossless.
public struct NitroAdjustment: Sendable, Equatable {
    public enum Content: Sendable, Equatable {
        case curves(LevelsCurvesData)
        case levels(LevelsCurvesData)
        case channelMixer(NitroChannelMixer)
        case hsl(NitroHSL)
        /// An adjustment not modelled here; `json` is the complete inner object.
        case other(id: String, json: JSONValue)
    }

    public var content: Content
    /// The adjustment's checkbox.
    public var isEnabled: Bool
    /// Whether the panel is expanded in Nitro's sidebar (cosmetic).
    public var isDisclosed: Bool

    public init(_ content: Content, isEnabled: Bool = true, isDisclosed: Bool = false) {
        self.content = content
        self.isEnabled = isEnabled
        self.isDisclosed = isDisclosed
    }

    /// The `adjDataArr[].id` value.
    public var id: String {
        switch content {
        case .curves: "Curves"
        case .levels: "Levels"
        case .channelMixer: "ChannelMixer"
        case .hsl: "HSL"
        case .other(let id, _): id
        }
    }

    /// The inner object that Nitro stores, string-encoded, in `adjDataArr[].json`.
    public var json: JSONValue {
        var object: [String: JSONValue]
        switch content {
        case .curves(let data):
            object = ["id": "Curves", "name": "Curves", "localizedName": "Curves",
                      "numeric": [:], "levelsCurvesData": data.json]
        case .levels(let data):
            object = ["levelsCurvesData": data.json]
        case .channelMixer(let mixer):
            object = ["numeric": .object(mixer.numeric)]
        case .hsl(let hsl):
            object = ["version": 1, "numeric": .object(hsl.numeric)]
        case .other(_, let json):
            return json
        }
        object["enabled"] = .bool(isEnabled)
        object["disclosed"] = .bool(isDisclosed)
        return .object(object)
    }

    /// Parses an `adjDataArr` entry; unknown or unexpected shapes become `.other`.
    public init(id: String, json: JSONValue) {
        let content: Content? = switch id {
        case "Curves": json["levelsCurvesData"].flatMap(LevelsCurvesData.init(json:)).map(Content.curves)
        case "Levels": json["levelsCurvesData"].flatMap(LevelsCurvesData.init(json:)).map(Content.levels)
        case "ChannelMixer": json["numeric"]?.objectValue.map { .channelMixer(NitroChannelMixer(numeric: $0)) }
        case "HSL": json["numeric"]?.objectValue.map { .hsl(NitroHSL(numeric: $0)) }
        default: nil
        }
        guard let content else {
            self.init(.other(id: id, json: json))
            return
        }
        self.init(content,
                  isEnabled: json["enabled"]?.boolValue ?? true,
                  isDisclosed: json["disclosed"]?.boolValue ?? false)
    }
}

// MARK: - Levels / Curves

/// A point of a Nitro Levels/Curves channel.
public struct NitroCurvePoint: Sendable, Equatable {
    public var x: Double
    public var y: Double
    public var deletable: Bool
    public var inactive: Bool
    public var invisible: Bool
    public var isWhitePoint: Bool

    public init(x: Double, y: Double, deletable: Bool = false, inactive: Bool = false,
                invisible: Bool = false, isWhitePoint: Bool = false) {
        self.x = x
        self.y = y
        self.deletable = deletable
        self.inactive = inactive
        self.invisible = invisible
        self.isWhitePoint = isWhitePoint
    }

    var json: JSONValue {
        ["x": .number(x), "y": .number(y), "deletable": .bool(deletable), "inactive": .bool(inactive),
         "invisible": .bool(invisible), "isWhitePoint": .bool(isWhitePoint)]
    }

    init?(json: JSONValue) {
        guard let x = json["x"]?.doubleValue, let y = json["y"]?.doubleValue else { return nil }
        self.init(x: x, y: y,
                  deletable: json["deletable"]?.boolValue ?? false,
                  inactive: json["inactive"]?.boolValue ?? false,
                  invisible: json["invisible"]?.boolValue ?? false,
                  isWhitePoint: json["isWhitePoint"]?.boolValue ?? false)
    }
}

/// `levelsCurvesData`, shared by Nitro's Levels (`curves == false`) and Curves.
public struct LevelsCurvesData: Sendable, Equatable {
    /// Index of a channel in `channels`. 🟡 Order inferred from the manual (Combined, R, G, B).
    public enum Channel: Int, CaseIterable, Sendable {
        case master = 0, red, green, blue
    }

    public var curves: Bool
    /// `true`: the master channel works on luminance ("Grau"); `false`: equal RGB.
    public var operateOnGray: Bool
    public var gamma: Bool
    public var maxValue: Double
    public var histogramMaxValue: Double
    public var autoAlgorithm: Int
    /// Four point lists in `Channel` order.
    public var channels: [[NitroCurvePoint]]

    public init(curves: Bool, operateOnGray: Bool = true, gamma: Bool = true, maxValue: Double = 2,
                histogramMaxValue: Double = 1, autoAlgorithm: Int = 0,
                channels: [[NitroCurvePoint]]? = nil) {
        self.curves = curves
        self.operateOnGray = operateOnGray
        self.gamma = gamma
        self.maxValue = maxValue
        self.histogramMaxValue = histogramMaxValue
        self.autoAlgorithm = autoAlgorithm
        self.channels = channels ?? Array(
            repeating: Self.channel(maxValue: maxValue), count: Channel.allCases.count)
    }

    public subscript(channel: Channel) -> [NitroCurvePoint] {
        get { channels[channel.rawValue] }
        set { channels[channel.rawValue] = newValue }
    }

    /// Builds a channel with Nitro's fixed skeleton: invisible guard (0,0), black handle,
    /// `inner` user points (deletable), white handle, invisible guard (maxValue, maxValue).
    public static func channel(
        black: (x: Double, y: Double) = (0, 0),
        white: (x: Double, y: Double) = (1, 1),
        inner: [(x: Double, y: Double)] = [],
        maxValue: Double = 2
    ) -> [NitroCurvePoint] {
        [NitroCurvePoint(x: 0, y: 0, invisible: true),
         NitroCurvePoint(x: black.x, y: black.y)]
            + inner.map { NitroCurvePoint(x: $0.x, y: $0.y, deletable: true) }
            + [NitroCurvePoint(x: white.x, y: white.y, isWhitePoint: true),
               NitroCurvePoint(x: maxValue, y: maxValue, invisible: true)]
    }

    var json: JSONValue {
        ["curves": .bool(curves), "operateOnGray": .bool(operateOnGray), "gamma": .bool(gamma),
         "maxValue": .number(maxValue), "histogramMaxValue": .number(histogramMaxValue),
         "autoAlgorithm": .number(Double(autoAlgorithm)),
         "pointsArray": .array(channels.map { .array($0.map(\.json)) })]
    }

    init?(json: JSONValue) {
        guard let curves = json["curves"]?.boolValue,
              let pointsArray = json["pointsArray"]?.arrayValue,
              pointsArray.count == Channel.allCases.count
        else { return nil }
        var channels: [[NitroCurvePoint]] = []
        for channel in pointsArray {
            guard let points = channel.arrayValue?.map(NitroCurvePoint.init(json:)),
                  !points.contains(nil)
            else { return nil }
            channels.append(points.compactMap { $0 })
        }
        self.init(curves: curves,
                  operateOnGray: json["operateOnGray"]?.boolValue ?? true,
                  gamma: json["gamma"]?.boolValue ?? true,
                  maxValue: json["maxValue"]?.doubleValue ?? 2,
                  histogramMaxValue: json["histogramMaxValue"]?.doubleValue ?? 1,
                  autoAlgorithm: Int(exactly: json["autoAlgorithm"]?.doubleValue ?? 0) ?? 0,
                  channels: channels)
    }
}

// MARK: - Channel Mixer

/// Nitro's channel mixer: output rows with input weights and a `bias` (UI "Konstant").
public struct NitroChannelMixer: Sendable, Equatable {
    public struct Row: Sendable, Equatable {
        public var red: Double
        public var green: Double
        public var blue: Double
        public var bias: Double

        public init(red: Double, green: Double, blue: Double, bias: Double = 0) {
            self.red = red
            self.green = green
            self.blue = blue
            self.bias = bias
        }
    }

    public var red = Row(red: 1, green: 0, blue: 0)
    public var green = Row(red: 0, green: 1, blue: 0)
    public var blue = Row(red: 0, green: 0, blue: 1)

    public init() {}

    private static var outputs: [(name: String, row: WritableKeyPath<NitroChannelMixer, Row>)] {
        [("red", \.red), ("green", \.green), ("blue", \.blue)]
    }

    var numeric: [String: JSONValue] {
        var numeric: [String: JSONValue] = [:]
        for (name, keyPath) in Self.outputs {
            let row = self[keyPath: keyPath]
            numeric["\(name)_red"] = .number(row.red)
            numeric["\(name)_green"] = .number(row.green)
            numeric["\(name)_blue"] = .number(row.blue)
            numeric["\(name)_bias"] = .number(row.bias)
        }
        return numeric
    }

    init(numeric: [String: JSONValue]) {
        for (name, keyPath) in Self.outputs {
            let current = self[keyPath: keyPath]
            func value(_ input: String, _ fallback: Double) -> Double {
                numeric["\(name)_\(input)"]?.doubleValue ?? fallback
            }
            self[keyPath: keyPath] = Row(
                red: value("red", current.red), green: value("green", current.green),
                blue: value("blue", current.blue), bias: value("bias", current.bias))
        }
    }
}

// MARK: - HSL

/// The nine HSL colour swatches, in Nitro's UI order.
public enum NitroHSLColor: String, CaseIterable, Sendable {
    case red, orange, yellow, green, cyan, lightBlue, blue, purple, magenta
}

/// Nitro's per-colour HSL adjustment. All values are 0 when neutral.
public struct NitroHSL: Sendable, Equatable {
    public struct Values: Sendable, Equatable {
        /// Hue shift in degrees.
        public var hueDelta: Double
        public var saturationDelta: Double
        public var lumaDelta: Double
        public var range: Double

        public init(hueDelta: Double = 0, saturationDelta: Double = 0, lumaDelta: Double = 0, range: Double = 0) {
            self.hueDelta = hueDelta
            self.saturationDelta = saturationDelta
            self.lumaDelta = lumaDelta
            self.range = range
        }
    }

    public var values: [NitroHSLColor: Values] = [:]

    public init(values: [NitroHSLColor: Values] = [:]) {
        self.values = values
    }

    public subscript(color: NitroHSLColor) -> Values {
        get { values[color] ?? Values() }
        set { values[color] = newValue }
    }

    var numeric: [String: JSONValue] {
        var numeric: [String: JSONValue] = [:]
        for color in NitroHSLColor.allCases {
            let values = self[color]
            numeric["hueDelta_\(color.rawValue)"] = .number(values.hueDelta)
            numeric["saturationDelta_\(color.rawValue)"] = .number(values.saturationDelta)
            numeric["lumaDelta_\(color.rawValue)"] = .number(values.lumaDelta)
            numeric["range_\(color.rawValue)"] = .number(values.range)
        }
        return numeric
    }

    init(numeric: [String: JSONValue]) {
        for color in NitroHSLColor.allCases {
            func value(_ parameter: String) -> Double {
                numeric["\(parameter)_\(color.rawValue)"]?.doubleValue ?? 0
            }
            self[color] = Values(hueDelta: value("hueDelta"), saturationDelta: value("saturationDelta"),
                                 lumaDelta: value("lumaDelta"), range: value("range"))
        }
    }
}
