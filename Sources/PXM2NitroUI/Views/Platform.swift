import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#endif

/// Everything the shared views do differently on macOS and iOS/iPadOS, in one place.
enum Platform {
    /// Shows files in the system file browser, or `nil` where the app cannot open one.
    static var revealFiles: (@MainActor ([URL]) -> Void)? {
        #if os(macOS)
        return { NSWorkspace.shared.activateFileViewerSelecting($0) }
        #else
        return nil
        #endif
    }

    static let fileBrowserName = "Finder"

    /// How to show the output folder: the path with the home folder as `~` on macOS, the
    /// folder's name elsewhere (iOS paths point into containers and file providers).
    static func displayLocation(of folder: URL) -> String {
        #if os(macOS)
        var path = folder.path(percentEncoded: false)
        if path.count > 1, path.hasSuffix("/") { path.removeLast() }
        // In the sandbox NSHomeDirectory() is the container, so ask for the real home folder.
        if let entry = getpwuid(getuid()), let home = entry.pointee.pw_dir.map({ String(cString: $0) }),
           path == home || path.hasPrefix(home + "/") {
            return "~" + path.dropFirst(home.count)
        }
        return path
        #else
        return (try? folder.resourceValues(forKeys: [.localizedNameKey]).localizedName) ?? folder.lastPathComponent
        #endif
    }
}

extension View {
    /// A checkbox on macOS, the platform's usual toggle elsewhere.
    func checkboxToggleStyle() -> some View {
        #if os(macOS)
        toggleStyle(.checkbox)
        #else
        self
        #endif
    }
}
