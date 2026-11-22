import Foundation
@testable import PXM2NitroKit
import Testing

struct JSONValueTests {
    private func decode(_ json: String) throws -> JSONValue {
        try JSONDecoder().decode(JSONValue.self, from: Data(json.utf8))
    }

    @Test func distinguishesBoolsFromNumbers() throws {
        #expect(try decode("true") == .bool(true))
        #expect(try decode("1") == .number(1))
    }

    @Test func unwrapsCompactContainers() throws {
        let value = try decode(#"[2, {"l": [1, {"E": 1, "e": 0.5}]}]"#).unwrappingVersionContainers()
        #expect(value == .object(["l": .object(["E": .number(1), "e": .number(0.5)])]))
    }

    @Test func unwrapsVerboseContainers() throws {
        let value = try decode(#"{"version": 1, "versionSpecifiContainer": {"red": 0.3}}"#)
            .unwrappingVersionContainers()
        #expect(value == .object(["red": .number(0.3)]))
    }

    @Test func keepsPlainArrays() throws {
        let value = try decode("[[0, 0], [1, 1]]").unwrappingVersionContainers()
        #expect(value == .array([.array([.number(0), .number(0)]), .array([.number(1), .number(1)])]))
    }

    @Test func truthiness() {
        #expect(JSONValue.number(1).isTruthy)
        #expect(JSONValue.bool(true).isTruthy)
        #expect(!JSONValue.number(0).isTruthy)
        #expect(!JSONValue.bool(false).isTruthy)
    }
}
