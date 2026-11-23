import Foundation
@testable import PXM2NitroKit
import Testing

struct ConverterTests {
    private func contents(_ result: ConversionResult) throws -> [NitroAdjustment.Content] {
        try #require(result.preset).adjustments.map(\.content)
    }

    private func levelsCurves(_ result: ConversionResult, curves: Bool) throws -> NitroLevelsCurves {
        try #require(try contents(result).compactMap(\.levelsCurves).first { $0.isCurves == curves })
    }

    @Test func convertsRGBCurveToMasterChannel() throws {
        let preset = try Fixtures.photomatorPreset("BW", "001")
        let result = Converter.convert(preset)
        #expect(result.preset?.name == "BW 001")

        let curves = try levelsCurves(result, curves: true)
        #expect(!curves.operateOnGray)
        let rgb = try #require(preset.adjustments?.curves?.rgb)
        // guard, black handle, 4 inner points, white handle, guard
        #expect(curves.master.count == rgb.count + 2)
        #expect(curves.master[1] == NitroCurvePoint(x: rgb[0].x, y: rgb[0].y))
        #expect(curves.master[2] == NitroCurvePoint(x: rgb[1].x, y: rgb[1].y, deletable: true))
        #expect(curves.master[rgb.count] == NitroCurvePoint(x: 1, y: rgb[rgb.count - 1].y, isWhitePoint: true))
        #expect(curves.red == curves.channel())
    }

    @Test func reportsSkippedBlocks() throws {
        let result = Converter.convert(try Fixtures.photomatorPreset("BW", "001"))
        let skipped = Set(result.diagnostics.filter { $0.kind == .skipped }.compactMap(\.block))
        #expect(skipped == [.light, .blackAndWhite, .grain])
    }

    @Test func convertsRGBLevels() throws {
        let result = Converter.convert(try Fixtures.photomatorPreset("filmic", "PT800"))
        let levels = try levelsCurves(result, curves: false)
        #expect(!levels.operateOnGray)
        #expect(abs(levels.master[1].x - 0.009124071608744393) < 1e-12)
        #expect(levels.master[1].y == 0)
        #expect(levels.master[2] == NitroCurvePoint(x: 1, y: 1, isWhitePoint: true))
        // PT800 also has curves, selective color and light (tone sliders and clarity, no contrast).
        #expect(try result.preset?.adjustments.map(\.id) == ["Levels", "Curves", "HSL", "Tone", "Detail"])
    }

    @Test func warnsAboutUncentredLevelsMidtones() throws {
        // LS 002: luminance white 0.876 with a moved gray; red/blue only move a quarter handle.
        let result = Converter.convert(try Fixtures.photomatorPreset("LS", "002"))
        let levels = try levelsCurves(result, curves: false)
        #expect(levels.operateOnGray)
        #expect(abs(levels.master[2].x - 0.8758519575751356) < 1e-12)
        #expect(levels.red == levels.channel())
        #expect(levels.blue == levels.channel())
        let warnings = result.diagnostics.filter { $0.kind == .approximated && $0.block == .levels }
        #expect(warnings.count == 3)
    }

    @Test func emptyLevelsBlockIsNotWritten() throws {
        // EK100+ has Levels enabled without any edited channel.
        let result = Converter.convert(try Fixtures.photomatorPreset("filmic", "EK100+"))
        #expect(try contents(result).allSatisfy {
            if case .levelsCurves(let data) = $0 { data.isCurves } else { true }
        })
    }

    @Test func convertsChannelMixerRows() throws {
        let result = Converter.convert(try Fixtures.photomatorPreset("LS", "005"))
        let mixer = try #require(try contents(result).compactMap(\.channelMixer).first)
        #expect(mixer.red == NitroChannelMixer().red)
        #expect(mixer.blue == .init(red: -0.5, green: 1.5, blue: 0, bias: 0))
    }

    @Test func presetIntensityBlendsTowardNeutral() throws {
        let adjustments = PhotomatorAdjustments(formatVersion: 2, root: [
            "in": 0.5,
            "C": ["E": 1, "rgb": ["p": [[0, 0.2], [0.5, 0.7], [1, 1]]]],
            "m": ["E": 1, "r": ["red": 2, "green": 0, "blue": 0, "constant": 0.4]],
        ])
        let preset = Fixtures.preset("Half", adjustments)
        let result = Converter.convert(preset)
        #expect(result.preset?.name == "Half")

        let curves = try levelsCurves(result, curves: true)
        #expect(curves.master[1] == NitroCurvePoint(x: 0, y: 0.1))
        #expect(curves.master[2] == NitroCurvePoint(x: 0.5, y: 0.6, deletable: true))

        let mixer = try #require(try contents(result).compactMap(\.channelMixer).first)
        #expect(mixer.red == .init(red: 1.5, green: 0, blue: 0, bias: 0.2))
    }

    @Test func zeroIntensityCurvesAreNotWritten() {
        let adjustments = PhotomatorAdjustments(formatVersion: 2, root: [
            "in": 0,
            "C": ["E": 1, "rgb": ["p": [[0, 0.2], [0.5, 0.7], [1, 1]]]],
        ])
        let preset = Fixtures.preset("Zero", adjustments)
        #expect(Converter.convert(preset).preset == nil)
    }

    @Test func warnsAboutParametricCurveSliders() {
        let adjustments = PhotomatorAdjustments(formatVersion: 2, root: [
            "C": ["E": 1, "rgb": ["p": [[0, 0], [1, 1]], "d": 0.3, "l": 0, "s": 0, "h": -0.1]],
        ])
        let preset = Fixtures.preset("Sliders", adjustments)
        let diagnostics = Converter.convert(preset).diagnostics
        #expect(diagnostics.contains { $0.kind == .skipped && $0.block == .curves && $0.message.contains("d, h") })
    }

    @Test func presetWithoutConvertibleBlocksYieldsNothing() {
        let adjustments = PhotomatorAdjustments(formatVersion: 2, root: [
            "g": ["E": 1, "i": 0.5],
            "C": ["E": 1, "rgb": ["p": [[0, 0], [1, 1]]]],
        ])
        let preset = PhotomatorPreset(id: "x", name: "Grain only", collectionName: "Test",
                                      adjustments: adjustments, otherPropertyKeys: ["CropData"])
        let result = Converter.convert(preset)
        #expect(result.preset == nil)
        #expect(result.diagnostics.map(\.kind) == [.skipped, .skipped])
    }

    @Test func convertedPresetsAreValidNitroFiles() throws {
        for preset in try Fixtures.photomatorPresets("filmic") {
            let nitro = try #require(Converter.convert(preset).preset)
            #expect(try NitroPreset(data: nitro.encoded()) == nitro)
        }
    }
}
