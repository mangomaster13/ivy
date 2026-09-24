import XCTest
@testable import Ivy

@MainActor
final class DoorNavigationTests: XCTestCase {
    func testDoorOpensAndWaitsForTapWithoutAwardingAnotherEgg() {
        let store = StoreHarness.make()
        store.mailboxOpened = true
        store.collected = [.letter]
        store.overlay = .lyric
        store.lyricDraft = "coveredinyou"
        store.submitAssemble()
        XCTAssertTrue(store.doorOpened)
        XCTAssertEqual(store.collected, [.letter])
        XCTAssertEqual(store.room, .yard)
        XCTAssertEqual(store.yardImageName, "story-yard-open")
        XCTAssertFalse(store.isHallTransitioning)
        XCTAssertNil(store.collectingEgg)
        XCTAssertEqual(store.overlay, .none)
        store.tapYardDoor()
        XCTAssertEqual(store.room, .hall)
        store.tapHallExit()
        XCTAssertEqual(store.room, .yard)
        XCTAssertTrue(store.doorOpened)
    }

    func testCoveredInYou817IsWrong() {
        let store = StoreHarness.make()
        store.mailboxOpened = true
        store.overlay = .lyric
        store.lyricDraft = "coveredinyou817"
        store.submitAssemble()
        XCTAssertFalse(store.doorOpened)
        XCTAssertTrue(store.collected.isEmpty)
        XCTAssertEqual(store.overlay, .lyric)
        XCTAssertEqual(store.lyricHint, GameCopy.wrongAnswer)
    }

    func testDoorOpensAfterKey() {
        let store = StoreHarness.make()
        store.mailboxOpened = true
        store.tapYardDoor()
        XCTAssertEqual(store.overlay, .lyric)
        XCTAssertEqual(store.room, .yard)
    }

    func testGenericCollectionQueuesDistinctEggsAndIgnoresDuplicateCallbacks() {
        let store = StoreHarness.make()
        store.collect(.rose)
        store.collect(.plane)
        store.collect(.rose)
        XCTAssertEqual(store.collected, [.rose, .plane])
        XCTAssertEqual(store.collectionQueue, [.rose, .plane])
        store.finishCollection(.plane)
        XCTAssertEqual(store.collectingEgg, .rose)
        store.finishCollection(.rose)
        XCTAssertEqual(store.collectingEgg, .plane)
        store.finishCollection(.rose)
        XCTAssertEqual(store.collectingEgg, .plane)
        store.finishCollection(.plane)
        XCTAssertNil(store.collectingEgg)
        XCTAssertEqual(store.room, .yard)
    }

    func testInterruptedCollectionKeepsEggWithoutReplayingCelebration() {
        let suite = "ivy.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = GameStore(defaults: defaults)
        original.isIntro = false
        original.overlay = .plaque
        original.plaqueDraft = "817"
        original.submitAssemble()
        original.persistNow()
        let restored = GameStore(defaults: defaults)
        restored.prefersReducedMotion = true
        XCTAssertEqual(restored.collected, [.letter])
        XCTAssertNil(restored.collectingEgg)
        XCTAssertFalse(restored.doorOpened)
        restored.tapYardMailbox()
        XCTAssertEqual(restored.overlay, .envelope)
    }
}

@MainActor
final class IvyFeedbackTests: XCTestCase {
    func testBlockedToolActionHintsWithoutUsingOrConsumingTheTool() {
        let store = StoreHarness.make()
        store.room = .hall
        store.openMemory(.drawer)
        XCTAssertEqual(store.overlay, .none)
        XCTAssertEqual(store.sceneHint, "A small keyhole beneath the handle.")
        store.acquire(.brassKey)
        store.openMemory(.drawer)
        store.openContainer(.drawer)
        XCTAssertEqual(store.sceneHint, "Something in your bag might fit.")
        XCTAssertEqual(store.sceneHintPresentation, .interaction)
        XCTAssertFalse(store.memories.opened.contains("drawer"))
        XCTAssertTrue(store.exploration.tools.contains(.brassKey))
        store.chooseTool(.brassKey)
        store.openContainer(.drawer)
        XCTAssertTrue(store.memories.opened.contains("drawer"))
        XCTAssertFalse(store.exploration.tools.contains(.brassKey))
        XCTAssertTrue(store.sceneHint.isEmpty)
        store.backFromMemory()
        store.openMemory(.drawer)
        XCTAssertEqual(store.overlay, .memory(.drawer))
        XCTAssertTrue(store.sceneHint.isEmpty)
        store.tapMiss()
        XCTAssertTrue(store.sceneHint.isEmpty)
    }

    func testInputErrorKeepsDraftUntilPlayerEdits() {
        let store = StoreHarness.make()
        store.overlay = .plaque
        store.plaqueDraft = "816"
        store.submitAssemble()
        XCTAssertEqual(store.plaqueDraft, "816")
        XCTAssertEqual(store.assembleHintTone, .wrong)
        XCTAssertEqual(store.assembleHint, GameCopy.wrongAnswer)
        store.backspaceAssemble()
        XCTAssertEqual(store.plaqueDraft, "81")
        XCTAssertTrue(store.assembleHint.isEmpty)
        store.appendAssembleGlyph("7")
        store.submitAssemble()
        XCTAssertTrue(store.mailboxOpened)
    }

    func testSceneReplacementResetsToneAndDismissalLeavesWorldUnchanged() {
        let store = StoreHarness.make()
        store.showSceneHint("This key does not fit.", tone: .wrong)
        XCTAssertEqual(store.sceneHintTone, .wrong)
        store.showSceneHint("A quiet room.")
        XCTAssertEqual(store.sceneHintTone, .ordinary)
        store.dismissSceneHint()
        XCTAssertTrue(store.sceneHint.isEmpty)
        XCTAssertEqual(store.room, .yard)
        XCTAssertTrue(store.collected.isEmpty)
        store.overlay = .dialogue("A letter waits.")
        store.dismissDialogue()
        XCTAssertEqual(store.overlay, .none)
        XCTAssertFalse(store.doorOpened)
    }

    func testWordAndHotelErrorsKeepDraftsAndShowFeedback() {
        let store = StoreHarness.make()
        store.room = .bedroom
        store.overlay = .memory(.wholeBox)
        store.memories.wholeDraft = "whole"
        store.submitWhole()
        XCTAssertEqual(store.memories.wholeDraft, "whole")
        XCTAssertEqual(store.sceneHintTone, .wrong)
        XCTAssertEqual(store.sceneHint, GameCopy.wrongAnswer)
        store.room = .corridor
        store.overlay = .hotelLock
        store.exploration.hotelCode = [1, 2, 3, 4]
        store.corridorDigits = [0, 0, 0, 0]
        store.submitHotelCode()
        XCTAssertEqual(store.sceneHintTone, .wrong)
        XCTAssertEqual(store.sceneHint, GameCopy.wrongAnswer)
        store.turnHotelWheel(0, by: 1)
        XCTAssertTrue(store.sceneHint.isEmpty)
    }

    func testDecorativeTapsStaySilentWithASelectedTool() {
        let store = StoreHarness.make()
        store.acquire(.brassKey)
        store.chooseTool(.brassKey)
        store.tapMiss()
        store.tapYardIvy()
        XCTAssertTrue(store.sceneHint.isEmpty)
        XCTAssertEqual(store.overlay, .none)
        XCTAssertEqual(store.selectedTool, .brassKey)
    }
}
