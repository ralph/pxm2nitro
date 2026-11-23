import SwiftUI

/// What the export wrote, where, and how to get the presets into Nitro.
struct DoneView: View {
    let report: ExportReport
    let onBack: () -> Void
    let onConvertMore: () -> Void

    var body: some View {
        let tint = report.written.isEmpty ? Color.orange : Color.accentColor
        ScrollView {
            VStack(spacing: 18) {
                IconBadge(systemName: report.written.isEmpty ? "exclamationmark" : "checkmark", tint: tint)
                Text(SummaryText.title(for: report)).font(.title.weight(.semibold))
                Label(Platform.displayLocation(of: report.folder), systemImage: "folder")
                    .font(.callout.monospaced())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .card(cornerRadius: 8)
                    .textSelection(.enabled)

                notes

                HStack(spacing: 10) {
                    if let reveal = Platform.revealFiles {
                        Button("Show in \(Platform.fileBrowserName)") {
                            reveal(report.written.isEmpty ? [report.folder] : report.written)
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                    }
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
                .card(cornerRadius: 12)
                .padding(.top, 14)
            }
            .contentColumn(maxWidth: 560, padding: 40)
        }
    }

    private var notes: some View {
        VStack(spacing: 8) {
            ForEach(SummaryText.notes(for: report), id: \.self) { Text($0) }
            if report.writtenWithLosses > 0 || !report.existing.isEmpty || !report.failures.isEmpty {
                Button("Back to the List", action: onBack).buttonStyle(.borderless)
            }
            ForEach(Array(report.failures.enumerated()), id: \.offset) { _, failure in
                WarningLabel(text: "\(failure.presetTitle): \(failure.message)")
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }
}
