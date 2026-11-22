import ArgumentParser
import Foundation
import PXM2NitroKit

struct InspectCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "inspect",
        abstract: "List the presets in Photomator .adjustments packages and their enabled adjustments."
    )

    @Argument(help: "One or more .adjustments packages.", completion: .directory)
    var packages: [String]

    func run() throws {
        var hadError = false
        for path in packages {
            let package: LoadedPackage
            do {
                package = try AdjustmentsPackage.load(from: URL(filePath: path))
            } catch {
                FileHandle.standardError.write(Data("error: \(error)\n".utf8))
                hadError = true
                continue
            }
            print("\(path): \(package.presets.count) preset(s)")
            for preset in package.presets {
                guard let adjustments = preset.adjustments else {
                    print("  \(preset.title): no colour adjustments")
                    continue
                }
                let blocks = adjustments.enabledBlocks.map(\.displayName).joined(separator: ", ")
                var line = "  \(preset.title) [v\(adjustments.formatVersion)]: \(blocks)"
                if adjustments.intensity != 1 {
                    line += " (intensity \(adjustments.intensity))"
                }
                print(line)
                if !preset.otherPropertyKeys.isEmpty {
                    print("    other properties: \(preset.otherPropertyKeys.joined(separator: ", "))")
                }
            }
            for failure in package.failures {
                print("  ⚠️ \(failure.file.lastPathComponent): \(failure.reason)")
            }
        }
        if hadError { throw ExitCode.failure }
    }
}
