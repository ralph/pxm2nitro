import SwiftUI
#if os(macOS)
import AppKit
#endif

/// What the export wrote, where, and how to get the presets into Nitro.
struct DoneView: View {
    let report: ExportReport
    let onShowDetails: () -> Void
    let onConvertMore: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: report.written.isEmpty ? "exclamationmark" : "checkmark")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(report.written.isEmpty ? Color.orange : Color.accentColor)
                    .frame(width: 72, height: 72)
                    .background((report.written.isEmpty ? Color.orange : Color.accentColor).opacity(0.12), in: .circle)
                    .accessibilityHidden(true)
                Text(SummaryText.title(for: report)).font(.title.weight(.semibold))
                Label(Self.displayPath(of: report.folder), systemImage: "folder")
                    .font(.callout.monospaced())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.background, in: .rect(cornerRadius: 8))
                    .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary) }
                    .textSelection(.enabled)

                notes

                HStack(spacing: 10) {
                    #if os(macOS)
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting(report.written.isEmpty ? [report.folder] : report.written)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    #endif
                    Button("Convert More", action: onConvertMore)
                        .buttonStyle(.bordered)
                }
                .controlSize(.large)
                .padding(.top, 6)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Using them in Nitro").font(.headline)
                    Text("1. Copy the .nitropreset files into Nitro’s presets folder.\n2. Restart Nitro. The presets show up under their Photomator collection name.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.background, in: .rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary) }
                .padding(.top, 14)
            }
            .padding(40)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder private var notes: some View {
        VStack(spacing: 8) {
            if report.writtenWithLosses > 0 {
                let all = report.writtenWithLosses == report.written.count
                HStack(spacing: 4) {
                    Text(all ? "Every preset left out or approximated at least one setting."
                             : "\(SummaryText.count(report.writtenWithLosses, "preset")) left out or approximated at least one setting.")
                    Button("See what was left out", action: onShowDetails).buttonStyle(.borderless)
                }
            }
            if !report.existing.isEmpty {
                Text("\(SummaryText.count(report.existing.count, "preset was", "presets were")) not written because a file with the same name exists. Turn on “Replace files that already exist” to overwrite them.")
                Button("Back to the List", action: onShowDetails).buttonStyle(.borderless)
            }
            if report.nothingToConvert > 0 {
                Text("\(SummaryText.count(report.nothingToConvert, "preset had", "presets had")) nothing Nitro can use.")
            }
            ForEach(Array(report.failures.enumerated()), id: \.offset) { _, failure in
                Label("\(failure.presetTitle): \(failure.message)", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// The folder path with the home folder shortened to `~`.
    static func displayPath(of folder: URL) -> String {
        var path = folder.path(percentEncoded: false)
        if path.count > 1, path.hasSuffix("/") { path.removeLast() }
        #if os(macOS)
        // In the sandbox NSHomeDirectory() is the container, so ask for the real home folder.
        if let entry = getpwuid(getuid()), let home = entry.pointee.pw_dir.map({ String(cString: $0) }),
           path == home || path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count)
        }
        #endif
        return path
    }
}
