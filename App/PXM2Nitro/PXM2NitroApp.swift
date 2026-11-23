import PXM2NitroUI
import SwiftUI

@main
struct PXM2NitroApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif

    var body: some Scene {
        #if os(macOS)
        Window("pxm2nitro", id: "main") {
            ContentView()
                .frame(minWidth: 620, minHeight: 480)
        }
        .defaultSize(width: 960, height: 720)
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
#endif
