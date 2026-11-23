import Foundation
import PXM2NitroKit
import PXM2NitroTestSupport
@testable import PXM2NitroUI
import Testing

@MainActor
struct ConversionSessionTests {
    private func session(_ names: String...) async -> ConversionSession {
        let session = ConversionSession()
        await session.add(names.map(SampleFiles.photomatorPackage))
        return session
    }

    @Test func summarisesPackages() async {
        let session = await session("BW", "filmic", "LS")
        #expect(session.packages.map(\.fileName) == ["BW.adjustments", "filmic.adjustments", "LS.adjustments"])
        #expect(session.presetCount == 19)
        #expect(session.convertibleCount == 19)
        #expect(!session.isBusy)

        let bw = session.packages[0]
        #expect(bw.collectionNames == ["BW"])
        #expect(bw.convertibleCount == 4)
        #expect(bw.losslessCount == 0)
        #expect(bw.blocks.blocks(.carriedOver) == [.curves])
        #expect(bw.blocks.blocks(.approximated) == [.light, .selectiveColor, .vignette])
        #expect(bw.blocks.blocks(.leftOut) == [.fade, .blackAndWhite, .grain])
    }

    @Test func packageBlocksUseTheLeastFavourableStatus() async throws {
        // Only LS 002 approximates Levels; the other LS presets do not use Levels at all.
        let ls = try #require(await session("LS").packages.first)
        #expect(ls.blocks.blocks(.approximated).contains(.levels))
        #expect(ls.blocks.blocks(.carriedOver) == [.curves, .channelMixer])
    }

    @Test func presetSummaryNamesTheNitroFile() async throws {
        let filmic = try #require(await session("filmic").packages.first)
        let pt800 = try #require(filmic.presets.first { $0.preset.name == "PT800" })
        #expect(pt800.nitroFileName == "🎞️ PT800.nitropreset")
        #expect(pt800.result.blocks.blocks(.carriedOver) == [.levels, .curves])
        #expect(pt800.result.blocks.blocks(.leftOut) == [.whiteBalance, .colorBalance, .grain])
    }

    @Test func addingAPackageAgainReplacesIt() async {
        let session = await session("BW", "LS")
        await session.add([SampleFiles.photomatorPackage("BW")])
        #expect(session.packages.map(\.fileName) == ["BW.adjustments", "LS.adjustments"])
    }

    @Test func trailingSlashStillMatchesTheSamePackage() async {
        let session = await session("BW")
        let path = SampleFiles.photomatorPackage("BW").path(percentEncoded: false)
        await session.add([URL(filePath: path + "/"), URL(filePath: path, directoryHint: .notDirectory)])
        #expect(session.packages.count == 1)
    }

    @Test func reportsFilesThatAreNotPackages() async {
        let session = ConversionSession()
        let missing = SampleFiles.repositoryRoot.appending(path: "sample_presets_photomator/missing.adjustments")
        await session.add([missing, SampleFiles.photomatorPackage("BW")])
        #expect(session.packages.count == 1)
        #expect(session.loadErrors.map(\.message) == ["missing.adjustments is not a Photomator or Pixelmator Pro preset file."])
        await session.add([SampleFiles.photomatorPackage("LS")])
        #expect(session.loadErrors.isEmpty)
    }

    @Test func removeAndReset() async {
        let session = await session("BW", "LS")
        session.remove(session.packages[0].id)
        #expect(session.packages.map(\.fileName) == ["LS.adjustments"])
        session.reset()
        #expect(session.packages.isEmpty)
        #expect(session.lastExport == nil)
    }

    @Test func exportsEveryPresetAndKeepsExistingFiles() async {
        let session = await session("BW", "filmic", "LS")
        let folder = SampleFiles.temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }

        let first = await session.export(to: folder)
        #expect(first.written.count == 19)
        #expect(first.writtenWithLosses == 19)
        #expect(first.existing.isEmpty && first.failures.isEmpty && first.nothingToConvert == 0)
        #expect(session.lastExport?.written.count == 19)

        let second = await session.export(to: folder)
        #expect(second.written.isEmpty)
        #expect(second.existing.count == 19)

        session.replaceExisting = true
        #expect(await session.export(to: folder).written.count == 19)
    }

    @Test func overlappingExportsDoNotOverwriteEachOther() async {
        let session = await session("BW")
        let folder = SampleFiles.temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }

        async let first = session.export(to: folder)
        async let second = session.export(to: folder)
        let reports = await [first, second]
        #expect(reports.map(\.written.count).sorted() == [0, 4])
        #expect(reports.map(\.existing.count).sorted() == [0, 4])
    }
}
