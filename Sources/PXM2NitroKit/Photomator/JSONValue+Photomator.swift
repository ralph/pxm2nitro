/// Photomator (PTFoundation) conventions on top of the generic JSON value.
extension JSONValue {
    /// Photomator stores flags as `0`/`1` in compact containers and as `true`/`false`
    /// in verbose ones.
    var isTruthy: Bool {
        switch self {
        case .bool(let value): value
        case .number(let value): value != 0
        default: false
        }
    }

    /// Whether this is an object whose listed fields are numbers wherever they are present.
    func isObject(withNumericFields keys: [String]) -> Bool {
        guard let object = objectValue else { return false }
        return keys.allSatisfy { key in object[key].map { $0.doubleValue != nil } ?? true }
    }

    /// Removes PTFoundation's version containers recursively. Two styles exist:
    /// compact `[version, {…}]` and verbose `{"version": v, "versionSpecifiContainer": {…}}`
    /// (sic: "Specifi").
    func unwrappingVersionContainers() -> JSONValue {
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
