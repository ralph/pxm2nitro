import Foundation

/// The colour adjustment blocks of a Photomator preset (`ColorAdjustmentData`).
/// See `docs/photomator-format.md` §3 for the key dictionary.
public enum PhotomatorBlock: String, CaseIterable, Sendable {
    case light = "l"
    case fade = "f"
    case whiteBalance = "w"
    case hueSaturation = "hS"
    case levels = "L"
    case curves = "C"
    case sharpen = "S"
    case selectiveClarity = "cl"
    case colorBalance = "B"
    case selectiveColor = "ca"
    case replaceColor = "r"
    case removeColor = "R"
    case channelMixer = "m"
    case colorMonochrome = "M"
    case blackAndWhite = "b"
    case sepia = "s"
    case invert = "i"
    case vignette = "v"
    case grain = "g"
    case lut = "cL"

    /// Name of the adjustment as shown in Photomator.
    public var displayName: String {
        switch self {
        case .light: "Light"
        case .fade: "Fade"
        case .whiteBalance: "White Balance"
        case .hueSaturation: "Color"
        case .levels: "Levels"
        case .curves: "Curves"
        case .sharpen: "Sharpen"
        case .selectiveClarity: "Selective Clarity"
        case .colorBalance: "Color Balance"
        case .selectiveColor: "Selective Color"
        case .replaceColor: "Replace Color"
        case .removeColor: "Remove Color"
        case .channelMixer: "Channel Mixer"
        case .colorMonochrome: "Color Monochrome"
        case .blackAndWhite: "Black & White"
        case .sepia: "Sepia"
        case .invert: "Invert"
        case .vignette: "Vignette"
        case .grain: "Grain"
        case .lut: "LUT"
        }
    }
}

/// Decoded `ColorAdjustmentData` with all version containers removed.
public struct PhotomatorAdjustments: Sendable, Equatable {
    /// Version of the root container (2 or 3 in known presets).
    public let formatVersion: Int
    /// Root object after unwrapping; block payloads are keyed by `PhotomatorBlock.rawValue`.
    public let root: [String: JSONValue]

    public init(formatVersion: Int, root: [String: JSONValue]) {
        self.formatVersion = formatVersion
        self.root = root
    }

    /// Decodes the raw `ColorAdjustmentData` bytes: `[version, {…}]` JSON.
    public init(data: Data) throws {
        guard case .array(let items) = try JSONValue(data: data),
              items.count == 2, let version = items[0].intValue,
              let root = items[1].unwrappingVersionContainers().objectValue
        else {
            throw PhotomatorError.malformedAdjustmentData
        }
        self.init(formatVersion: version, root: root)
    }

    /// Preset intensity (`in`), 0…1. Defaults to 1.
    public var intensity: Double { root["in"]?.doubleValue ?? 1 }

    /// The payload of a block, or `nil` if the block is absent or disabled (`E` flag).
    public func enabledBlock(_ block: PhotomatorBlock) -> [String: JSONValue]? {
        guard let payload = root[block.rawValue]?.objectValue,
              payload["E"]?.isTruthy == true
        else { return nil }
        return payload
    }

    /// All enabled blocks in `PhotomatorBlock` order.
    public var enabledBlocks: [PhotomatorBlock] {
        PhotomatorBlock.allCases.filter { enabledBlock($0) != nil }
    }
}

// MARK: - Typed blocks

/// Per-channel values of Curves and Levels. A `nil` channel was not edited (identity).
public struct ColorChannels<Value: Sendable & Equatable>: Sendable, Equatable {
    public var rgb: Value?
    public var red: Value?
    public var green: Value?
    public var blue: Value?
    public var luminance: Value?

    public init(rgb: Value? = nil, red: Value? = nil, green: Value? = nil,
                blue: Value? = nil, luminance: Value? = nil) {
        self.rgb = rgb
        self.red = red
        self.green = green
        self.blue = blue
        self.luminance = luminance
    }

    init(_ block: [String: JSONValue], parse: (JSONValue) -> Value?) {
        func value(_ key: String) -> Value? { block[key].flatMap(parse) }
        self.init(rgb: value("rgb"), red: value("r"), green: value("g"),
                  blue: value("b"), luminance: value("l"))
    }
}

public struct CurvePoint: Sendable, Equatable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// Curves (`C`): control points in 0…1, sorted by x, per channel.
public typealias PhotomatorCurves = ColorChannels<[CurvePoint]>

public extension ColorChannels where Value == [CurvePoint] {
    static var identityCurve: [CurvePoint] { [CurvePoint(x: 0, y: 0), CurvePoint(x: 1, y: 1)] }
}

/// The five input handles of one Levels channel.
public struct LevelsHandles: Sendable, Equatable {
    static let keys = ["black", "midOfBlackAndGray", "gray", "midOfGrayAndWhite", "white"]
    public var black: Double
    public var midOfBlackAndGray: Double
    public var gray: Double
    public var midOfGrayAndWhite: Double
    public var white: Double
}

