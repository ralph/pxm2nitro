import Foundation
import PXM2NitroKit

/// Texts with counts shown on the screens, kept out of the views so they can be tested.
enum SummaryText {
    static func count(_ n: Int, _ singular: String, _ plural: String? = nil) -> String {
        "\(n) \(n == 1 ? singular : plural ?? singular + "s")"
    }

    /// "3 packages · 19 presets"
    static func listTitle(packages: Int, presets: Int) -> String {
        "\(count(packages, "package")) · \(count(presets, "preset"))"
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
        switch (convertible, lossless) {
        case (0, _): return "nothing to convert"
        case (1, 1): return "preset converts exactly"
        case (1, _): return "preset converts partly"
        case (_, convertible): return "presets convert, all exactly"
        case (_, 0): return "presets convert, all partly"
        default: return "presets convert, \(lossless) exactly"
        }
    }

    static func unreadableFiles(_ n: Int) -> String {
        "\(count(n, "preset file")) could not be read"
    }

    /// Footer line next to the main button.
    static func exportSummary(convertible: Int, presets: Int) -> String {
        if presets == 0 { return "Add presets to see what carries over to Nitro." }
        if convertible == 0 { return "None of these presets can be converted." }
        return "\(count(convertible, "Nitro preset")) will be written"
    }

    static func title(for report: ExportReport) -> String {
        report.written.isEmpty ? "No Nitro presets written" : "\(count(report.written.count, "Nitro preset")) written"
    }

    /// Notes under the export result, most important first.
    static func notes(for report: ExportReport) -> [String] {
        var notes: [String] = []
        if report.writtenWithLosses > 0 {
            notes.append(report.writtenWithLosses == report.written.count
                ? "Every preset left out or approximated at least one setting."
                : "\(count(report.writtenWithLosses, "preset")) left out or approximated at least one setting.")
        }
        if !report.existing.isEmpty {
            notes.append("\(count(report.existing.count, "preset was", "presets were")) not written because a file with the same name exists. Turn on “Replace files that already exist” to overwrite them.")
        }
        if report.nothingToConvert > 0 {
            notes.append("\(count(report.nothingToConvert, "preset had", "presets had")) nothing Nitro can use.")
        }
        return notes
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

    /// `label` with a capital first letter, for headings and the legend.
    var title: String { label.prefix(1).uppercased() + label.dropFirst() }
}
