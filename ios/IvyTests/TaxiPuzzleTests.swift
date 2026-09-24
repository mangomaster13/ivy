import XCTest
@testable import Ivy

@MainActor
final class TaxiPuzzleTests: XCTestCase {
    func testWholeRouteReceiptHomecomingAndOldSave() throws {
        let suite = "ivy.taxi.tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = GameStore(defaults: defaults)
        store.isIntro = false
        store.room = .taxi

        store.openMemory(.taxiCard)
        store.takeTaxiCard()
        XCTAssertTrue(store.exploration.clues.contains(.taxiRoute))
        store.backFromMemory()
        store.openMemory(.taxi)
        for node in [1, 3, 6] { store.extendTaxiRoute(to: node) }
        XCTAssertFalse(store.taxi.arrived)
        store.undoTaxiRoute()
        store.undoTaxiRoute()
        for node in [4, 3, 6] { store.extendTaxiRoute(to: node) }
        XCTAssertTrue(store.taxi.arrived)
        XCTAssertEqual(store.overlay, .none)
        store.openMemory(.taxiReceipt)
        XCTAssertTrue(store.taxi.receiptPrinted)
        store.takeTaxiReceipt()
        XCTAssertTrue(store.collected.contains(.taxi))
        XCTAssertEqual(store.collectingEgg, .taxi)
        store.finishCollection(.taxi)
        store.backFromMemory()
        store.tapDiegetic(.taxiDoor)
        XCTAssertEqual(store.room, .yard)

        var old = MemoryProgress()
        old.opened.insert("taxi")
        store.memories = try JSONDecoder().decode(MemoryProgress.self, from: JSONEncoder().encode(old))
        store.collected = []
        store.migrateTaxi()
        XCTAssertTrue(store.taxi.arrived)
        XCTAssertTrue(store.taxi.receiptPrinted)
        XCTAssertFalse(store.taxi.receiptTaken)
        store.collected.insert(.taxi)
        store.migrateTaxi()
        XCTAssertTrue(store.taxi.receiptTaken)
    }
}
