@testable import PXM2NitroKit
import Testing

struct SelectiveColorMapperTests {
    private func hsl(_ adjustments: PhotomatorAdjustments) -> (NitroHSL?, [ConversionDiagnostic]) {
        var context = MappingContext(intensity: adjustments.intensity)
        let contents = SelectiveColorMapper.map(adjustments, context: &context)
        let hsl = contents.compactMap(\.hsl).first
        return (hsl, context.diagnostics)
    }

    private func adjustments(ranges: [JSONValue], intensity: Double = 1) -> PhotomatorAdjustments {
        PhotomatorAdjustments(formatVersion: 2, root: ["in": .number(intensity), "ca": ["E": 1, "a": .array(ranges)]])
    }

    private func range(hue: Double = 0, saturation: Double = 0, brightness: Double = 0) -> JSONValue {
        ["hue": .number(hue), "saturation": .number(saturation), "brightness": .number(brightness)]
    }

    @Test func mapsRangesInOrderAndAveragesLightBlue() throws {
        let (result, diagnostics) = hsl(try Fixtures.photomatorAdjustments("BW", "001"))
        let hsl = try #require(result)
        #expect(hsl[.red] == NitroHSL.Values())
        #expect(hsl[.orange].saturationDelta == -0.3)
        #expect(hsl[.orange].lumaDelta == 0.6494239267676767)
        #expect(hsl[.cyan].saturationDelta == -0.25)
        #expect(hsl[.lightBlue].saturationDelta == (hsl[.cyan].saturationDelta + hsl[.blue].saturationDelta) / 2)
        #expect(hsl[.lightBlue].lumaDelta == (hsl[.cyan].lumaDelta + hsl[.blue].lumaDelta) / 2)
        #expect(NitroHSLColor.allCases.allSatisfy { hsl[$0].range == 0 })
        #expect(diagnostics.map(\.kind) == [.uncalibrated])
    }

    @Test func scalesHueToDegreesAndAppliesIntensity() throws {
        let ranges = [range(hue: 0.5, saturation: 0.4)] + Array(repeating: range(), count: 7)
        let (full, _) = hsl(adjustments(ranges: ranges))
        #expect(full?[.red].hueDelta == 0.5 * MappingConstants.SelectiveColor.hueDegreesPerUnit)
        let (half, _) = hsl(adjustments(ranges: ranges, intensity: 0.5))
        #expect(half?[.red].hueDelta == 0.25 * MappingConstants.SelectiveColor.hueDegreesPerUnit)
        #expect(half?[.red].saturationDelta == 0.2)
    }

    @Test func neutralRangesProduceNothing() {
        let (result, diagnostics) = hsl(adjustments(ranges: Array(repeating: range(), count: 8)))
        #expect(result == nil)
        #expect(diagnostics.isEmpty)
    }

    @Test func missingRangesAreSkipped() {
        let adjustments = PhotomatorAdjustments(formatVersion: 2, root: ["in": 1, "ca": ["E": 1]])
        let (result, diagnostics) = hsl(adjustments)
        #expect(result == nil)
        #expect(diagnostics.map(\.kind) == [.skipped])
    }

    @Test func nearlyNeutralRangesProduceNothing() {
        let (result, diagnostics) = hsl(adjustments(ranges: Array(repeating: range(saturation: 1e-9), count: 8)))
        #expect(result == nil)
        #expect(diagnostics.isEmpty)
    }

    @Test func unexpectedRangeCountIsSkipped() {
        let (result, diagnostics) = hsl(adjustments(ranges: [range(saturation: 0.5)]))
        #expect(result == nil)
        #expect(diagnostics.map(\.kind) == [.skipped])
    }
}
