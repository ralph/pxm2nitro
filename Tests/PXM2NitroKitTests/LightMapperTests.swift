import Foundation
@testable import PXM2NitroKit
import Testing

struct LightMapperTests {
    private func map(_ light: JSONValue, intensity: Double = 1) -> (tone: NitroSliders?, enhance: NitroSliders?, [ConversionDiagnostic]) {
        let (contents, diagnostics) = Fixtures.map(LightMapper.self, light, intensity: intensity)
        let sliders = contents.compactMap(\.sliders)
        return (sliders.first { $0.kind == .tone }, sliders.first { $0.kind == .enhance }, diagnostics)
    }

    @Test func mapsToneSlidersAndContrast() throws {
        let (tone, enhance, diagnostics) = map(["E": 1, "e": 0.5, "h": -0.25, "s": 0.2, "b": -0.1, "c": 0.3])
        let toneSliders = try #require(tone)
        #expect(toneSliders["exposure"] == 0.5)
        #expect(toneSliders["highlights"] == 0.75)
        #expect(toneSliders["shadows"] == 0.2)
        #expect(toneSliders["midtones"] == 0.9)
        #expect(toneSliders["boost"] == 1)
        #expect(toneSliders["boostShadowSliderValue"] == 0.9)
        #expect(try #require(enhance)["contrast"] == 1.3)
        #expect(diagnostics.map(\.kind) == [.uncalibrated])
    }

    @Test func appliesIntensity() throws {
        let (tone, enhance, _) = map(["E": 1, "e": 0.4, "h": -0.5, "c": -0.2], intensity: 0.5)
        #expect(tone?["exposure"] == 0.2)
        #expect(tone?["highlights"] == 0.75)
        #expect(enhance?["contrast"] == 0.9)
    }

    @Test func raisedHighlightsAreReported() {
        let (tone, _, diagnostics) = map(["E": 1, "h": 0.8])
        #expect(tone == nil)
        #expect(diagnostics.map(\.kind) == [.skipped])
    }

    @Test func blackPointClarityAndTextureAreReported() {
        let (tone, enhance, diagnostics) = map(["E": 1, "e": 0.1, "B": 0.2, "C": -0.1, "T": 0.1])
        #expect(tone != nil)
        #expect(enhance == nil)
        #expect(diagnostics.map(\.kind) == [.skipped, .skipped, .skipped, .uncalibrated])
    }

    @Test func neutralOrDisabledProducesNothing() {
        for light: JSONValue in [["E": 1, "e": 0, "h": 0, "B": 0], ["E": 0, "e": 0.5]] {
            let (tone, enhance, diagnostics) = map(light)
            #expect(tone == nil && enhance == nil)
            #expect(diagnostics.isEmpty)
        }
    }

    @Test func nonNumericValueIsSkipped() {
        let (tone, _, diagnostics) = map(["E": 1, "e": "bright"])
        #expect(tone == nil)
        #expect(diagnostics.map(\.kind) == [.skipped])
    }

    @Test func toneTemplateMatchesNitrosOwnToneBlock() throws {
        // Lebendig's Tone only moved the RAW-only white point; everything else is at Nitro's defaults.
        let preset = try NitroPreset(data: Data(contentsOf: Fixtures.nitroPreset("Lebendig")))
        var lebendig = try #require(preset.adjustments.compactMap(\.content.sliders).first { $0.kind == .tone })
        lebendig["whitePointDelta"] = 0
        #expect(lebendig == NitroSliders(.tone))
    }
}
