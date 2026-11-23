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

    @Test func displayPathShortensTheHomeFolder() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let path = DoneView.displayPath(of: home.appending(path: "Desktop/Nitro Presets", directoryHint: .isDirectory))
        #expect(path == "~/Desktop/Nitro Presets")
    }
}
