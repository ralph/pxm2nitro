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
        for path in packages {
            let presets = try AdjustmentsPackage.load(from: URL(filePath: path))
            print("\(path): \(presets.count) preset(s)")
            for preset in presets {
                let title = [preset.collectionName, preset.name].compactMap { $0 }.joined(separator: " / ")
                guard let adjustments = preset.adjustments else {
                    print("  \(title): no colour adjustments")
                    continue
                }
                let blocks = adjustments.enabledBlocks.map { "\($0)" }.joined(separator: ", ")
                var line = "  \(title) [v\(adjustments.formatVersion)]: \(blocks)"
                if adjustments.intensity != 1 {
                    line += " (intensity \(adjustments.intensity))"
                }
                print(line)
                if !preset.otherPropertyKeys.isEmpty {
                    print("    other properties: \(preset.otherPropertyKeys.joined(separator: ", "))")
                }
            }
        }
    }
}
