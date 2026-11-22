import Foundation

public enum PhotomatorError: Error, Equatable, CustomStringConvertible {
    case notAPackage(URL)
    case malformedAdjustmentData

    public var description: String {
        switch self {
        case .notAPackage(let url): "\(url.path) is not a Photomator .adjustments package"
        case .malformedAdjustmentData: "ColorAdjustmentData is not a versioned JSON container"
        }
    }
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
}

/// Reads a `.adjustments` package (or the `Adjustments.library` inside Photomator.app):
///
///     Adjustments-LibraryInfo.plist   collections-list
///     collections/<UUID>.plist        name, presets-list
///     presets/<UUID>.plist            id, name, properties[{key, value}]
public enum AdjustmentsPackage {
    static let colorAdjustmentDataKey = "ColorAdjustmentData"

    /// Loads all presets, in collection order and then in each collection's display order.
    /// Presets not referenced by any collection follow, sorted by name.
    public static func load(from url: URL) throws -> [PhotomatorPreset] {
        let presetsDirectory = url.appending(path: "presets", directoryHint: .isDirectory)
        guard FileManager.default.fileExists(atPath: presetsDirectory.path) else {
            throw PhotomatorError.notAPackage(url)
        }

        var listed: [(id: String, collection: String)] = []
        for collection in try collections(in: url) {
            listed += collection.presetsList.map { ($0, collection.name) }
        }

        let presetFiles = try FileManager.default
            .contentsOfDirectory(at: presetsDirectory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "plist" }
        let filesByID = Dictionary(
            presetFiles.map { ($0.deletingPathExtension().lastPathComponent, $0) },
            uniquingKeysWith: { first, _ in first })

        var presets: [PhotomatorPreset] = []
        var seen = Set<String>()
        for entry in listed {
            guard let file = filesByID[entry.id], seen.insert(entry.id).inserted else { continue }
            presets.append(try loadPreset(from: file, collectionName: entry.collection))
        }
        let orphans = try filesByID
            .filter { !seen.contains($0.key) }
            .map { try loadPreset(from: $0.value, collectionName: nil) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return presets + orphans
    }

    static func loadPreset(from url: URL, collectionName: String?) throws -> PhotomatorPreset {
        let plist = try PropertyListDecoder().decode(PresetPlist.self, from: Data(contentsOf: url))
        var adjustments: PhotomatorAdjustments?
        var otherKeys: [String] = []
        for property in plist.properties {
            if property.key == colorAdjustmentDataKey, let data = property.data {
                adjustments = try PhotomatorAdjustments(data: data)
            } else {
                otherKeys.append(property.key)
            }
        }
        return PhotomatorPreset(
            id: plist.id, name: plist.name, collectionName: collectionName,
            adjustments: adjustments, otherPropertyKeys: otherKeys)
    }

    /// Collections in library order; falls back to directory order if the library info is missing.
    static func collections(in url: URL) throws -> [CollectionPlist] {
        let directory = url.appending(path: "collections", directoryHint: .isDirectory)
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        let decoder = PropertyListDecoder()

        let infoURL = url.appending(path: "Adjustments-LibraryInfo.plist")
        let ids: [String]
        if let data = try? Data(contentsOf: infoURL) {
            ids = try decoder.decode(LibraryInfoPlist.self, from: data).collectionsList
        } else {
            ids = try FileManager.default.contentsOfDirectory(atPath: directory.path)
                .filter { $0.hasSuffix(".plist") }
                .map { String($0.dropLast(".plist".count)) }
                .sorted()
        }
        return try ids.compactMap { id in
            let file = directory.appending(path: "\(id).plist")
            guard let data = try? Data(contentsOf: file) else { return nil }
            return try decoder.decode(CollectionPlist.self, from: data)
        }
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
