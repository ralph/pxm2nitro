import Foundation
import PXM2NitroKit
@testable import PXM2NitroUI
import Testing

@MainActor
struct ConversionSessionTests {
    static let samples = URL(filePath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "sample_presets_photomator")

    static func package(_ name: String) -> URL { samples.appending(path: "\(name).adjustments") }

    private func session(_ names: String...) -> ConversionSession {
        let session = ConversionSession()
        session.add(names.map(Self.package))
        return session
    }

    private func temporaryFolder() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "pxm2nitro-ui-\(UUID().uuidString)")
    }

    @Test func summarisesPackages() throws {
        let session = session("BW", "filmic", "LS")
        #expect(session.packages.map(\.fileName) == ["BW.adjustments", "filmic.adjustments", "LS.adjustments"])
        #expect(session.presetCount == 19)
        #expect(session.convertibleCount == 19)

        let bw = session.packages[0]
        #expect(bw.collectionNames == ["BW"])
        #expect(bw.convertibleCount == 4)
        #expect(bw.fullyConvertibleCount == 0)
        #expect(bw.blocks(.carriedOver) == [.curves])
        #expect(bw.blocks(.approximated) == [.selectiveColor])
        #expect(bw.blocks(.leftOut) == [.light, .fade, .blackAndWhite, .vignette, .grain])
    }

    @Test func packageBlocksUseTheLeastFavourableStatus() throws {
        // Only LS 002 approximates Levels; the other LS presets do not use Levels at all.
        let ls = try #require(session("LS").packages.first)
        #expect(ls.blocks(.approximated).contains(.levels))
        #expect(ls.blocks(.carriedOver) == [.curves, .channelMixer])
    }

    @Test func presetSummaryNamesTheNitroFile() throws {
        let filmic = try #require(session("filmic").packages.first)
        let pt800 = try #require(filmic.presets.first { $0.name == "PT800" })
        #expect(pt800.nitroFileName == "🎞️ PT800.nitropreset")
        #expect(pt800.blocks(.carriedOver) == [.levels, .curves])
        #expect(pt800.blocks(.leftOut) == [.light, .whiteBalance, .colorBalance, .vignette, .grain])
    }

    @Test func addingAPackageAgainReplacesIt() {
        let session = session("BW", "LS")
        session.add([Self.package("BW")])
        #expect(session.packages.map(\.fileName) == ["BW.adjustments", "LS.adjustments"])
    }

    @Test func reportsFilesThatAreNotPackages() {
        let session = ConversionSession()
        session.add([Self.samples.appending(path: "missing.adjustments"), Self.package("BW")])
        #expect(session.packages.count == 1)
        #expect(session.loadErrors.map(\.message) == ["missing.adjustments is not a Photomator or Pixelmator Pro preset file."])
        session.add([Self.package("LS")])
        #expect(session.loadErrors.isEmpty)
    }

    @Test func removeAndReset() {
        let session = session("BW", "LS")
        session.remove(Self.package("BW").standardizedFileURL)
        #expect(session.packages.map(\.fileName) == ["LS.adjustments"])
        session.reset()
        #expect(session.packages.isEmpty)
        #expect(session.lastExport == nil)
    }

    @Test func exportsEveryPresetAndKeepsExistingFiles() throws {
        let session = session("BW", "filmic", "LS")
        let folder = temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }

        let first = session.export(to: folder)
        #expect(first.written.count == 19)
        #expect(first.writtenWithLosses == 19)
        #expect(first.existing.isEmpty && first.failures.isEmpty && first.nothingToConvert == 0)
        #expect(session.lastExport?.written.count == 19)

        let second = session.export(to: folder)
        #expect(second.written.isEmpty)
        #expect(second.existing.count == 19)

        session.replaceExisting = true
        #expect(session.export(to: folder).written.count == 19)
    }
}
