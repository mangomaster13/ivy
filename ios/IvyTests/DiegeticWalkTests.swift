import XCTest
@testable import Ivy

@MainActor
final class DiegeticWalkTests: XCTestCase {
    func testHallHoleLandsInPlane() {
        let store = StoreHarness.make()
        store.room = .hall
        store.doorOpened = true
        store.tapDiegetic(.hallHole)
        XCTAssertEqual(store.room, .plane)
        XCTAssertTrue(store.collected.isEmpty)
    }

    func testDepartOpensRouteBeforeTravel() {
        let store = StoreHarness.make()
        store.room = .plane
        store.tapDiegetic(.planeDepart)
        XCTAssertEqual(store.room, .plane)
        XCTAssertEqual(store.overlay, .memory(.flight))
        XCTAssertFalse(store.collected.contains(.plane))
    }

    func testLockedCorridorDoesNotEnterBedroom() {
        let store = StoreHarness.make()
        store.room = .corridor
        store.corridorUnlocked = false
        store.tapDiegetic(.corridorForward)
        XCTAssertEqual(store.room, .corridor)
    }

    func testCinemaExitCannotSkipToFerris() {
        let store = StoreHarness.make()
        store.room = .cinema
        store.tapDiegetic(.cinemaExit)
        XCTAssertEqual(store.room, .dictionary)
        store.tapDiegetic(.cinemaExit)
        XCTAssertEqual(store.room, .dictionary)
    }

    func testTaxiDoorClimbsToHall() {
        let store = StoreHarness.make()
        store.room = .taxi
        store.tapDiegetic(.taxiDoor)
        XCTAssertEqual(store.room, .hall)
    }

    func testSnapshotRestoresWonderlandRoom() {
        let suite = "ivy.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let seeded = GameStore(defaults: defaults)
        seeded.isIntro = false
        seeded.prefersReducedMotion = true
        seeded.room = .cinema
        seeded.persistNow()
        let b = GameStore(defaults: defaults)
        XCTAssertEqual(b.room, .cinema)
    }
}
