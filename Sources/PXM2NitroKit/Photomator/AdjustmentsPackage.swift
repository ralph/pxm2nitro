import Foundation

public enum PhotomatorError: LocalizedError, Equatable, CustomStringConvertible {
    case notAPackage(URL)
    case malformedAdjustmentData

    public var description: String {
        switch self {
        case .notAPackage(let url): "\(url.path) is not a Photomator .adjustments package"
        case .malformedAdjustmentData: "ColorAdjustmentData is not a versioned JSON container"
        }
    }

    public var errorDescription: String? { description }
}

/// One preset from a Photomator / Pixelmator Pro adjustments package.
public struct PhotomatorPreset: Sendable, Equatable {
    public let id: String
    public let name: String
    /// Short name of the collection (group) the preset belongs to, if any.
    public let collectionName: String?
    /// Decoded `ColorAdjustmentData`, or `nil` if the preset has none.
    public let adjustments: PhotomatorAdjustments?
    /// Keys of preset properties other than `ColorAdjustmentData` (not converted).
    public let otherPropertyKeys: [String]

    /// "Collection / Name", or just the name.
    public var title: String { title(separator: " / ") }

    /// Collection and preset name joined by `separator`, or just the name.
    public func title(separator: String) -> String {
        [collectionName, name].compactMap { $0 }.joined(separator: separator)
    }
}

/// A preset file that could not be read; the rest of the package still loads.
public struct PresetLoadFailure: Sendable {
    public let file: URL
    public let collectionName: String?
    public let reason: String
}

/// The readable presets of a package plus the files that failed.
public struct LoadedPackage: Sendable {
    public let presets: [PhotomatorPreset]
    public let failures: [PresetLoadFailure]
}

/// Reads a `.adjustments` package (or the `Adjustments.library` inside Photomator.app):
///
///     Adjustments-LibraryInfo.plist   collections-list
///     collections/<UUID>.plist        name, presets-list
///     presets/<UUID>.plist            id, name, properties[{key, value}]
public enum AdjustmentsPackage {
    static let colorAdjustmentDataKey = "ColorAdjustmentData"

    /// Loads all presets, in collection order and then in each collection's display order.
    /// Presets not referenced by any collection follow, sorted by file name.
    /// Throws only if `url` is not a package; unreadable presets end up in `failures`.
    public static func load(from url: URL) throws -> LoadedPackage {
        let presetsDirectory = url.appending(path: "presets", directoryHint: .isDirectory)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: presetsDirectory.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw PhotomatorError.notAPackage(url)
        }

        var remaining = try plistFilesByID(in: presetsDirectory)
        var order: [(file: URL, collection: String?)] = []
        for collection in try collections(in: url) {
            for id in collection.presetsList {
                if let file = remaining.removeValue(forKey: id) {
                    order.append((file, collection.name))
                }
            }
        }
        order += remaining.sorted { $0.key < $1.key }.map { ($0.value, nil) }

        var presets: [PhotomatorPreset] = []
        var failures: [PresetLoadFailure] = []
        for (file, collection) in order {
            do {
                presets.append(try loadPreset(from: file, collectionName: collection))
            } catch {
                failures.append(PresetLoadFailure(file: file, collectionName: collection, reason: "\(error)"))
            }
        }
        return LoadedPackage(presets: presets, failures: failures)
    }

    /// Loads a single `presets/<UUID>.plist` file.
    public static func loadPreset(from url: URL, collectionName: String? = nil) throws -> PhotomatorPreset {
        let plist = try PropertyListDecoder().decode(PresetPlist.self, from: Data(contentsOf: url))
        var adjustments: PhotomatorAdjustments?
        if let property = plist.properties.first(where: { $0.key == colorAdjustmentDataKey }) {
            guard let data = property.data else { throw PhotomatorError.malformedAdjustmentData }
            adjustments = try PhotomatorAdjustments(data: data)
        }
        return PhotomatorPreset(
            id: plist.id, name: plist.name, collectionName: collectionName,
            adjustments: adjustments,
            otherPropertyKeys: plist.properties.map(\.key).filter { $0 != colorAdjustmentDataKey })
    }

    /// Collections in library order, followed by collections the library info does not list
    /// (in file-name order). Unreadable library info or collection files are skipped, so their
    /// presets load without a collection.
    static func collections(in url: URL) throws -> [CollectionPlist] {
        let directory = url.appending(path: "collections", directoryHint: .isDirectory)
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        let files = try plistFilesByID(in: directory)
        let decoder = PropertyListDecoder()

        let listed = (try? Data(contentsOf: url.appending(path: "Adjustments-LibraryInfo.plist")))
            .flatMap { try? decoder.decode(LibraryInfoPlist.self, from: $0).collectionsList } ?? []
        let listedSet = Set(listed)
        let ids = listed + files.keys.filter { !listedSet.contains($0) }.sorted()
        return ids.compactMap { files[$0] }.compactMap {
            try? decoder.decode(CollectionPlist.self, from: Data(contentsOf: $0))
        }
    }

    /// `*.plist` files in a directory, keyed by file name without extension (the UUID).
    static func plistFilesByID(in directory: URL) throws -> [String: URL] {
        let files = try FileManager.default
            .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "plist" }
        return Dictionary(uniqueKeysWithValues: files.map { ($0.deletingPathExtension().lastPathComponent, $0) })
    }
}

// MARK: - Plist shapes

struct LibraryInfoPlist: Decodable {
    let collectionsList: [String]
    enum CodingKeys: String, CodingKey { case collectionsList = "collections-list" }
}

struct CollectionPlist: Decodable {
    let name: String
    let presetsList: [String]
    enum CodingKeys: String, CodingKey {
        case name
        case presetsList = "presets-list"
    }
}

struct PresetPlist: Decodable {
    struct Property: Decodable {
        let key: String
        /// The value when it is binary data; other value types are not needed.
        let data: Data?

        enum CodingKeys: String, CodingKey { case key, value }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            key = try container.decode(String.self, forKey: .key)
            data = try? container.decode(Data.self, forKey: .value)
        }
    }

    let id: String
    let name: String
    let properties: [Property]
}
