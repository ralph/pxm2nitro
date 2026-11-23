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
                BlockChips(outcomes: package.blocks)
            }
            if !package.failures.isEmpty {
                Label(SummaryText.count(package.failures.count, "preset file") + " could not be read",
                      systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                Label(isExpanded ? "Hide Details" : "Show Details",
                      systemImage: isExpanded ? "chevron.up" : "chevron.down")
                    .labelStyle(TrailingIconLabelStyle())
            }
            .buttonStyle(.borderless)
            .font(.callout.weight(.medium))

            if isExpanded {
                PresetDetails(package: package)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(.background, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isExpanded ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.1))
        }
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

/// One row per preset: Nitro file name, converted and left-out adjustments.
struct PresetDetails: View {
    let package: PackageSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            row(preset: Text("Preset"), converted: Text("Carried over"), leftOut: Text("Left out"))
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
            Divider()
            ForEach(Array(package.presets.enumerated()), id: \.offset) { _, preset in
                row(
                    preset: VStack(alignment: .leading, spacing: 2) {
                        Text(preset.preset.name).font(.callout.weight(.medium))
                        if let file = preset.nitroFileName {
                            Text("→ \(file)").font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text("Nothing to convert").font(.caption).foregroundStyle(.orange)
                        }
                    },
                    converted: BlockChips(outcomes: preset.result.blocks.filter { $0.status != .leftOut }),
                    leftOut: BlockChips(outcomes: preset.result.blocks.filter { $0.status == .leftOut }))
                    .padding(.vertical, 10)
                    .help(preset.result.diagnostics.map(\.description).joined(separator: "\n"))
                Divider()
            }
            ForEach(package.failures, id: \.file) { failure in
                Label("\(failure.file.lastPathComponent) could not be read: \(failure.reason)",
                      systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.vertical, 8)
            }
            notes.padding(.top, 12)
        }
    }

    private func row(preset: some View, converted: some View, leftOut: some View) -> some View {
        HStack(alignment: .top, spacing: 16) {
            preset.frame(width: 170, alignment: .leading)
            converted.frame(maxWidth: .infinity, alignment: .leading)
            leftOut.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var notes: some View {
        VStack(alignment: .leading, spacing: 6) {
            if package.blocks.contains(where: { $0.status == .approximated }) {
                Text("**≈ Approximate** settings are converted, but not exactly. Selective Color becomes Nitro HSL with a strength that isn’t calibrated yet, so colour shifts may come out stronger or weaker than in Photomator.")
            }
            if package.blocks.contains(where: { $0.status == .leftOut }) {
                Text("**Left out** settings have no Nitro counterpart in this converter yet. The rest of the preset is still written.")
            }
            #if os(macOS)
            Text("Hover over a preset to see exactly what changed.")
            #endif
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Title first, icon after it ("Show Details ⌄").
struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon.imageScale(.small)
        }
    }
}
