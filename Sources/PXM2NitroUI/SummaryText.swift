import Foundation
import PXM2NitroKit
import UniformTypeIdentifiers

extension UTType {
    /// Photomator / Pixelmator Pro adjustments package (`.adjustments`). The app's Info.plist
    /// imports this type so pickers and drops recognise it.
    public static let photomatorAdjustments = UTType(importedAs: "com.pixelmatorteam.adjustments",
                                                      conformingTo: .package)
}

/// Texts shown on the screens, kept out of the views so they can be tested.
enum SummaryText {
    static func count(_ n: Int, _ singular: String, _ plural: String? = nil) -> String {
        "\(n) \(n == 1 ? singular : plural ?? singular + "s")"
    }

    /// "Collection “BW” · 4 presets"
    static func subtitle(for package: PackageSummary) -> String {
        let presets = count(package.presets.count, "preset")
        let quoted = package.collectionNames.map { "“\($0)”" }
        switch quoted.count {
        case 0: return presets
        case 1: return "Collection \(quoted[0]) · \(presets)"
        default: return "Collections \(quoted.joined(separator: ", ")) · \(presets)"
        }
    }

    /// The line under "4 of 4": how much of the convertible presets carries over.
    static func conversionNote(for package: PackageSummary) -> String {
        let convertible = package.convertibleCount, lossless = package.losslessCount
        let verb = convertible == 1 ? "converts" : "convert"
        if convertible == 0 { return "nothing to convert" }
        if lossless == convertible { return convertible == 1 ? "preset converts exactly" : "presets convert, all exactly" }
        if lossless == 0 { return convertible == 1 ? "preset converts partly" : "presets \(verb), all partly" }
        return "presets \(verb), \(lossless) exactly"
    }

    /// Footer line above the main button.
    static func exportSummary(convertible: Int, presets: Int) -> String {
        if presets == 0 { return "Add presets to see what carries over to Nitro." }
        if convertible == 0 { return "None of these presets can be converted." }
        return "\(count(convertible, "Nitro preset")) will be written"
    }

    static func title(for report: ExportReport) -> String {
        report.written.isEmpty ? "No Nitro presets written" : "\(count(report.written.count, "Nitro preset")) written"
    }
}

extension BlockOutcome.Status {
    var label: String {
        switch self {
        case .carriedOver: "carried over"
        case .approximated: "approximate"
        case .leftOut: "left out"
        }
    }
}
