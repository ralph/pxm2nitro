/// One entry of a Nitro edit version's `adjDataArr`. See `docs/nitro-format.md` §3.
///
/// Adjustments the converter writes are modelled explicitly; everything else is kept as
/// raw JSON (`.other`) so it survives reading and re-writing.
public struct NitroAdjustment: Sendable, Equatable {
    public enum Content: Sendable, Equatable {
        /// Curves or Levels, depending on `NitroLevelsCurves.isCurves`.
        case levelsCurves(NitroLevelsCurves)
        case channelMixer(NitroChannelMixer)
        case hsl(NitroHSL)
        /// An adjustment not modelled here; `json` is its complete inner object.
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
        case .levelsCurves(let data): data.isCurves ? "Curves" : "Levels"
        case .channelMixer: "ChannelMixer"
        case .hsl: "HSL"
        case .other(let id, _): id
        }
    }

    /// The inner object that Nitro stores, string-encoded, in `adjDataArr[].json`.
    public var json: JSONValue {
        var object: [String: JSONValue]
        switch content {
        case .levelsCurves(let data):
            object = ["levelsCurvesData": data.json]
            if data.isCurves {
                // Only Curves repeats its identity inside the object (`localizedName` is
                // Nitro's UI language; "Curves" is fine for applying the preset).
                object.merge(["id": "Curves", "name": "Curves", "localizedName": "Curves", "numeric": [:]]) { $1 }
            }
        case .channelMixer(let mixer):
            object = ["numeric": .object(mixer.numeric)]
        case .hsl(let hsl):
            object = ["version": 1, "numeric": .object(hsl.numeric)]
        case .other(_, let json):
            object = json.objectValue ?? [:]
        }
        object["enabled"] = .bool(isEnabled)
        object["disclosed"] = .bool(isDisclosed)
        return .object(object)
    }

    /// Parses an `adjDataArr` entry; unknown or unexpected shapes become `.other`.
    public init(id: String, json: JSONValue) {
        let content: Content? = switch id {
        case "Curves", "Levels":
            json["levelsCurvesData"].flatMap(NitroLevelsCurves.init(json:))
                .flatMap { $0.isCurves == (id == "Curves") ? .levelsCurves($0) : nil }
        case "ChannelMixer": json["numeric"]?.objectValue.map { .channelMixer(NitroChannelMixer(numeric: $0)) }
        case "HSL" where (json["version"]?.intValue ?? 1) == 1:
            json["numeric"]?.objectValue.map { .hsl(NitroHSL(numeric: $0)) }
        default: nil
        }
        self.init(content ?? .other(id: id, json: json),
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

/// `levelsCurvesData`, shared by Nitro's Levels (`isCurves == false`) and Curves.
public struct NitroLevelsCurves: Sendable, Equatable {
    public var isCurves: Bool
    /// `true`: the master channel works on luminance ("Grau"); `false`: equal RGB.
    public var operateOnGray: Bool
    public var gamma: Bool
    /// Upper end of the curve range; the last (invisible) guard point sits at (maxValue, maxValue).
    public var maxValue: Double
    public var histogramMaxValue: Double
    public var autoAlgorithm: Int
    /// Channels in `pointsArray` order. 🟡 The order is inferred from the manual (Combined, R, G, B).
    public var master: [NitroCurvePoint]
    public var red: [NitroCurvePoint]
    public var green: [NitroCurvePoint]
    public var blue: [NitroCurvePoint]

    /// An identity Curves or Levels adjustment.
    public init(isCurves: Bool, operateOnGray: Bool = true, gamma: Bool = true, maxValue: Double = 2,
                histogramMaxValue: Double = 1, autoAlgorithm: Int = 0) {
        self.isCurves = isCurves
        self.operateOnGray = operateOnGray
        self.gamma = gamma
        self.maxValue = maxValue
        self.histogramMaxValue = histogramMaxValue
        self.autoAlgorithm = autoAlgorithm
        master = []
        red = []
        green = []
        blue = []
        let identity = channel()
        (master, red, green, blue) = (identity, identity, identity, identity)
    }

    /// Builds a channel with Nitro's fixed skeleton: invisible guard (0,0), black handle,
    /// `inner` user points (deletable), white handle, invisible guard (maxValue, maxValue).
    public func channel(
        black: CurvePoint = CurvePoint(x: 0, y: 0),
        white: CurvePoint = CurvePoint(x: 1, y: 1),
        inner: [CurvePoint] = []
    ) -> [NitroCurvePoint] {
        [NitroCurvePoint(x: 0, y: 0, invisible: true),
         NitroCurvePoint(x: black.x, y: black.y)]
            + inner.map { NitroCurvePoint(x: $0.x, y: $0.y, deletable: true) }
            + [NitroCurvePoint(x: white.x, y: white.y, isWhitePoint: true),
               NitroCurvePoint(x: maxValue, y: maxValue, invisible: true)]
    }

    var json: JSONValue {
        ["curves": .bool(isCurves), "operateOnGray": .bool(operateOnGray), "gamma": .bool(gamma),
         "maxValue": .number(maxValue), "histogramMaxValue": .number(histogramMaxValue),
         "autoAlgorithm": .number(Double(autoAlgorithm)),
         "pointsArray": .array([master, red, green, blue].map { .array($0.map(\.json)) })]
    }

    init?(json: JSONValue) {
        guard let isCurves = json["curves"]?.boolValue,
              let pointsArray = json["pointsArray"]?.arrayValue, pointsArray.count == 4
        else { return nil }
        var channels: [[NitroCurvePoint]] = []
        for channel in pointsArray {
            guard let raw = channel.arrayValue else { return nil }
            let points = raw.compactMap(NitroCurvePoint.init(json:))
            guard points.count == raw.count else { return nil }
            channels.append(points)
        }
        self.init(isCurves: isCurves,
                  operateOnGray: json["operateOnGray"]?.boolValue ?? true,
                  gamma: json["gamma"]?.boolValue ?? true,
                  maxValue: json["maxValue"]?.doubleValue ?? 2,
                  histogramMaxValue: json["histogramMaxValue"]?.doubleValue ?? 1,
                  autoAlgorithm: json["autoAlgorithm"]?.intValue ?? 0)
        (master, red, green, blue) = (channels[0], channels[1], channels[2], channels[3])
    }
}

// MARK: - Channel Mixer

/// Nitro's channel mixer: output rows with input weights and a `bias` (UI "Konstant").
/// Numeric keys are `<output>_<input>` and `<output>_bias`.
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

        fileprivate func numeric(output: String) -> [String: JSONValue] {
            ["\(output)_red": .number(red), "\(output)_green": .number(green),
             "\(output)_blue": .number(blue), "\(output)_bias": .number(bias)]
        }

        fileprivate init(numeric: [String: JSONValue], output: String, default row: Row) {
            func value(_ input: String) -> Double? { numeric["\(output)_\(input)"]?.doubleValue }
            self.init(red: value("red") ?? row.red, green: value("green") ?? row.green,
                      blue: value("blue") ?? row.blue, bias: value("bias") ?? row.bias)
        }
    }

    public var red = Row(red: 1, green: 0, blue: 0)
    public var green = Row(red: 0, green: 1, blue: 0)
    public var blue = Row(red: 0, green: 0, blue: 1)

    /// The identity mixer.
    public init() {}

    var numeric: [String: JSONValue] {
        red.numeric(output: "red")
            .merging(green.numeric(output: "green")) { $1 }
            .merging(blue.numeric(output: "blue")) { $1 }
    }

    init(numeric: [String: JSONValue]) {
        red = Row(numeric: numeric, output: "red", default: red)
        green = Row(numeric: numeric, output: "green", default: green)
        blue = Row(numeric: numeric, output: "blue", default: blue)
    }
}

