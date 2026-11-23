import PXM2NitroKit
import SwiftUI

/// The app's single screen: drop zone → package list → export result.
public struct ContentView: View {
    @State private var session = ConversionSession()
    @State private var isImportingPackages = false
    @State private var isChoosingFolder = false
    @State private var isDropTargeted = false
    @State private var expanded: Set<PackageSummary.ID> = []

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Two file importers must sit on different views to both work.
                .fileImporter(isPresented: $isChoosingFolder, allowedContentTypes: [.folder]) { result in
                    guard case .success(let folder) = result else { return }
                    Task { await session.export(to: folder) }
                }
            if session.lastExport == nil {
                Divider()
                FooterBar(session: session) { isChoosingFolder = true }
            }
        }
        .background(.background.secondary)
        .fileImporter(isPresented: $isImportingPackages, allowedContentTypes: [.photomatorAdjustments],
                      allowsMultipleSelection: true) { result in
            guard case .success(let urls) = result else { return }
            add(urls)
        }
        .dropDestination(for: URL.self) { urls, _ in
            add(urls)
            return true
        } isTargeted: { isDropTargeted = $0 }
        .toolbar {
            ToolbarItemGroup {
                Button("Clear All", systemImage: "trash") {
                    expanded = []
                    session.reset()
                }
                .disabled(session.packages.isEmpty)
                Button("Add Presets…", systemImage: "plus") { isImportingPackages = true }
                    .disabled(session.lastExport != nil)
            }
        }
        #if os(macOS)
        .navigationSubtitle("Photomator to Nitro")
        #endif
    }

    @ViewBuilder private var content: some View {
        if let report = session.lastExport {
            DoneView(report: report,
                     onShowDetails: { session.dismissExport() },
                     onConvertMore: {
                         expanded = []
                         session.reset()
                     })
        } else if session.packages.isEmpty {
            VStack(spacing: 16) {
                LoadErrors(errors: session.loadErrors)
                DropZone(isTargeted: isDropTargeted, isBusy: session.isBusy) { isImportingPackages = true }
            }
            .padding(24)
            .frame(maxWidth: 880)
        } else {
            PackageList(session: session, expanded: $expanded, isDropTargeted: isDropTargeted) {
                isImportingPackages = true
            }
        }
    }

    private func add(_ urls: [URL]) {
        guard session.lastExport == nil else { return }
        Task { await session.add(urls) }
    }
}

/// The big empty-state target. Clicking it opens the file picker.
struct DropZone: View {
    let isTargeted: Bool
    let isBusy: Bool
    let onChoose: () -> Void

    var body: some View {
        Button(action: onChoose) {
            VStack(spacing: 14) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.tint)
                    .frame(width: 72, height: 72)
                    .background(Color.accentColor.opacity(0.12), in: .circle)
                Text("Drop Photomator or Pixelmator Pro presets")
                    .font(.title2.weight(.semibold))
                Text("Drag .adjustments files here, or click to choose them.\nYou can add several at once.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                if isBusy {
                    ProgressView().controlSize(.small).padding(.top, 8)
                } else {
                    Text("Choose Files…")
                        .font(.callout.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.background, in: .rect(cornerRadius: 8))
                        .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(.quaternary) }
                        .padding(.top, 8)
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background, in: .rect(cornerRadius: 18))
            .overlay { DashedBorder(cornerRadius: 18, lineWidth: 2, isHighlighted: isTargeted) }
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Choose Photomator or Pixelmator Pro presets")
    }
}

struct DashedBorder: View {
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let isHighlighted: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(isHighlighted ? Color.accentColor : Color.secondary.opacity(0.5),
                          style: StrokeStyle(lineWidth: lineWidth, dash: [8, 6]))
    }
}

/// Files from the last drop or pick that could not be read.
struct LoadErrors: View {
    let errors: [LoadError]

    var body: some View {
        if !errors.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(errors) { Text($0.message) }
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.orange.opacity(0.12), in: .rect(cornerRadius: 10))
            .overlay(alignment: .topTrailing) {
                Image(systemName: "exclamationmark.triangle").foregroundStyle(.orange).padding(12)
            }
        }
    }
}

/// The loaded packages, a smaller drop target for more, and the legend.
struct PackageList: View {
    let session: ConversionSession
    @Binding var expanded: Set<PackageSummary.ID>
    let isDropTargeted: Bool
    let onAdd: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) { title; Spacer(); BlockLegend() }
                    VStack(alignment: .leading, spacing: 8) { title; BlockLegend() }
                }
                LoadErrors(errors: session.loadErrors)
                Button(action: onAdd) {
                    Label("Drop more .adjustments files here, or click to add", systemImage: "square.and.arrow.down")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(.background, in: .rect(cornerRadius: 12))
                        .overlay { DashedBorder(cornerRadius: 12, lineWidth: 1.5, isHighlighted: isDropTargeted) }
                        .contentShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                ForEach(session.packages) { package in
                    PackageCard(package: package, isExpanded: binding(for: package.id)) {
                        expanded.remove(package.id)
                        session.remove(package.id)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 880)
            .frame(maxWidth: .infinity)
        }
    }

    private var title: some View {
        Text("\(SummaryText.count(session.packages.count, "package")) · \(SummaryText.count(session.presetCount, "preset"))")
            .font(.title3.weight(.semibold))
    }

    private func binding(for id: PackageSummary.ID) -> Binding<Bool> {
        Binding { expanded.contains(id) } set: { isOn in
            if isOn { expanded.insert(id) } else { expanded.remove(id) }
        }
    }
}

/// Summary, the replace option and the main button.
struct FooterBar: View {
    @Bindable var session: ConversionSession
    let onChooseFolder: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text(SummaryText.exportSummary(convertible: session.convertibleCount, presets: session.presetCount))
                    .font(.callout.weight(session.presetCount == 0 ? .regular : .medium))
                    .foregroundStyle(session.presetCount == 0 ? .secondary : .primary)
                if session.presetCount > 0 {
                    Toggle("Replace files that already exist", isOn: $session.replaceExisting)
                        #if os(macOS)
                        .toggleStyle(.checkbox)
                        #endif
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if session.isBusy { ProgressView().controlSize(.small) }
            Button(action: onChooseFolder) {
                Label("Choose Output Folder…", systemImage: "folder")
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
            .disabled(session.convertibleCount == 0 || session.isBusy)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.background)
    }
}
