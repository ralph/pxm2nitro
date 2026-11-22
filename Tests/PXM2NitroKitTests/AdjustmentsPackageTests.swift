import Foundation
@testable import PXM2NitroKit
import Testing

struct AdjustmentsPackageTests {
    @Test func loadsPresetsInCollectionOrder() throws {
        let presets = try AdjustmentsPackage.load(from: Fixtures.photomatorPackage("BW"))
        #expect(presets.map(\.name) == ["001", "002", "003", "004"])
        #expect(presets.allSatisfy { $0.collectionName == "BW" })
        #expect(presets.allSatisfy { $0.otherPropertyKeys.isEmpty })
    }

    @Test func rejectsNonPackages() {
        #expect(throws: PhotomatorError.self) {
            try AdjustmentsPackage.load(from: Fixtures.repositoryRoot.appending(path: "docs"))
        }
    }

    @Test func readsEnabledBlocksOfVersion2Preset() throws {
        let preset = try #require(try AdjustmentsPackage.load(from: Fixtures.photomatorPackage("BW"))
            .first { $0.name == "002" })
        let adjustments = try #require(preset.adjustments)
        #expect(adjustments.formatVersion == 2)
        #expect(adjustments.intensity == 1)
        #expect(Set(adjustments.enabledBlocks) ==
            [.curves, .blackAndWhite, .selectiveColor, .fade, .grain, .light])
    }

    @Test func readsVersion3PresetWithLevels() throws {
        let preset = try #require(try AdjustmentsPackage.load(from: Fixtures.photomatorPackage("filmic"))
            .first { $0.name == "PT800" })
        let adjustments = try #require(preset.adjustments)
        #expect(adjustments.formatVersion == 3)
        #expect(Set(adjustments.enabledBlocks) ==
            [.colorBalance, .curves, .levels, .selectiveColor, .grain, .light, .vignette, .whiteBalance])

        let levels = try #require(adjustments.levels)
        let rgb = try #require(levels.rgb)
        #expect(abs(rgb.black - 0.009124071608744393) < 1e-12)
        #expect(rgb.white == 1)
        #expect(levels.luminance?.gray == 0.5000000000000013)
        #expect(levels.red == nil)
    }

    @Test func readsCurvesAndSelectiveColor() throws {
        let preset = try #require(try AdjustmentsPackage.load(from: Fixtures.photomatorPackage("BW"))
            .first { $0.name == "001" })
        let adjustments = try #require(preset.adjustments)

        let curves = try #require(adjustments.curves)
        #expect(curves.rgb.count == 6)
        #expect(curves.rgb.first == CurvePoint(x: 0, y: 0.033715503246753244))
        #expect(curves.luminance == PhotomatorCurves.identity)

        let selectiveColor = try #require(adjustments.selectiveColor)
        #expect(selectiveColor.ranges.count == 8)
        #expect(selectiveColor.ranges[1].saturation == -0.3)
    }

    @Test func readsChannelMixerRows() throws {
        let preset = try #require(try AdjustmentsPackage.load(from: Fixtures.photomatorPackage("LS"))
            .first { $0.name == "005" })
        let mixer = try #require(preset.adjustments?.channelMixer)
        #expect(mixer.red == nil)
        #expect(mixer.blue == ChannelMixerRow(red: -0.5, green: 1.5, blue: 0, constant: 0))
    }

    @Test func disabledBlocksAreIgnored() throws {
        let preset = try #require(try AdjustmentsPackage.load(from: Fixtures.photomatorPackage("BW"))
            .first { $0.name == "001" })
        let adjustments = try #require(preset.adjustments)
        #expect(adjustments.channelMixer == nil)
        #expect(adjustments.enabledBlock(.selectiveClarity) == nil)
    }
}
