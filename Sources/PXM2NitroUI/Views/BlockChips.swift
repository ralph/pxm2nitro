import PXM2NitroKit
import SwiftUI

/// Lays out its children left to right and wraps them onto new lines.
struct FlowLayout: Layout {
    private static let spacing: CGFloat = 6

    /// Child sizes do not depend on the proposal, so they are measured once per update.
    func makeCache(subviews: Subviews) -> [CGSize] {
        subviews.map { $0.sizeThatFits(.unspecified) }
    }

    func updateCache(_ cache: inout [CGSize], subviews: Subviews) {
        cache = makeCache(subviews: subviews)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout [CGSize]) -> CGSize {
        arrange(cache, maxWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout [CGSize]) {
        for (subview, frame) in zip(subviews, arrange(cache, maxWidth: bounds.width).frames) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                          proposal: ProposedViewSize(frame.size))
        }
    }

    private func arrange(_ sizes: [CGSize], maxWidth: CGFloat) -> (frames: [CGRect], size: CGSize) {
        var frames: [CGRect] = []
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0, width: CGFloat = 0
        for size in sizes {
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += lineHeight + Self.spacing
                lineHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + Self.spacing
            lineHeight = max(lineHeight, size.height)
            width = max(width, x - Self.spacing)
        }
        return (frames, CGSize(width: width, height: frames.isEmpty ? 0 : y + lineHeight))
    }
}

/// One adjustment and how it converts.
struct BlockChip: View {
    let outcome: BlockOutcome
    /// Shown as a tooltip, e.g. why the adjustment was left out.
    var reason = ""

    var body: some View {
        HStack(spacing: 4) {
            StatusMark(status: outcome.status)
            Text(outcome.block.displayName)
        }
        .font(.caption.weight(outcome.status == .leftOut ? .regular : .medium))
        .foregroundStyle(outcome.status == .leftOut ? .secondary : .primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(outcome.status.tint.opacity(0.13), in: .rect(cornerRadius: 6))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(outcome.block.displayName), \(outcome.status.label)")
        .help(reason)
        .accessibilityHint(reason)
    }
}

/// Tag groups in one wrapping row, with a divider between non-empty groups.
struct BlockChips: View {
    let groups: [[BlockOutcome]]
    var reasons: [PhotomatorBlock: String] = [:]

    var body: some View {
        let groups = groups.filter { !$0.isEmpty }
        FlowLayout {
            ForEach(groups.indices, id: \.self) { index in
                if index > 0 {
                    // Not a `Divider`: outside a stack it draws horizontally.
                    Rectangle().fill(.separator).frame(width: 1, height: 16)
                        .padding(.horizontal, 4).accessibilityHidden(true)
                }
                ForEach(groups[index], id: \.block) { BlockChip(outcome: $0, reason: reasons[$0.block, default: ""]) }
            }
        }
    }
}

/// Explains the three tag kinds.
struct BlockLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            ForEach(BlockOutcome.Status.allCases, id: \.self) { status in
                HStack(spacing: 4) {
                    StatusMark(status: status)
                    Text(status.title)
                }
                .fixedSize()
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