/// Levels (`L`).
public typealias PhotomatorLevels = ColorChannels<LevelsHandles>

/// One output channel of the channel mixer.
public struct ChannelMixerRow: Sendable, Equatable {
    static let keys = ["red", "green", "blue", "constant"]
    public var red: Double
    public var green: Double
    public var blue: Double
    public var constant: Double
}

/// Channel Mixer (`m`): output rows `red`, `green`, `blue`; absent rows were not edited.
public typealias PhotomatorChannelMixer = ColorChannels<ChannelMixerRow>

/// One of the eight Selective Color ranges.
public struct SelectiveColorRange: Sendable, Equatable {
    public var hue: Double
    public var saturation: Double
    public var brightness: Double
}

/// Light (`l`), stored as UI percent / 100.
public struct PhotomatorLight: Sendable, Equatable {
    static let keys = ["e", "h", "s", "b", "c", "B", "C", "T"]
    public var exposure: Double
    public var highlights: Double
    public var shadows: Double
    public var brightness: Double
    public var contrast: Double
    public var blackPoint: Double
    public var clarity: Double
    public var texture: Double
}

/// Color (`hS`): global hue, saturation and vibrance, stored as UI percent / 100.
public struct PhotomatorColor: Sendable, Equatable {
    static let keys = ["h", "s", "v"]
    public var hue: Double
    public var saturation: Double
    public var vibrancy: Double
}

extension PhotomatorAdjustments {
    public var curves: PhotomatorCurves? {
        enabledBlock(.curves).map {
            ColorChannels($0) { channel in
                channel["p"]?.arrayValue?.compactMap { pair in
                    guard let xy = pair.arrayValue, xy.count == 2,
                          let x = xy[0].doubleValue, let y = xy[1].doubleValue
                    else { return nil }
                    return CurvePoint(x: x, y: y)
                }.sorted { $0.x < $1.x }
            }
        }
    }

    public var levels: PhotomatorLevels? {
        enabledBlock(.levels).map {
            ColorChannels($0) { channel in
                guard channel.isObject(withNumericFields: LevelsHandles.keys) else { return nil }
                return LevelsHandles(
                    black: channel["black"]?.doubleValue ?? 0,
                    midOfBlackAndGray: channel["midOfBlackAndGray"]?.doubleValue ?? 0.25,
                    gray: channel["gray"]?.doubleValue ?? 0.5,
                    midOfGrayAndWhite: channel["midOfGrayAndWhite"]?.doubleValue ?? 0.75,
                    white: channel["white"]?.doubleValue ?? 1)
            }
        }
    }

    public var channelMixer: PhotomatorChannelMixer? {
        enabledBlock(.channelMixer).map {
            ColorChannels($0) { row in
                guard row.isObject(withNumericFields: ChannelMixerRow.keys) else { return nil }
                return ChannelMixerRow(
                    red: row["red"]?.doubleValue ?? 0,
                    green: row["green"]?.doubleValue ?? 0,
                    blue: row["blue"]?.doubleValue ?? 0,
                    constant: row["constant"]?.doubleValue ?? 0)
            }
        }
    }

    /// Light (`l`); `nil` if the block is disabled or one of its values is not a number.
    public var light: PhotomatorLight? {
        enabledBlock(.light).flatMap { payload in
            guard JSONValue.object(payload).isObject(withNumericFields: PhotomatorLight.keys) else { return nil }
            func value(_ key: String) -> Double { payload[key]?.doubleValue ?? 0 }
            return PhotomatorLight(exposure: value("e"), highlights: value("h"), shadows: value("s"),
                                   brightness: value("b"), contrast: value("c"), blackPoint: value("B"),
                                   clarity: value("C"), texture: value("T"))
        }
    }

    /// Color (`hS`); `nil` if the block is disabled or one of its values is not a number.
    public var color: PhotomatorColor? {
        enabledBlock(.hueSaturation).flatMap { payload in
            guard JSONValue.object(payload).isObject(withNumericFields: PhotomatorColor.keys) else { return nil }
            return PhotomatorColor(hue: payload["h"]?.doubleValue ?? 0,
                                   saturation: payload["s"]?.doubleValue ?? 0,
                                   vibrancy: payload["v"]?.doubleValue ?? 0)
        }
    }

    /// Selective Color (`ca`): eight ranges in UI order
    /// red, orange, yellow, green, cyan, blue, violet, magenta.
    public var selectiveColor: [SelectiveColorRange]? {
        enabledBlock(.selectiveColor)?["a"]?.arrayValue?.map { entry in
            SelectiveColorRange(
                hue: entry["hue"]?.doubleValue ?? 0,
                saturation: entry["saturation"]?.doubleValue ?? 0,
                brightness: entry["brightness"]?.doubleValue ?? 0)
        }
    }
}
