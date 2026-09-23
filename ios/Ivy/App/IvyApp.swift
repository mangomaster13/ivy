import SwiftUI

/// Ivy gift game: one portrait iPhone window, no account, no network.
@main
struct IvyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
