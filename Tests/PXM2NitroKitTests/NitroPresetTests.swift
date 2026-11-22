import Foundation
@testable import PXM2NitroKit
import Testing

struct NitroPresetTests {
    static let samples = ["N1 all", "N0 defaults", "curves hsl channel mixer", "Lebendig", "Entsättigen"]

    /// The original inner JSON objects of a sample, keyed by adjustment id.
    private func originalInnerJSON(_ sample: String) throws -> [String: JSONValue] {
        let root = try JSONValue(data: Data(contentsOf: Fixtures.nitroPreset(sample)))
        let entries = try #require(root["editModel"]?["versions"]?.arrayValue?.first?["adjDataArr"]?.arrayValue)
        return try Dictionary(uniqueKeysWithValues: entries.map { entry in
            let json = try #require(entry["json"]?.stringValue)
            return (try #require(entry["id"]?.stringValue), try JSONValue(data: Data(json.utf8)))
        })
    }

    @Test(arguments: samples)
    func modelledAdjustmentsReproduceNitrosJSON(sample: String) throws {
        let preset = try NitroPreset(data: Data(contentsOf: Fixtures.nitroPreset(sample)))
        let original = try originalInnerJSON(sample)
        #expect(preset.adjustments.map(\.id).sorted() == original.keys.sorted())

        for adjustment in preset.adjustments {
            var expected = try #require(original[adjustment.id]?.objectValue)
            var actual = try #require(adjustment.json.objectValue)
            // Nitro writes its UI language here ("Kurven"); not relevant for applying presets.
            expected["localizedName"] = nil
            actual["localizedName"] = nil
            #expect(actual == expected, "\(sample) / \(adjustment.id)")
        }
    }

    @Test(arguments: samples)
    func encodingRoundTrips(sample: String) throws {
        let preset = try NitroPreset(data: Data(contentsOf: Fixtures.nitroPreset(sample)))
        #expect(try NitroPreset(data: preset.encoded()) == preset)
    }

    @Test func parsesModelledAdjustments() throws {
        let preset = try NitroPreset(data: Data(contentsOf: Fixtures.nitroPreset("curves hsl channel mixer")))
        let contents = preset.adjustments.map(\.content)

        let mixer = try #require(contents.compactMap(\.channelMixer).first)
        #expect(mixer.red == .init(red: 1, green: -0.29553092, blue: 0.23336692, bias: 0.03830644))
        #expect(mixer.green == .init(red: 0, green: 1, blue: 0))

        let hsl = try #require(contents.compactMap(\.hsl).first)
        #expect(hsl[.orange].hueDelta == 12.730264)
        #expect(hsl[.lightBlue] == .init())

        let curves = try #require(contents.compactMap(\.levelsCurves).first)
        #expect(curves.isCurves)
        #expect(curves.master.count == 6)
        #expect(curves.red == curves.channel())
    }

    @Test func encodesAdjustmentsAsJSONStrings() throws {
        var curves = NitroLevelsCurves(isCurves: true)
        curves.master = curves.channel(inner: [CurvePoint(x: 0.25, y: 0.4)])
        let preset = NitroPreset(name: "Test", adjustments: [
            NitroAdjustment(.levelsCurves(curves)),
            NitroAdjustment(.channelMixer(NitroChannelMixer())),
            NitroAdjustment(.hsl(NitroHSL(values: [.red: .init(hueDelta: 10)]))),
        ])

        let root = try JSONValue(data: preset.encoded())
        #expect(root["name"] == "Test")
        let version = try #require(root["editModel"]?["versions"]?.arrayValue?.first)
        #expect(version["decoderVersionString"] == "9.dng")
        let entries = try #require(version["adjDataArr"]?.arrayValue)
        #expect(entries.compactMap { $0["id"]?.stringValue } == ["Curves", "ChannelMixer", "HSL"])

        let hsl = try JSONValue(data: Data(try #require(entries[2]["json"]?.stringValue).utf8))
        #expect(hsl["numeric"]?.objectValue?.count == 36)
        #expect(hsl["numeric"]?["hueDelta_red"] == 10)
        #expect(hsl["version"] == 1)
        #expect(hsl["enabled"] == true)
    }

    @Test func channelSkeleton() {
        let points = NitroLevelsCurves(isCurves: true)
            .channel(black: CurvePoint(x: 0.1, y: 0.05), inner: [CurvePoint(x: 0.5, y: 0.6)])
        #expect(points.map(\.x) == [0, 0.1, 0.5, 1, 2])
        #expect(points.map(\.invisible) == [true, false, false, false, true])
        #expect(points.map(\.deletable) == [false, false, true, false, false])
        #expect(points.map(\.isWhitePoint) == [false, false, false, true, false])
    }

    @Test func levelsAndCurvesIdsFollowTheFlag() {
        #expect(NitroAdjustment(.levelsCurves(NitroLevelsCurves(isCurves: false))).id == "Levels")
        #expect(NitroAdjustment(.levelsCurves(NitroLevelsCurves(isCurves: true))).id == "Curves")
    }

    @Test func otherAdjustmentsHonourFlags() throws {
        var adjustment = NitroAdjustment(id: "Tone", json: ["enabled": true, "numeric": ["exposure": 0.5]])
        #expect(adjustment.isEnabled)
        adjustment.isEnabled = false
        #expect(adjustment.json["enabled"] == false)
        #expect(adjustment.json["numeric"]?["exposure"] == 0.5)
    }

    @Test func builtPresetRoundTrips() throws {
        let preset = NitroPreset(name: "T", adjustments: [
            NitroAdjustment(.hsl(NitroHSL(values: [.red: .init(hueDelta: 10)]))),
        ])
        #expect(try NitroPreset(data: preset.encoded()) == preset)
    }

    @Test func unknownHSLVersionStaysRaw() {
        let adjustment = NitroAdjustment(id: "HSL", json: ["version": 2, "numeric": ["hueDelta_red": 1]])
        guard case .other = adjustment.content else { Issue.record("expected .other"); return }
    }

    @Test(arguments: [
        #"{"name": "x"}"#,
        #"not json"#,
        #"{"name":"x","editModel":{"currentVersionIndex":"0","versions":[{"adjDataArr":[]}]}}"#,
        #"{"name":"x","editModel":{"versions":[{"adjDataArr":[{"id":"Tone","json":"{broken"}]}]}}"#,
        #"{"name":"x","editModel":{"versions":[{"adjDataArr":[{"id":"Tone","json":"[1]"}]}]}}"#,
    ])
    func rejectsMalformedPresets(json: String) {
        #expect(throws: NitroError.self) { try NitroPreset(data: Data(json.utf8)) }
    }
}