// MARK: - HSL

/// The nine HSL colour swatches, in Nitro's UI order.
public enum NitroHSLColor: String, CaseIterable, Sendable {
    case red, orange, yellow, green, cyan, lightBlue, blue, purple, magenta
}

/// Nitro's per-colour HSL adjustment. Numeric keys are `<parameter>_<colour>`; 0 is neutral.
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

        /// The field-wise mean of two swatches.
        public static func average(_ a: Values, _ b: Values) -> Values {
            Values(hueDelta: (a.hueDelta + b.hueDelta) / 2,
                   saturationDelta: (a.saturationDelta + b.saturationDelta) / 2,
                   lumaDelta: (a.lumaDelta + b.lumaDelta) / 2,
                   range: (a.range + b.range) / 2)
        }
    }

    public var values: [NitroHSLColor: Values]

    public init(values: [NitroHSLColor: Values] = [:]) {
        self.values = values
    }

    /// Compares the effective values: a missing colour equals an explicit neutral one.
    public static func == (lhs: NitroHSL, rhs: NitroHSL) -> Bool {
        NitroHSLColor.allCases.allSatisfy { lhs[$0] == rhs[$0] }
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
        values = [:]
        for color in NitroHSLColor.allCases {
            func value(_ parameter: String) -> Double {
                numeric["\(parameter)_\(color.rawValue)"]?.doubleValue ?? 0
            }
            self[color] = Values(hueDelta: value("hueDelta"), saturationDelta: value("saturationDelta"),
                                 lumaDelta: value("lumaDelta"), range: value("range"))
        }
    }
}
