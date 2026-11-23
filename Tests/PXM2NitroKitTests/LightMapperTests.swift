@testable import PXM2NitroKit
import Testing

struct LightMapperTests {
    /// The mapped slider adjustments by kind, and the diagnostics.
    private func map(_ light: JSONValue, intensity: Double = 1) -> ([NitroSliderKind: NitroSliders], [ConversionDiagnostic]) {
        let (contents, diagnostics) = Fixtures.map(LightMapper.self, light, intensity: intensity)
        return (Dictionary(uniqueKeysWithValues: contents.compactMap(\.sliders).map { ($0.kind, $0) }), diagnostics)
    }

    @Test func mapsToneSlidersAndContrast() throws {
        let (sliders, diagnostics) = map(["E": 1, "e": 0.5, "h": -0.25, "s": 0.2, "b": -0.1, "c": 0.3])
        let toneSliders = try #require(sliders[.tone])
        #expect(toneSliders["exposure"] == 0.5)
        #expect(toneSliders["highlights"] == 0.875)
        #expect(toneSliders["shadows"] == 0.1)
        #expect(toneSliders["midtones"] == 0.9)
        #expect(toneSliders["boost"] == 1)
        #expect(toneSliders["boostShadowSliderValue"] == 0.9)
        #expect(try #require(sliders[.enhance])["contrast"] == 1.3)
        #expect(sliders[.detail] == nil)
        #expect(diagnostics.map(\.kind) == [.uncalibrated])
    }

    @Test func appliesIntensity() throws {
        let (sliders, _) = map(["E": 1, "e": 0.4, "h": -0.5, "c": -0.2], intensity: 0.5)
        #expect(sliders[.tone]?["exposure"] == 0.2)
        #expect(sliders[.tone]?["highlights"] == 0.875)
        #expect(sliders[.enhance]?["contrast"] == 0.9)
    }

    @Test func valuesAreClampedToNitrosRanges() throws {
        let (sliders, diagnostics) = map(["E": 1, "b": -1.5, "e": 4])
        let tone = try #require(sliders[.tone])
        #expect(tone["midtones"] == 0.5)
        #expect(tone["exposure"] == 3)
        #expect(diagnostics.map(\.message) == [
            "exposure was clamped to Nitro's range (-3 to 3)",
            "brightness was clamped to Nitro's range (0.5 to 1.5)",
            "exposure and brightness: placeholder scale, not calibrated yet",
        ])
    }

    @Test func raisedHighlightsAreReported() {
        let (sliders, diagnostics) = map(["E": 1, "h": 0.8])
        #expect(sliders.isEmpty)
        #expect(diagnostics.map(\.kind) == [.skipped])
    }

    @Test func textureIsReported() {
        let (sliders, diagnostics) = map(["E": 1, "e": 0.1, "T": 0.1])
        #expect(Array(sliders.keys) == [.tone])
        #expect(diagnostics.map(\.kind) == [.skipped, .uncalibrated])
    }

    /// Photomator's positive black point deepens the blacks; Nitro's positive Black lifts them.
    @Test func blackPointGoesToNitrosBlackSliderWithTheSignFlipped() throws {
        let (sliders, diagnostics) = map(["E": 1, "B": 0.25], intensity: 0.5)
        let tone = try #require(sliders[.tone])
        #expect(tone["blackPointDelta"] == -0.0625)
        #expect(diagnostics.map(\.message) == ["black point: placeholder scale, not calibrated yet"])
    }

    @Test func clarityGoesToDetail() throws {
        let (sliders, diagnostics) = map(["E": 1, "C": -0.2], intensity: 0.5)
        #expect(Array(sliders.keys) == [.detail])
        #expect(sliders[.detail]?["clarity"] == -0.1)
        #expect(diagnostics.map(\.message) == ["clarity: placeholder scale, not calibrated yet"])
    }

    @Test func neutralOrDisabledProducesNothing() {
        for light: JSONValue in [["E": 1, "e": 0, "h": 0, "B": 0], ["E": 0, "e": 0.5]] {
            let (sliders, diagnostics) = map(light)
            #expect(sliders.isEmpty)
            #expect(diagnostics.isEmpty)
        }
    }

    @Test func nonNumericValueIsSkipped() {
        let (sliders, diagnostics) = map(["E": 1, "e": "bright"])
        #expect(sliders.isEmpty)
        #expect(diagnostics.map(\.kind) == [.skipped])
    }
}
