import XCTest
@testable import Ivy

@MainActor
final class MailboxKeyTests: XCTestCase {
    func testHarnessSkipsIntro() {
        let store = StoreHarness.make()
        XCTAssertFalse(store.isIntro)
        XCTAssertEqual(store.room, .yard)
    }

    func testEnter817CollectsLetterThenOpensScrollAfterLanding() {
        let store = StoreHarness.make()
        store.overlay = .plaque
        store.plaqueDraft = "817"
        store.submitAssemble()
        XCTAssertTrue(store.mailboxOpened)
        XCTAssertEqual(store.collected, [.letter])
        XCTAssertEqual(store.collectingEgg, .letter)
        XCTAssertEqual(store.room, .yard)
        XCTAssertEqual(store.overlay, .none)
        store.finishCollection(.letter)
        XCTAssertEqual(store.overlay, .envelope)
        XCTAssertFalse(store.envelopeDidUnroll)
        store.markEnvelopeUnrolled()
        store.dismissEnvelope()
        XCTAssertEqual(store.overlay, .none)
        store.tapYardDoor()
        XCTAssertEqual(store.overlay, .lyric)
    }

    func testWrongMailboxEnterKeepsDigitsAndStings() {
        let store = StoreHarness.make()
        store.overlay = .plaque
        store.plaqueDraft = "929"
        store.submitAssemble()
        XCTAssertFalse(store.mailboxOpened)
        XCTAssertEqual(store.plaqueDraft, "929")
        XCTAssertEqual(store.overlay, .plaque)
        XCTAssertEqual(store.plaqueHint, GameCopy.wrongAnswer)
    }

    func testFilledLetterSlotRereadsWithoutAnotherCollection() {
        let store = StoreHarness.make()
        store.overlay = .plaque
        store.plaqueDraft = "817"
        store.submitAssemble()
        store.finishCollection(.letter)
        store.markEnvelopeUnrolled()
        store.dismissEnvelope()
        store.reopenEnvelopeFromBar()
        XCTAssertEqual(store.overlay, .envelope)
        XCTAssertTrue(store.envelopeDidUnroll)
        XCTAssertEqual(store.collected, [.letter])
        XCTAssertNil(store.collectingEgg)
    }

    func testMailboxOnlySaveReceivesLetterBeforeDoorWasEverOpened() {
        let suite = "ivy.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let old = GameStore(defaults: defaults)
        old.isIntro = false
        old.mailboxOpened = true
        old.persistNow()
        let restored = GameStore(defaults: defaults)
        XCTAssertEqual(restored.collected, [.letter])
        XCTAssertTrue(restored.mailboxOpened)
        XCTAssertFalse(restored.doorOpened)
        XCTAssertNil(restored.collectingEgg)
    }

    func testBlockedDoorBeforeKeyDoesNotOpenLyricLock() {
        let store = StoreHarness.make()
        store.tapYardDoor()
        XCTAssertEqual(store.room, .yard)
        XCTAssertEqual(store.overlay, .dialogue(GameCopy.doorNeedsLetter))
        XCTAssertFalse(store.doorOpened)
    }

    func testUsedMailboxRereadsLetterWithoutAnotherEgg() {
        let store = StoreHarness.make()
        store.mailboxOpened = true
        store.collected = [.letter]
        store.tapYardMailbox()
        XCTAssertEqual(store.overlay, .envelope)
        XCTAssertEqual(store.collected, [.letter])
        XCTAssertNil(store.collectingEgg)
        XCTAssertEqual(store.room, .yard)
    }

    func testSnapshotRestoresLetterAndOpenDoorWithoutDialogue() {
        let suite = "ivy.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let a = GameStore(defaults: defaults)
        a.isIntro = false
        a.prefersReducedMotion = true
        a.mailboxOpened = true
        a.collected = [.letter]
        a.overlay = .lyric
        a.lyricDraft = "coveredinyou"
        a.submitAssemble()
        a.overlay = .dialogue("noise")
        a.persistNow()

        let b = GameStore(defaults: defaults)
        XCTAssertTrue(b.mailboxOpened)
        XCTAssertEqual(b.collected, Set([EggId.letter]))
        XCTAssertTrue(b.doorOpened)
        XCTAssertEqual(b.room, .hall)
        XCTAssertNotEqual(b.overlay, .dialogue("noise"))
        XCTAssertTrue(b.isIntro == false || b.doorOpened)
    }

    func testMailboxSuccessMigratesToLetterBeforeDoorOpens() throws {
        let restored = try restoreLegacyLetter(doorOpened: false)
        XCTAssertTrue(restored.mailboxOpened)
        XCTAssertEqual(restored.collected, Set([.letter, .plane]))
        XCTAssertEqual(restored.overlay, .envelope)
        XCTAssertTrue(restored.envelopeDidUnroll)
    }

    func testLegacyIvyMigratesToLetterAfterDoorOpens() throws {
        let restored = try restoreLegacyLetter(doorOpened: true)
        XCTAssertTrue(restored.doorOpened)
        XCTAssertEqual(restored.collected, Set([.letter, .plane]))
    }

    private func restoreLegacyLetter(doorOpened: Bool) throws -> GameStore {
        let suite = "ivy.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = GameStore(defaults: defaults)
        original.isIntro = false
        original.mailboxOpened = true
        original.doorOpened = doorOpened
        original.persistNow()
        let key = "ivy.game.snapshot.v4"
        var snapshot = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(defaults.data(forKey: key))) as? [String: Any])
        snapshot["collected"] = [doorOpened ? "ivy" : "letter", "plane"]
        snapshot["overlay"] = "envelope"
        defaults.set(try JSONSerialization.data(withJSONObject: snapshot), forKey: key)
        return GameStore(defaults: defaults)
    }
}
