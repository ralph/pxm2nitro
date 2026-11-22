import Foundation

public enum NitroError: Error, Equatable, CustomStringConvertible {
    case malformedPreset(String)

    public var description: String {
        switch self {
        case .malformedPreset(let reason): "Not a valid .nitropreset: \(reason)"
        }
    }
}

/// A Nitro preset (`.nitropreset`): JSON with one edit version whose `adjDataArr` holds
/// each adjustment as a *string-encoded* JSON object. See `docs/nitro-format.md` §1.
///
/// Write-oriented: reading keeps the name, decoder version and the adjustments of the current
/// edit version. Masks, other versions and the remaining edit-model fields are not preserved;
/// `encoded()` writes Nitro's constants for them.
public struct NitroPreset: Sendable, Equatable {
    public static let fileExtension = "nitropreset"
    /// RAW decoder version Nitro writes for its current ("v9") decoder.
    public static let currentDecoderVersion = "9.dng"

    public var name: String
    public var decoderVersion: String
    public var adjustments: [NitroAdjustment]

    public init(name: String, adjustments: [NitroAdjustment],
                decoderVersion: String = NitroPreset.currentDecoderVersion) {
        self.name = name
        self.adjustments = adjustments
        self.decoderVersion = decoderVersion
    }

    /// Parses a `.nitropreset` file. Uses the current edit version (`currentVersionIndex`).
    public init(data: Data) throws {
        let root = try JSONValue(data: data)
        guard let name = root["name"]?.stringValue,
              let editModel = root["editModel"],
              let versions = editModel["versions"]?.arrayValue
        else { throw NitroError.malformedPreset("missing name or editModel.versions") }
        let index = editModel["currentVersionIndex"]?.intValue ?? 0
        guard versions.indices.contains(index), let entries = versions[index]["adjDataArr"]?.arrayValue else {
            throw NitroError.malformedPreset("missing adjDataArr")
        }
        let adjustments = try entries.map { entry in
            guard let id = entry["id"]?.stringValue, let json = entry["json"]?.stringValue else {
                throw NitroError.malformedPreset("adjDataArr entry without id/json")
            }
            return NitroAdjustment(id: id, json: try JSONValue(data: Data(json.utf8)))
        }
        self.init(name: name, adjustments: adjustments,
                  decoderVersion: versions[index]["decoderVersionString"]?.stringValue ?? Self.currentDecoderVersion)
    }

    /// The complete file contents.
    public func encoded() throws -> Data {
        let entries: [JSONValue] = try adjustments.map { adjustment in
            let json = String(decoding: try adjustment.json.encoded(), as: UTF8.self)
            return ["id": .string(adjustment.id), "json": .string(json)]
        }
        let root: JSONValue = [
            "name": .string(name),
            "version": 1,
            "editModel": [
                "formatVersion": 1,
                "currentVersionIndex": 0,
                "defaultOrientation": 1,
                "lowResMask": false,
                "editingJPEGHalf": false,
                "versions": [[
                    "decoderVersionString": .string(decoderVersion),
                    "masks": [],
                    "adjDataArr": .array(entries),
                ]],
            ],
        ]
        return try root.encoded()
    }
}
