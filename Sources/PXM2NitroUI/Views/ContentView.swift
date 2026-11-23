import PXM2NitroKit
import SwiftUI

/// The app's single screen: drop zone → package list → export result.
public struct ContentView: View {
    let session: ConversionSession
    @State private var isImportingPackages = false
    @State private var isChoosingFolder = false
    @State private var isDropTargeted = false
    @State private var expanded: Set<PackageSummary.ID> = []

    /// The session is owned by the app, so menu commands or file opening can reach it later.
    public init(session: ConversionSession) {
        self.session = session
    }

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
            // `add` ignores files while the export result is shown, so refuse the drop.
            guard session.lastExport == nil else { return false }
            add(urls)
            return true
        } isTargeted: { isDropTargeted = $0 }
        .onChange(of: session.packages.map(\.id)) { _, ids in
            expanded.formIntersection(ids)
        }
        .toolbar {
            ToolbarItemGroup {
                Button("Clear All", systemImage: "trash", action: session.reset)
                    .disabled(session.packages.isEmpty && session.loadErrors.isEmpty)
                Button("Add Presets…", systemImage: "plus") { isImportingPackages = true }
                    .disabled(session.lastExport != nil)
            }
        }
    }

    @ViewBuilder private var content: some View {
        if let report = session.lastExport {
            DoneView(report: report, onBack: session.dismissExport, onConvertMore: session.reset)
        } else if session.packages.isEmpty {
            VStack(spacing: 16) {
                LoadErrors(errors: session.loadErrors)
                DropZone(isTargeted: isDropTargeted, isBusy: session.isBusy) { isImportingPackages = true }
            }
            .contentColumn(maxWidth: 880, padding: 24)
        } else {
            PackageList(session: session, expanded: $expanded, isDropTargeted: isDropTargeted) {
                isImportingPackages = true
            }
        }
    }

    private func add(_ urls: [URL]) {
        Task { await session.add(urls) }
    }
}

/// The big empty-state target. Clicking it opens the file picker.
struct DropZone: View {
    let isTargeted: Bool
    let isBusy: Bool
    let onChoose: () -> Void

    var body: some View {
        DropTarget(cornerRadius: 18, lineWidth: 2, isTargeted: isTargeted, action: onChoose) {
            VStack(spacing: 14) {
                IconBadge(systemName: "square.and.arrow.down", tint: .accentColor)
                Text("Drop Photomator or Pixelmator Pro presets")
                    .font(.title2.weight(.semibold))
                Text("Drag .adjustments files here, or click to choose them.\nYou can add several at once.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Group {
                    if isBusy {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Choose Files…")
                            .font(.callout.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .card(cornerRadius: 8)
                    }
                }
                .padding(.top, 8)
            }
            .padding(40)
            .frame(maxHeight: .infinity)
        }
        .accessibilityLabel("Choose Photomator or Pixelmator Pro presets")
    }
}

/// Files from the last drop or pick that could not be read.
struct LoadErrors: View {
    let errors: [LoadError]

    var body: some View {
        if !errors.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(errors) { WarningLabel(text: $0.message) }
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.orange.opacity(0.12), in: .rect(cornerRadius: 10))
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
                DropTarget(cornerRadius: 12, lineWidth: 1.5, isTargeted: isDropTargeted, action: onAdd) {
                    Label("Drop more .adjustments files here, or click to add", systemImage: "square.and.arrow.down")
                        .foregroundStyle(.secondary)
                        .frame(minHeight: 56)
                }
                ForEach(session.packages) { package in
                    PackageCard(package: package, isExpanded: binding(for: package.id)) {
                        session.remove(package.id)
                    }
                }
            }
            .contentColumn(maxWidth: 880, padding: 24)
        }
    }

    private var title: some View {
        Text(SummaryText.listTitle(packages: session.packages.count, presets: session.presetCount))
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
        let presets = session.presetCount, convertible = session.convertibleCount
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text(SummaryText.exportSummary(convertible: convertible, presets: presets))
                    .font(.callout.weight(presets == 0 ? .regular : .medium))
                    .foregroundStyle(presets == 0 ? .secondary : .primary)
                if presets > 0 {
                    Toggle("Replace files that already exist", isOn: $session.replaceExisting)
                        .checkboxToggleStyle()
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
            .disabled(convertible == 0 || session.isBusy)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(.background)
    }
}
