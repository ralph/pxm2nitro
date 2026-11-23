@testable import PXM2NitroKit
import Testing

struct VignetteMapperTests {
    private func vignette(_ payload: JSONValue, intensity: Double = 1) -> (NitroSliders?, [ConversionDiagnostic]) {
        let (contents, diagnostics) = Fixtures.map(VignetteMapper.self, payload, intensity: intensity)
        return (contents.compactMap(\.sliders).first, diagnostics)
    }

    @Test func mapsStrengthToIntensity() throws {
        let (result, diagnostics) = vignette(["E": 1, "e": 0.3, "b": 0, "s": 1])
        let nitro = try #require(result)
        #expect(nitro.kind == .vignette)
        #expect(nitro["intensity"] == 0.3)
        #expect(diagnostics.map(\.kind) == [.uncalibrated])
    }

    @Test func defaultVignetteIsStillWritten() throws {
        // Photomator's default vignette darkens the edges, like Nitro's.
        let (result, _) = vignette(["E": 1])
        #expect(try #require(result)["intensity"] == 0.5)
    }

    @Test func appliesIntensityAndSkipsZeroStrength() {
        #expect(vignette(["E": 1, "e": 0.4], intensity: 0.5).0?["intensity"] == 0.2)
        let (result, diagnostics) = vignette(["E": 1, "e": 0, "b": 0.5])
        #expect(result == nil)
        #expect(diagnostics.isEmpty)
    }

    @Test func softnessAndBlackPointAreReported() throws {
        // BW 004: exposure 0.1, black point 0.6, softness 0.9.
        let result = Converter.convert(try Fixtures.photomatorPreset("BW", "004"))
        let messages = result.diagnostics.filter { $0.block == .vignette }.map(\.kind)
        #expect(messages == [.uncalibrated, .skipped, .skipped])
        #expect(result.blocks.contains(BlockOutcome(.vignette, .approximated)))
        let nitro = try #require(result.preset?.adjustments.compactMap(\.content.sliders).first { $0.kind == .vignette })
        #expect(nitro["intensity"] == 0.1)
    }
}
