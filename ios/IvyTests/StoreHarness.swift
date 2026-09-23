import Foundation
@testable import Ivy

@MainActor
enum StoreHarness {
    /// Isolated store: Reduce Motion on so walks and cuts stay synchronous.
    static func make() -> GameStore {
        let suite = "ivy.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = GameStore(defaults: defaults)
        store.isIntro = false
        store.prefersReducedMotion = true
        store.overlay = .none
        return store
    }
}
