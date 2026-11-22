import ArgumentParser
import Foundation
import PXM2NitroKit

struct ConvertCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "convert",
        abstract: "Convert Photomator .adjustments packages to Nitro presets.",
        discussion: """
            Writes one .nitropreset per convertible preset into the output folder. Copy the files \
            into Nitro's preset folder and restart Nitro:
            ~/Library/Group Containers/group.com.gentlemencoders.nitro/Library/Application Support/My Preset
            """
    )

    @Argument(help: "One or more .adjustments packages.", completion: .directory)
    var packages: [String]

    @Option(name: .shortAndLong, help: "Folder to write the .nitropreset files to.", completion: .directory)
    var output: String

    @Flag(help: "Replace existing files in the output folder.")
    var overwrite = false

    func run() throws {
        var exporter = PresetExporter(outputDirectory: URL(filePath: output, directoryHint: .isDirectory),
                                      overwrite: overwrite)
        var written = 0, nothingToConvert = 0, existing = 0, failed = false
        for path in packages {
            let package: LoadedPackage
            do {
                package = try AdjustmentsPackage.load(from: URL(filePath: path))
            } catch {
                printError("\(path): \(error)")
                failed = true
                continue
            }
            print("\(path):")
            for failure in package.failures {
                printError("  \(failure.file.lastPathComponent): \(failure.reason)")
                failed = true
            }
            for preset in package.presets {
                let entry: PresetExporter.Entry
                do {
                    entry = try exporter.export(preset)
                } catch {
                    printError("  \(preset.title): \(error)")
                    failed = true
                    continue
                }
                switch entry.outcome {
                case .written(let file):
                    print("  ✓ \(preset.title) → \(file.lastPathComponent)")
                    written += 1
                case .fileExists(let file):
                    printError("  \(preset.title): \(file.lastPathComponent) exists (use --overwrite)")
                    existing += 1
                case .nothingToConvert:
                    print("  – \(preset.title): nothing to convert")
                    nothingToConvert += 1
                }
                for diagnostic in entry.diagnostics {
                    print("      \(diagnostic)")
                }
            }
        }
        print("\(written) written to \(exporter.outputDirectory.path), "
              + "\(nothingToConvert) with nothing to convert, \(existing) already existing.")
        if failed { throw ExitCode.failure }
    }
}

func printError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}
