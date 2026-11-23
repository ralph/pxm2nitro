import PXM2NitroKit
import SwiftUI

/// Lays out its children left to right and wraps them onto new lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(maxWidth: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = arrange(maxWidth: bounds.width, subviews: subviews).frames
        for (subview, frame) in zip(subviews, frames) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                          proposal: ProposedViewSize(frame.size))
        }
    }

    private func arrange(maxWidth: CGFloat, subviews: Subviews) -> (frames: [CGRect], size: CGSize) {
        var frames: [CGRect] = []
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0, width: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            width = max(width, x - spacing)
        }
        return (frames, CGSize(width: width, height: frames.isEmpty ? 0 : y + lineHeight))
    }
}

/// One adjustment and how it converts. The symbol carries the status, so it does not rely on colour.
struct BlockChip: View {
    let outcome: BlockOutcome

    var body: some View {
        HStack(spacing: 4) {
            symbol.foregroundStyle(tint)
            Text(outcome.block.displayName)
        }
        .font(.caption.weight(outcome.status == .leftOut ? .regular : .medium))
        .foregroundStyle(outcome.status == .leftOut ? .secondary : .primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(tint.opacity(outcome.status == .leftOut ? 0.12 : 0.14), in: .rect(cornerRadius: 6))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(outcome.block.displayName), \(outcome.status.label)")
    }

    @ViewBuilder private var symbol: some View {
        switch outcome.status {
        case .carriedOver: Image(systemName: "checkmark").imageScale(.small)
        case .approximated: Text("≈")
        case .leftOut: Image(systemName: "minus").imageScale(.small)
        }
    }

    private var tint: Color {
        switch outcome.status {
        case .carriedOver: .accentColor
        case .approximated: .orange
        case .leftOut: .gray
        }
    }
}

/// The adjustments of a preset or package: converted ones first, then those left out.
struct BlockChips: View {
    let outcomes: [BlockOutcome]

    var body: some View {
        let converted = outcomes.filter { $0.status != .leftOut }.sorted { $0.status < $1.status }
        let leftOut = outcomes.filter { $0.status == .leftOut }
        FlowLayout {
            ForEach(converted, id: \.block) { BlockChip(outcome: $0) }
            if !converted.isEmpty, !leftOut.isEmpty {
                Divider().frame(height: 16).padding(.horizontal, 4).accessibilityHidden(true)
            }
            ForEach(leftOut, id: \.block) { BlockChip(outcome: $0) }
        }
    }
}

/// Explains the three tag kinds.
struct BlockLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            ForEach([BlockOutcome.Status.carriedOver, .approximated, .leftOut], id: \.self) {
                LegendItem(status: $0)
            }
        }
    }
}

private struct LegendItem: View {
    let status: BlockOutcome.Status

    var body: some View {
        HStack(spacing: 4) {
            switch status {
            case .carriedOver: Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
            case .approximated: Text("≈").foregroundStyle(.orange)
            case .leftOut: Image(systemName: "minus").foregroundStyle(.gray)
            }
            Text(status.label.prefix(1).uppercased() + status.label.dropFirst())
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize()
    }
}
