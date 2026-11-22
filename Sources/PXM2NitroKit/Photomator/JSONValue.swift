/// A decoded JSON value. Used for Photomator's `ColorAdjustmentData`, whose terse,
/// versioned structure is easier to walk generically than to model with `Codable`.
public enum JSONValue: Sendable, Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public subscript(key: String) -> JSONValue? {
        if case .object(let object) = self { object[key] } else { nil }
    }

    public var doubleValue: Double? {
        if case .number(let value) = self { value } else { nil }
    }

    public var arrayValue: [JSONValue]? {
        if case .array(let value) = self { value } else { nil }
    }

    public var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { value } else { nil }
    }

    /// Photomator stores flags as `0`/`1` in compact containers and as `true`/`false`
    /// in verbose ones.
    public var isTruthy: Bool {
        switch self {
        case .bool(let value): value
        case .number(let value): value != 0
        default: false
        }
    }

    /// Removes PTFoundation's version containers recursively. Two styles exist:
    /// compact `[version, {…}]` and verbose `{"version": v, "versionSpecifiContainer": {…}}`
    /// (sic: "Specifi").
    public func unwrappingVersionContainers() -> JSONValue {
        switch self {
        case .array(let items):
            if items.count == 2, case .number = items[0], case .object = items[1] {
                return items[1].unwrappingVersionContainers()
            }
            return .array(items.map { $0.unwrappingVersionContainers() })
        case .object(let object):
            if object.count == 2, object["version"] != nil,
               let payload = object["versionSpecifiContainer"] {
                return payload.unwrappingVersionContainers()
            }
            return .object(object.mapValues { $0.unwrappingVersionContainers() })
        default:
            return self
        }
    }
}

extension JSONValue: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            self = .object(try container.decode([String: JSONValue].self))
        }
    }
}
