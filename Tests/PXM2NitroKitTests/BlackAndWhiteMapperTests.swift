@testable import PXM2NitroKit
import Testing

struct BlackAndWhiteMapperTests {
    private func bw(_ payload: JSONValue, intensity: Double = 1) -> (NitroSliders?, [ConversionDiagnostic]) {
        let (contents, diagnostics) = Fixtures.map(BlackAndWhiteMapper.self, payload, intensity: intensity)
        return (contents.compactMap(\.sliders).first, diagnostics)
    }

    private func sum(_ sliders: NitroSliders) -> Double { sliders["red"] + sliders["green"] + sliders["blue"] }

    @Test func neutralFilterWritesNitrosDefaultWeights() throws {
        let (result, diagnostics) = bw(["E": 1, "i": 1, "t": 0])
        #expect(try #require(result) == NitroSliders(.blackAndWhite))
        #expect(diagnostics.map(\.kind) == [.uncalibrated])
    }

    @Test func filterColourTiltsWeightsAndKeepsTheirSum() throws {
        let (result, diagnostics) = bw(["E": 1, "b": ["red": 0.5, "green": 0, "blue": -0.5]])
        let nitro = try #require(result)
        #expect(nitro["red"] > 0.299)
        #expect(nitro["blue"] < 0.114)
        #expect(abs(sum(nitro) - 1) < 1e-12)
        #expect(diagnostics.map(\.kind) == [.uncalibrated])
    }

    @Test func toningIntensityAndFilterLuminanceAreReported() {
        let (result, diagnostics) = bw(["E": 1, "t": 0.2, "i": 0.5, "b": ["luminance": 0.1, "saturation": 0.1]])
        #expect(result != nil)
        #expect(diagnostics.map(\.kind) == [.uncalibrated, .skipped, .skipped, .skipped, .skipped])
    }

    @Test func partialPresetIntensityIsReported() throws {
        let (result, diagnostics) = bw(["E": 1, "b": ["red": 0.4]], intensity: 0.5)
        let full = try #require(bw(["E": 1, "b": ["red": 0.2]]).0)
        #expect(result == full)   // the filter is blended toward neutral …
        #expect(diagnostics.map(\.kind).contains(.approximated))   // … but the grey cannot be
    }

    @Test func zeroStrengthWritesNothing() {
        for (result, diagnostics) in [bw(["E": 1, "b": ["red": 0.4]], intensity: 0), bw(["E": 1, "i": 0])] {
            #expect(result == nil)
            #expect(diagnostics.isEmpty)
        }
    }

    @Test func malformedFilterIsSkipped() {
        let (result, diagnostics) = bw(["E": 1, "b": ["red": "warm"]])
        #expect(result == nil)
        #expect(diagnostics.map(\.kind) == [.skipped])
    }

    @Test func samplePresets() throws {
        for name in ["001", "002", "003", "004"] {
            let result = Converter.convert(try Fixtures.photomatorPreset("BW", name))
            let nitro = try #require(result.preset?.adjustments.compactMap(\.content.sliders).first { $0.kind == .blackAndWhite })
            #expect(abs(sum(nitro) - 1) < 1e-12)
            #expect(nitro != NitroSliders(.blackAndWhite))   // the filter colour was read
            #expect(result.blocks.contains(BlockOutcome(.blackAndWhite, .approximated)))
        }
    }
}
