import Foundation
@testable import PXM2NitroKit
import Testing

struct AdjustmentsPackageTests {
    @Test func loadsPresetsInCollectionOrder() throws {
        let package = try AdjustmentsPackage.load(from: Fixtures.photomatorPackage("BW"))
        #expect(package.presets.map(\.name) == ["001", "002", "003", "004"])
        #expect(package.presets.allSatisfy { $0.collectionName == "BW" && $0.otherPropertyKeys.isEmpty })
        #expect(package.presets.first?.title == "BW / 001")
        #expect(package.failures.isEmpty)
    }

    @Test func rejectsNonPackages() {
        #expect(throws: PhotomatorError.self) {
            try AdjustmentsPackage.load(from: Fixtures.repositoryRoot.appending(path: "docs"))
        }
    }

    @Test func reportsUnreadablePresetsWithoutFailingThePackage() throws {
        let package = FileManager.default.temporaryDirectory
            .appending(path: "pxm2nitro-test-\(UUID().uuidString).adjustments")
        let presets = package.appending(path: "presets")
        try FileManager.default.createDirectory(at: presets, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: package) }
        try FileManager.default.copyItem(
            at: Fixtures.photomatorPackage("BW").appending(path: "presets/25980DAD-4C3C-40C0-A8D9-49B5A775B6BD.plist"),
            to: presets.appending(path: "A.plist"))
        try Data("not a plist".utf8).write(to: presets.appending(path: "B.plist"))

        let loaded = try AdjustmentsPackage.load(from: package)
        #expect(loaded.presets.map(\.name) == ["002"])
        #expect(loaded.presets.first?.collectionName == nil)
        #expect(loaded.failures.map(\.file.lastPathComponent) == ["B.plist"])
    }

    @Test func readsEnabledBlocksOfVersion2Preset() throws {
        let adjustments = try Fixtures.photomatorAdjustments("BW", "002")
        #expect(adjustments.formatVersion == 2)
        #expect(adjustments.intensity == 1)
        #expect(Set(adjustments.enabledBlocks) ==
            [.curves, .blackAndWhite, .selectiveColor, .fade, .grain, .light])
    }

    @Test func readsVersion3PresetWithLevels() throws {
        let adjustments = try Fixtures.photomatorAdjustments("filmic", "PT800")
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
        let adjustments = try Fixtures.photomatorAdjustments("BW", "001")

        let curves = try #require(adjustments.curves)
        let rgb = try #require(curves.rgb)
        #expect(rgb.count == 6)
        #expect(rgb.first == CurvePoint(x: 0, y: 0.033715503246753244))
        #expect(curves.luminance == PhotomatorCurves.identityCurve)

        let selectiveColor = try #require(adjustments.selectiveColor)
        #expect(selectiveColor.count == 8)
        #expect(selectiveColor[1].saturation == -0.3)
    }

    @Test func readsChannelMixerRows() throws {
        let mixer = try #require(try Fixtures.photomatorAdjustments("LS", "005").channelMixer)
        #expect(mixer.red == nil)
        #expect(mixer.blue == ChannelMixerRow(red: -0.5, green: 1.5, blue: 0, constant: 0))
    }

    @Test func disabledBlocksAreIgnored() throws {
        let adjustments = try Fixtures.photomatorAdjustments("BW", "001")
        #expect(adjustments.channelMixer == nil)
        #expect(adjustments.enabledBlock(.selectiveClarity) == nil)
    }
}
