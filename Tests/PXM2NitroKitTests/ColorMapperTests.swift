@testable import PXM2NitroKit
import Testing

struct ColorMapperTests {
    private func enhance(_ color: JSONValue, intensity: Double = 1) -> (NitroSliders?, [ConversionDiagnostic]) {
        let (contents, diagnostics) = Fixtures.map(ColorMapper.self, color, intensity: intensity)
        return (contents.compactMap(\.sliders).first, diagnostics)
    }

    @Test func mapsSaturationAndVibrance() throws {
        let (result, diagnostics) = enhance(["E": 1, "h": 0, "s": -0.2, "v": 0.15])
        let enhance = try #require(result)
        #expect(enhance.kind == .enhance)
        #expect(isNearlyEqual(enhance["saturation"], 0.84))
        #expect(enhance["vibrancy"] == 0.15)
        #expect(enhance["contrast"] == 1)
        #expect(diagnostics.map(\.kind) == [.uncalibrated])
    }

    @Test func appliesIntensity() throws {
        let (result, _) = enhance(["E": 1, "s": -0.4, "v": 0.2], intensity: 0.5)
        let enhance = try #require(result)
        #expect(isNearlyEqual(enhance["saturation"], 0.84))
        #expect(enhance["vibrancy"] == 0.1)
    }

    @Test func saturationDoesNotGoNegative() throws {
        let (result, _) = enhance(["E": 1, "s": -1.5])
        #expect(try #require(result)["saturation"] == 0)
    }

    @Test func hueAloneIsLeftOut() {
        let (result, diagnostics) = enhance(["E": 1, "h": -0.1, "s": 0, "v": 0])
        #expect(result == nil)
        #expect(diagnostics.map(\.kind) == [.skipped])
    }

    @Test func neutralOrDisabledProducesNothing() {
        for color: JSONValue in [["E": 1, "h": 0, "s": 0, "v": 0], ["E": 0, "s": -0.5]] {
            let (result, diagnostics) = enhance(color)
            #expect(result == nil)
            #expect(diagnostics.isEmpty)
        }
    }

    @Test func nonNumericValueIsSkipped() {
        let (result, diagnostics) = enhance(["E": 1, "s": "a lot"])
        #expect(result == nil)
        #expect(diagnostics.map(\.kind) == [.skipped])
    }

    @Test func samplePresets() throws {
        // LS 002: Color saturation −20 %, plus Light contrast +25 % merged into the same Enhance.
        let saturated = Converter.convert(try Fixtures.photomatorPreset("LS", "002"))
        let enhances = try #require(saturated.preset).adjustments.compactMap(\.content.sliders).filter { $0.kind == .enhance }
        #expect(enhances.count == 1)
        let enhance = try #require(enhances.first)
        #expect(isNearlyEqual(enhance["saturation"], 0.84))
        #expect(isNearlyEqual(enhance["contrast"], 1.075))
        // Saturation alone is calibrated, so Color carries over without a note.
        #expect(saturated.blocks.contains(BlockOutcome(.hueSaturation, .carriedOver)))

        let hueOnly = Converter.convert(try Fixtures.photomatorPreset("LS", "005"))
        #expect(hueOnly.blocks.contains(BlockOutcome(.hueSaturation, .leftOut)))
    }
}
