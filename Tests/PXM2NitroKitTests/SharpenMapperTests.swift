@testable import PXM2NitroKit
import Testing

struct SharpenMapperTests {
    private func detail(_ sharpen: JSONValue, intensity: Double = 1) -> (NitroSliders?, [ConversionDiagnostic]) {
        let (contents, diagnostics) = Fixtures.map(SharpenMapper.self, sharpen, intensity: intensity)
        return (contents.compactMap(\.sliders).first, diagnostics)
    }

    @Test func mapsIntensityToDetailSharpen() throws {
        let (result, diagnostics) = detail(["E": 1, "i": 0.4, "r": 2.5])
        let detail = try #require(result)
        #expect(detail.kind == .detail)
        #expect(detail["sharpen"] == 0.4)
        #expect(diagnostics.map(\.kind) == [.uncalibrated])
    }

    @Test func appliesIntensity() {
        #expect(detail(["E": 1, "i": 0.5, "r": 2.5], intensity: 0.5).0?["sharpen"] == 0.25)
    }

    @Test func nonDefaultRadiusIsReported() {
        let (result, diagnostics) = detail(["E": 1, "i": 0.25, "r": 1])
        #expect(result != nil)
        #expect(diagnostics.map(\.kind) == [.uncalibrated, .skipped])
    }

    @Test func missingFieldsAreAtPhotomatorsDefaults() {
        let (result, diagnostics) = detail(["E": 1])
        #expect(result?["sharpen"] == 0.5)
        #expect(diagnostics.map(\.kind) == [.uncalibrated])
    }

    @Test func zeroOrDisabledProducesNothing() {
        for sharpen: JSONValue in [["E": 1, "i": 0, "r": 1], ["E": 0, "i": 0.5]] {
            let (result, diagnostics) = detail(sharpen)
            #expect(result == nil)
            #expect(diagnostics.isEmpty)
        }
    }

    @Test func mergesWithLightClarity() throws {
        let adjustments = PhotomatorAdjustments(formatVersion: 2, root: [
            "in": 1, "l": ["E": 1, "C": -0.3], "S": ["E": 1, "i": 0.5, "r": 2.5],
        ])
        let preset = try #require(Converter.convert(Fixtures.preset("Sharp", adjustments)).preset)
        let details = preset.adjustments.compactMap(\.content.sliders).filter { $0.kind == .detail }
        #expect(details.count == 1)
        #expect(abs((details.first?["clarity"] ?? 0) + 0.9) < 1e-12)
        #expect(details.first?["sharpen"] == 0.5)
    }
}
