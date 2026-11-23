import PXM2NitroKit
import SwiftUI

extension BlockOutcome.Status {
    var tint: Color {
        switch self {
        case .carriedOver: .accentColor
        case .approximated: .orange
        case .leftOut: .gray
        }
    }
}

/// The mark for a status, used by the tags and the legend. It carries the status by shape,
/// so the tags do not rely on colour alone.
struct StatusMark: View {
    let status: BlockOutcome.Status

    var body: some View {
        Group {
            switch status {
            case .carriedOver: Image(systemName: "checkmark").imageScale(.small)
            case .approximated: Text(verbatim: "≈")
            case .leftOut: Image(systemName: "minus").imageScale(.small)
            }
        }
        .foregroundStyle(status.tint)
        .accessibilityHidden(true)
    }
}

/// The big round icon at the top of the empty and result screens.
struct IconBadge: View {
    let systemName: String
    let tint: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 30, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 72, height: 72)
            .background(tint.opacity(0.12), in: .circle)
            .accessibilityHidden(true)
    }
}

/// A clickable area with a dashed border that lights up while files are dragged over the window.
struct DropTarget<Label: View>: View {
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let isTargeted: Bool
    let action: () -> Void
    @ViewBuilder let label: Label

    var body: some View {
        Button(action: action) {
            label
                .frame(maxWidth: .infinity)
                .background(.background, in: .rect(cornerRadius: cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(isTargeted ? Color.accentColor : Color.secondary.opacity(0.5),
                                      style: StrokeStyle(lineWidth: lineWidth, dash: [8, 6]))
                }
                .contentShape(.rect(cornerRadius: cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

struct WarningLabel: View {
    let text: String

    var body: some View {
        Label(text, systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
    }
}

extension View {
    /// Opaque rounded background with a hairline border.
    func card(cornerRadius: CGFloat, border: Color = .primary.opacity(0.12)) -> some View {
        background(.background, in: .rect(cornerRadius: cornerRadius))
            .overlay { RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(border) }
    }

    /// A centred column of at most `maxWidth`.
    func contentColumn(maxWidth: CGFloat, padding: CGFloat) -> some View {
        self.padding(padding).frame(maxWidth: maxWidth).frame(maxWidth: .infinity)
    }
}
