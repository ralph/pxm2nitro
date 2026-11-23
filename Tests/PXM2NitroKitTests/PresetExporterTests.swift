import Foundation
@testable import PXM2NitroKit
import PXM2NitroTestSupport
import Testing

struct PresetExporterTests {
    @Test func writesConvertiblePresets() throws {
        let directory = SampleFiles.temporaryFolder()
        defer { try? FileManager.default.removeItem(at: directory) }
        var exporter = PresetExporter(outputDirectory: directory)

        let entry = try exporter.export(try Fixtures.photomatorPreset("BW", "001"))
        let file = directory.appending(path: "BW 001.nitropreset")
        #expect(entry.outcome == .written(file))
        #expect(try NitroPreset(data: Data(contentsOf: file)).name == "BW 001")
        #expect(!entry.diagnostics.isEmpty)
    }

    @Test func respectsExistingFilesUnlessOverwriting() throws {
        let directory = SampleFiles.temporaryFolder()
        defer { try? FileManager.default.removeItem(at: directory) }
        let preset = try Fixtures.photomatorPreset("BW", "001")
        let file = directory.appending(path: "BW 001.nitropreset")

        var first = PresetExporter(outputDirectory: directory)
        _ = try first.export(preset)
        var second = PresetExporter(outputDirectory: directory)
        #expect(try second.export(preset).outcome == .fileExists(file))
        var third = PresetExporter(outputDirectory: directory, overwrite: true)
        #expect(try third.export(preset).outcome == .written(file))
    }

    @Test func keepsNamesUniqueWithinOneExport() throws {
        let directory = SampleFiles.temporaryFolder()
        defer { try? FileManager.default.removeItem(at: directory) }
        var exporter = PresetExporter(outputDirectory: directory)
        let preset = try Fixtures.photomatorPreset("BW", "001")

        _ = try exporter.export(preset)
        let second = directory.appending(path: "BW 001 2.nitropreset")
        #expect(try exporter.export(preset).outcome == .written(second))
        #expect(try NitroPreset(data: Data(contentsOf: second)).name == "BW 001 2")
    }

    @Test func deduplicatesLongNamesWithoutLosingTheCounter() throws {
        let directory = SampleFiles.temporaryFolder()
        defer { try? FileManager.default.removeItem(at: directory) }
        var exporter = PresetExporter(outputDirectory: directory)
        let bw = try Fixtures.photomatorPreset("BW", "001")
        let longName = String(repeating: "x", count: 250)
        let preset = Fixtures.preset(longName, bw.adjustments)

        guard case .written(let first) = try exporter.export(preset).outcome,
              case .written(let second) = try exporter.export(preset).outcome
        else { Issue.record("both exports should be written"); return }
        #expect(first != second)
        #expect(second.lastPathComponent.hasSuffix(" 2.nitropreset"))
        #expect(second.lastPathComponent.utf8.count <= 255)
    }

    @Test func skipsPresetsWithNothingToConvert() throws {
        let directory = SampleFiles.temporaryFolder()
        defer { try? FileManager.default.removeItem(at: directory) }
        var exporter = PresetExporter(outputDirectory: directory)
        let preset = Fixtures.preset("Empty", nil)
        #expect(try exporter.export(preset).outcome == .nothingToConvert)
        #expect(!FileManager.default.fileExists(atPath: directory.path))
    }

    @Test func sanitisesFileNames() {
        #expect(PresetExporter.fileName(for: "A/B: C") == "A-B- C.nitropreset")
        #expect(PresetExporter.fileName(for: ".hidden") == "hidden.nitropreset")
        #expect(PresetExporter.fileName(for: "  ") == "Untitled.nitropreset")
        #expect(PresetExporter.fileName(for: String(repeating: "x", count: 300)).utf8.count
            == PresetExporter.maxStemLength + ".nitropreset".utf8.count)
    }
}
