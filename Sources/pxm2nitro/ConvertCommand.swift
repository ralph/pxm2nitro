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
        let outputDirectory = URL(filePath: output, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        var written = 0, skipped = 0, failed = false
        var usedFileNames = Set<String>()
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
                let result = Converter.convert(preset)
                guard let nitro = result.preset else {
                    print("  – \(preset.title): nothing to convert")
                    printDiagnostics(result.diagnostics)
                    skipped += 1
                    continue
                }
                let fileName = uniqueFileName(for: nitro.name, used: &usedFileNames)
                let file = outputDirectory.appending(path: fileName)
                if !overwrite, FileManager.default.fileExists(atPath: file.path) {
                    printError("  \(preset.title): \(fileName) exists (use --overwrite)")
                    skipped += 1
                    continue
                }
                try nitro.encoded().write(to: file, options: .atomic)
                print("  ✓ \(preset.title) → \(fileName)")
                printDiagnostics(result.diagnostics)
                written += 1
            }
        }
        print("\(written) preset(s) written to \(outputDirectory.path), \(skipped) skipped.")
        if failed { throw ExitCode.failure }
    }

    private func printDiagnostics(_ diagnostics: [ConversionDiagnostic]) {
        for diagnostic in diagnostics {
            print("      \(diagnostic)")
        }
    }

    /// A file name from the preset name, made safe and unique within this run.
    private func uniqueFileName(for name: String, used: inout Set<String>) -> String {
        let base = name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        var candidate = "\(base).\(NitroPreset.fileExtension)"
        var counter = 2
        while !used.insert(candidate.lowercased()).inserted {
            candidate = "\(base) \(counter).\(NitroPreset.fileExtension)"
            counter += 1
        }
        return candidate
    }
}

func printError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}
