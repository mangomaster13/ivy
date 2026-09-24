import XCTest
@testable import Ivy

@MainActor
final class GelatoWordPuzzleTests: XCTestCase {
    func testWholeAttemptGatesLettersInputAndActiveTasting() {
        let store = StoreHarness.make()
        store.room = .gelato
        store.acquire(.scoop)
        store.openMemory(.tasting)
        XCTAssertEqual(store.overlay, .memory(.menu))
        store.setGelatoFlavorDraft("jasmine")
        store.submitGelatoFlavor()
        XCTAssertTrue(store.gelatoWords.flavorDraft.isEmpty)
        XCTAssertFalse(store.gelatoWords.flavorSolved)
        XCTAssertFalse(store.clueText(.recipe).contains("leaf under"))

        // A correct prefix stays editable and does not reveal any letter.
        store.selectGelatoWord(4)
        store.submitGelatoChain()
        XCTAssertEqual(store.gelatoWords.order, [4])
        XCTAssertFalse(store.gelatoWords.chainSolved)
        store.selectGelatoWord(4)
        Array(0..<7).forEach(store.selectGelatoWord)
        store.submitGelatoChain()
        XCTAssertEqual(store.gelatoWords.order, Array(0..<7))
        XCTAssertFalse(store.gelatoWords.chainSolved)
        store.selectGelatoWord(0)
        GelatoWordProgress.answer.forEach(store.selectGelatoWord)
        store.submitGelatoChain()
        XCTAssertTrue(store.gelatoWords.chainSolved)
        XCTAssertTrue(store.clueText(.recipe).contains("leaf under"))
        store.setGelatoFlavorDraft("rose")
        store.submitGelatoFlavor()
        XCTAssertEqual(store.gelatoWords.flavorDraft, "rose")
        XCTAssertFalse(store.gelatoWords.flavorSolved)
        store.setGelatoFlavorDraft("  JAsMine ")
        store.submitGelatoFlavor()
        XCTAssertTrue(store.gelatoWords.flavorSolved)
        XCTAssertFalse(store.collected.contains(.gelato))
        XCTAssertEqual(store.overlay, .memory(.menu), "The served cup replaces the menu without a Taste navigation step")
        store.taste(2)
        XCTAssertFalse(store.collected.contains(.gelato), "Holding the spoon must not auto-select it")
        store.chooseTool(.scoop)
        store.taste(0)
        XCTAssertTrue(store.exploration.tools.contains(.scoop))
        store.taste(2)
        XCTAssertTrue(store.collected.contains(.gelato))
        XCTAssertFalse(store.exploration.tools.contains(.scoop))
        store.finishCollection(.gelato)
        store.cancelOverlay()
        store.openMemory(.menu)
        XCTAssertEqual(store.overlay, .observation(.gelato))
        XCTAssertNil(store.collectingEgg)
    }

    func testDraftsRestoreAndLegacyCompletionMigratesWithoutAwarding() throws {
        let suite = "ivy.word-chain.tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = GameStore(defaults: defaults)
        store.isIntro = false; store.prefersReducedMotion = true
        store.room = .gelato; store.overlay = .none
        store.openMemory(.menu)
        [4, 2, 6].forEach(store.selectGelatoWord)
        store.persistNow()
        let restored = GameStore(defaults: defaults)
        XCTAssertEqual(restored.gelatoWords.order, [4, 2, 6])
        restored.isIntro = false; restored.openMemory(.menu)
        [3, 0, 5, 1].forEach(restored.selectGelatoWord)
        restored.submitGelatoChain()
        restored.setGelatoFlavorDraft("rose")
        restored.submitGelatoFlavor()
        restored.persistNow()
        let again = GameStore(defaults: defaults)
        XCTAssertTrue(again.gelatoWords.chainSolved)
        XCTAssertEqual(again.gelatoWords.flavorDraft, "rose")
        XCTAssertFalse(again.gelatoWords.flavorSolved)

        // Missing optional record must decode an actual pre-word-puzzle save.
        var old = MemoryProgress()
        old.menuSolved = true
        let decoded = try JSONDecoder().decode(MemoryProgress.self, from: JSONEncoder().encode(old))
        XCTAssertNil(decoded.gelatoWords)
        again.memories = decoded
        again.migrateGelatoWords()
        XCTAssertTrue(again.gelatoWords.flavorSolved)
        XCTAssertFalse(again.collected.contains(.gelato))
        again.memories = MemoryProgress()
        again.memories.gelatoWater = GelatoWaterProgress(tagRevealed: true)
        again.migrateGelatoWords()
        XCTAssertTrue(again.gelatoWords.chainSolved)
        XCTAssertFalse(again.gelatoWords.flavorSolved)
        again.collected.insert(.gelato)
        again.migrateGelatoWords()
        XCTAssertTrue(again.gelatoWords.flavorSolved)
        XCTAssertEqual(again.collected, [.gelato])
    }

    func testCluesAndLegacyActionsCannotBypassWordPuzzle() {
        let store = StoreHarness.make()
        store.room = .gelato
        store.openMemory(.gelatoOrder)
        XCTAssertTrue(store.exploration.clues.contains(.gelatoOrder))
        store.openMemory(.gelatoNote)
        XCTAssertTrue(store.exploration.clues.contains(.gelatoLeaves))
        store.selectGelatoWord(4)
        XCTAssertTrue(store.gelatoWords.order.isEmpty)
        store.openMemory(.menu)
        store.memories.menu = [0, 1, 2, 3]
        store.confirmMenu()
        XCTAssertFalse(store.gelatoWords.chainSolved)
        store.acquire(.scoop)
        store.chooseTool(.scoop)
        store.overlay = .gelato
        store.exploration.freezerTemperature = -12
        store.exploration.scoops = ExplorationProgress.gelatoAnswer
        store.serveGelato()
        XCTAssertEqual(store.overlay, .memory(.menu))
        XCTAssertFalse(store.collected.contains(.gelato))
        store.gelatoWords = GelatoWordProgress(order: [99, 4, 4, -1, 2])
        store.gelatoWords.sanitize()
        XCTAssertEqual(store.gelatoWords.order, [4, 2])
    }
}
