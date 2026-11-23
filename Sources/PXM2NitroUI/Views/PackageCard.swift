import PXM2NitroKit
import SwiftUI

/// One package: how many presets convert, which adjustments carry over, and optional details.
struct PackageCard: View {
    let package: PackageSummary
    @Binding var isExpanded: Bool
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            if !package.blocks.isEmpty {
                BlockChips(groups: [package.converted, package.leftOut])
            }
            if !package.failures.isEmpty {
                WarningLabel(text: SummaryText.unreadableFiles(package.failures.count)).font(.callout)
            }
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Text(isExpanded ? "Hide Details" : "Show Details")
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down").imageScale(.small)
                }
            }
            .buttonStyle(.borderless)
            .font(.callout.weight(.medium))
            .accessibilityValue(isExpanded ? "expanded" : "collapsed")

            if isExpanded {
                PresetDetails(package: package)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .card(cornerRadius: 14, border: isExpanded ? .accentColor.opacity(0.35) : .primary.opacity(0.12))
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: "folder")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 40, height: 40)
                .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 9))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(package.fileName).font(.headline)
                Text(SummaryText.subtitle(for: package)).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(package.convertibleCount) of \(package.presets.count)")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                Text(SummaryText.conversionNote(for: package))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Button(action: onRemove) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Remove \(package.fileName)")
            .accessibilityLabel("Remove \(package.fileName)")
        }
    }
}

/// One row per preset: Nitro file name, converted and left-out adjustments, and what changed.
struct PresetDetails: View {
    private static let nameWidth: CGFloat = 170
    private static let columnSpacing: CGFloat = 16

    let package: PackageSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            row(preset: Text("Preset"),
                converted: Text("Converted"),
                leftOut: Text(BlockOutcome.Status.leftOut.title))
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
            Divider()
            // Offsets as IDs: preset IDs come from the files and need not be unique.
            ForEach(Array(package.presets.enumerated()), id: \.offset) { _, preset in
                VStack(alignment: .leading, spacing: 6) {
                    row(preset: name(of: preset),
                        converted: BlockChips(groups: [preset.converted]),
                        leftOut: BlockChips(groups: [preset.leftOut]))
                    ForEach(preset.notes, id: \.self) { note in
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, Self.nameWidth + Self.columnSpacing)
                    }
                }
                .padding(.vertical, 10)
                Divider()
            }
            ForEach(package.failures, id: \.file) { failure in
                WarningLabel(text: "\(failure.file.lastPathComponent) could not be read: \(failure.reason)")
                    .font(.caption)
                    .padding(.vertical, 8)
            }
            legendNotes.padding(.top, 12)
        }
    }

    private func name(of preset: PresetSummary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(preset.preset.name).font(.callout.weight(.medium))
            if let file = preset.nitroFileName {
                Text("→ \(file)").font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Nothing to convert").font(.caption).foregroundStyle(.orange)
            }
        }
    }

    private func row(preset: some View, converted: some View, leftOut: some View) -> some View {
        HStack(alignment: .top, spacing: Self.columnSpacing) {
            preset.frame(width: Self.nameWidth, alignment: .leading)
            converted.frame(maxWidth: .infinity, alignment: .leading)
            leftOut.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var legendNotes: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !package.converted.allSatisfy({ $0.status == .carriedOver }) {
                Text("\(Text("≈ Approximate").bold()) settings are converted, but not exactly; each preset lists what changed.")
            }
            if !package.leftOut.isEmpty {
                Text("\(Text("Left out").bold()) settings have no Nitro counterpart in this converter yet. The rest of the preset is still written.")
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
}
