import PXM2NitroUI
import SwiftUI

@main
struct PXM2NitroApp: App {
    @State private var session = ConversionSession()

    var body: some Scene {
        // A single Window (not a WindowGroup): the app quits when it is closed.
        Window("pxm2nitro", id: "main") {
            ContentView(session: session)
                .frame(minWidth: 620, minHeight: 480)
                .navigationSubtitle("Photomator to Nitro")
        }
        .defaultSize(width: 960, height: 720)
    }
}
