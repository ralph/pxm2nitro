import ArgumentParser
import PXM2NitroKit

@main
struct PXM2NitroCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pxm2nitro",
        abstract: "Convert Photomator / Pixelmator Pro adjustment presets to Nitro presets.",
        version: PXM2Nitro.version,
        subcommands: [ConvertCommand.self, InspectCommand.self]
    )
}
