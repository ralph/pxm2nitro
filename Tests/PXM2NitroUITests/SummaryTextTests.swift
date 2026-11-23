import Foundation
import PXM2NitroKit
import PXM2NitroTestSupport
@testable import PXM2NitroUI
import Testing

@MainActor
struct SummaryTextTests {
    private func package(_ name: String) async throws -> PackageSummary {
        let session = ConversionSession()
        await session.add([SampleFiles.photomatorPackage(name)])
        return try #require(session.packages.first)
    }

    @Test func packageLines() async throws {
        let bw = try await package("BW")
        #expect(SummaryText.subtitle(for: bw) == "Collection “BW” · 4 presets")
        #expect(SummaryText.conversionNote(for: bw) == "presets convert, all partly")
    }

    @Test func counts() {
        #expect(SummaryText.count(1, "preset") == "1 preset")
        #expect(SummaryText.count(2, "preset was", "presets were") == "2 presets were")
        #expect(SummaryText.exportSummary(convertible: 0, presets: 0) == "Add presets to see what carries over to Nitro.")
        #expect(SummaryText.exportSummary(convertible: 19, presets: 19) == "19 Nitro presets will be written")
        #expect(SummaryText.exportSummary(convertible: 1, presets: 3) == "1 Nitro preset will be written")
    }

    @Test func exportNotes() {
        var report = ExportReport(folder: URL(filePath: "/tmp/out"))
        report.written = [URL(filePath: "/tmp/out/a"), URL(filePath: "/tmp/out/b")]
        report.writtenWithLosses = 1
        report.existing = [URL(filePath: "/tmp/out/c")]
        #expect(SummaryText.title(for: report) == "2 Nitro presets written")
        #expect(SummaryText.notes(for: report) == [
            "1 preset left out or approximated at least one setting.",
            "1 preset was not written because a file with the same name exists. Turn on “Replace files that already exist” to overwrite them.",
        ])
    }

    @Test func presetNotesListApproximationsOnly() async throws {
        let ls = try await package("LS")
        let ls002 = try #require(ls.presets.first { $0.preset.name == "002" })
        #expect(ls002.notes.contains { $0.hasPrefix("Levels: ") })
        #expect(ls002.notes.contains { $0.hasPrefix("Selective Color: ") })
        #expect(!ls002.notes.contains { $0.hasPrefix("Light: ") })   // left out, shown as a tag
    }

    #if os(macOS)
    @Test func displayLocationShortensTheHomeFolder() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let path = Platform.displayLocation(of: home.appending(path: "Desktop/Nitro Presets", directoryHint: .isDirectory))
        #expect(path == "~/Desktop/Nitro Presets")
    }
    #endif
}
