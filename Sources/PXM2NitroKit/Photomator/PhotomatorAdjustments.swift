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
}

/// Decoded `ColorAdjustmentData` with all version containers removed.
public struct PhotomatorAdjustments: Sendable, Equatable {
    /// Version of the root container (2 or 3 in known presets).
    public let formatVersion: Int
    /// Root object after unwrapping; block payloads are keyed by `PhotomatorBlock.rawValue`.
    public let root: [String: JSONValue]

    public init(data: Data) throws {
        let raw = try JSONDecoder().decode(JSONValue.self, from: data)
        guard case .array(let items) = raw, items.count == 2,
              let version = items[0].doubleValue,
              case .object(let root) = raw.unwrappingVersionContainers()
        else {
            throw PhotomatorError.malformedAdjustmentData
        }
        self.formatVersion = Int(version)
        self.root = root
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

public struct CurvePoint: Sendable, Equatable {
    public var x: Double
    public var y: Double
}

/// Curves (`C`). Each channel is a list of control points in 0…1, sorted by x.
public struct PhotomatorCurves: Sendable, Equatable {
    public var rgb: [CurvePoint]
    public var red: [CurvePoint]
    public var green: [CurvePoint]
    public var blue: [CurvePoint]
    public var luminance: [CurvePoint]

    public static let identity = [CurvePoint(x: 0, y: 0), CurvePoint(x: 1, y: 1)]
}

/// The five input handles of one Levels channel.
public struct LevelsHandles: Sendable, Equatable {
    public var black: Double
    public var midOfBlackAndGray: Double
    public var gray: Double
    public var midOfGrayAndWhite: Double
    public var white: Double

    public static let identity = LevelsHandles(
        black: 0, midOfBlackAndGray: 0.25, gray: 0.5, midOfGrayAndWhite: 0.75, white: 1)
}

/// Levels (`L`). Channels that were never edited are absent and mean identity.
public struct PhotomatorLevels: Sendable, Equatable {
    public var rgb: LevelsHandles?
    public var red: LevelsHandles?
    public var green: LevelsHandles?
    public var blue: LevelsHandles?
    public var luminance: LevelsHandles?
}

/// One output channel of the channel mixer.
public struct ChannelMixerRow: Sendable, Equatable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var constant: Double
}

/// Channel Mixer (`m`). Absent rows are not stored by Photomator.
public struct PhotomatorChannelMixer: Sendable, Equatable {
    public var red: ChannelMixerRow?
    public var green: ChannelMixerRow?
    public var blue: ChannelMixerRow?
}

/// One of the eight Selective Color ranges.
public struct SelectiveColorRange: Sendable, Equatable {
    public var hue: Double
    public var saturation: Double
    public var brightness: Double
}

/// Selective Color (`ca`): eight ranges in UI order
/// red, orange, yellow, green, cyan, blue, violet, magenta.
public struct PhotomatorSelectiveColor: Sendable, Equatable {
    public var ranges: [SelectiveColorRange]
}

extension PhotomatorAdjustments {
    public var curves: PhotomatorCurves? {
        guard let block = enabledBlock(.curves) else { return nil }
        func channel(_ key: String) -> [CurvePoint] {
            let points = block[key]?["p"]?.arrayValue?.compactMap { pair -> CurvePoint? in
                guard let xy = pair.arrayValue, xy.count == 2,
                      let x = xy[0].doubleValue, let y = xy[1].doubleValue
                else { return nil }
                return CurvePoint(x: x, y: y)
            }
            return points ?? PhotomatorCurves.identity
        }
        return PhotomatorCurves(
            rgb: channel("rgb"), red: channel("r"), green: channel("g"),
            blue: channel("b"), luminance: channel("l"))
    }

    public var levels: PhotomatorLevels? {
        guard let block = enabledBlock(.levels) else { return nil }
        func channel(_ key: String) -> LevelsHandles? {
            guard let handles = block[key]?.objectValue,
                  let black = handles["black"]?.doubleValue,
                  let white = handles["white"]?.doubleValue
            else { return nil }
            let identity = LevelsHandles.identity
            return LevelsHandles(
                black: black,
                midOfBlackAndGray: handles["midOfBlackAndGray"]?.doubleValue ?? identity.midOfBlackAndGray,
                gray: handles["gray"]?.doubleValue ?? identity.gray,
                midOfGrayAndWhite: handles["midOfGrayAndWhite"]?.doubleValue ?? identity.midOfGrayAndWhite,
                white: white)
        }
        return PhotomatorLevels(
            rgb: channel("rgb"), red: channel("r"), green: channel("g"),
            blue: channel("b"), luminance: channel("l"))
    }

    public var channelMixer: PhotomatorChannelMixer? {
        guard let block = enabledBlock(.channelMixer) else { return nil }
        func row(_ key: String) -> ChannelMixerRow? {
            guard let row = block[key]?.objectValue else { return nil }
            return ChannelMixerRow(
                red: row["red"]?.doubleValue ?? 0,
                green: row["green"]?.doubleValue ?? 0,
                blue: row["blue"]?.doubleValue ?? 0,
                constant: row["constant"]?.doubleValue ?? 0)
        }
        return PhotomatorChannelMixer(red: row("r"), green: row("g"), blue: row("b"))
    }

    public var selectiveColor: PhotomatorSelectiveColor? {
        guard let entries = enabledBlock(.selectiveColor)?["a"]?.arrayValue else { return nil }
        return PhotomatorSelectiveColor(ranges: entries.map { entry in
            SelectiveColorRange(
                hue: entry["hue"]?.doubleValue ?? 0,
                saturation: entry["saturation"]?.doubleValue ?? 0,
                brightness: entry["brightness"]?.doubleValue ?? 0)
        })
    }
}
