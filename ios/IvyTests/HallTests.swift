import XCTest
@testable import Ivy

@MainActor
final class HallTests: XCTestCase {
    func testVuoriWrongClearsDraftAndCorrectCollectsOnlyOnce() {
        let store = StoreHarness.make()
        store.room = .hall
        store.tapVuori()
        [0, 1, 2, 3, 4].forEach(store.connectVuoriLetter)
        store.finishVuoriConnection()
        XCTAssertTrue(store.vuoriDraft.isEmpty)
        XCTAssertEqual(store.overlay, .vuori)
        XCTAssertTrue(store.vuoriMiss)
        XCTAssertFalse(store.collected.contains(.vuori))
        [1, 4, 3, 6, 7].forEach(store.connectVuoriLetter)
        XCTAssertFalse(store.collected.contains(.vuori), "Dragging must not collect before finger lift")
        store.finishVuoriConnection()
        XCTAssertEqual(store.collectingEgg, .vuori)
        XCTAssertEqual(store.overlay, .none)
        store.finishCollection(.vuori)
        store.tapVuori()
        XCTAssertNil(store.collectingEgg)
        XCTAssertEqual(store.overlay, .vuoriMemory)
        store.finishVuoriConnection()
        XCTAssertTrue(store.collectionQueue.isEmpty)
    }

    func testLotteryNeedsAllEggsAndHall() {
        let store = StoreHarness.make()
        store.room = .hall
        store.collected = Set(EggId.allCases.filter { $0 != .taxi })
        store.tapLottery()
        XCTAssertFalse(store.lotteryDrawn)
        XCTAssertEqual(store.overlay, .none)
        store.collected.insert(.taxi)
        store.room = .taxi
        store.tapLottery()
        XCTAssertFalse(store.lotteryDrawn)
        store.room = .hall
        store.tapLottery()
        XCTAssertTrue(store.lotteryDrawn)
        XCTAssertEqual(store.overlay, .prize)
        store.cancelOverlay()
        store.tapLottery()
        XCTAssertEqual(store.overlay, .prize)
    }

    func testHallDraftAndClaimSurviveReload() {
        let suite = "ivy.hall.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = GameStore(defaults: defaults)
        store.isIntro = false
        store.room = .hall
        store.tapVuori()
        [1, 4, 3].forEach(store.connectVuoriLetter)
        store.persistNow()
        let restored = GameStore(defaults: defaults)
        XCTAssertEqual(restored.vuoriDraft, "vuo")
        XCTAssertFalse(restored.lotteryDrawn)
        restored.collected = Set(EggId.allCases)
        restored.tapLottery()
        restored.persistNow()
        let claimed = GameStore(defaults: defaults)
        XCTAssertTrue(claimed.lotteryDrawn)
        XCTAssertTrue(claimed.lotteryReady)
        XCTAssertEqual(claimed.overlay, .none)
    }

    func testHallHoleDoesNotRequireVuoriAndKeepsInventory() {
        let store = StoreHarness.make()
        store.room = .hall
        store.collected = [.letter]
        store.tapDiegetic(.hallHole)
        XCTAssertEqual(store.room, .plane)
        XCTAssertEqual(store.collected, [.letter])
        store.tapDiegetic(.planeHole)
        XCTAssertEqual(store.room, .hall)
        store.tapHallExit()
        XCTAssertEqual(store.room, .yard)
    }

    func testOtherRoomsCannotOpenVuori() {
        let store = StoreHarness.make()
        store.room = .yard
        store.tapVuori()
        XCTAssertEqual(store.overlay, .none)
    }

    func testConnectionSupportsBacktrackingAndRetainsDraftOnBack() {
        let store = StoreHarness.make()
        store.room = .hall
        store.tapVuori()
        [-1, 9, 1, 1, 4, 3].forEach(store.connectVuoriLetter)
        XCTAssertEqual(store.vuoriDraft, "vuo")
        store.connectVuoriLetter(4)
        XCTAssertEqual(store.vuoriDraft, "vu")
        store.cancelOverlay()
        store.tapVuori()
        XCTAssertEqual(store.vuoriPath, [1, 4])
        store.finishVuoriConnection()
        XCTAssertTrue(store.vuoriPath.isEmpty)
        XCTAssertFalse(store.vuoriMiss)
    }

    func testWrongPathClearsWithoutMovingLetters() {
        let store = StoreHarness.make()
        store.room = .hall; store.tapVuori()
        [1, 4, 3, 6, 8].forEach(store.connectVuoriLetter)
        store.finishVuoriConnection()
        XCTAssertTrue(store.vuoriMiss)
        XCTAssertTrue(store.vuoriDraft.isEmpty)
        [1, 4, 3, 6, 7].forEach(store.connectVuoriLetter)
        store.finishVuoriConnection()
        XCTAssertEqual(store.collected, [.vuori])
        XCTAssertEqual(store.collectionQueue, [.vuori])
        XCTAssertEqual(String(VuoriPuzzle.letters), "lvaoutrie")
    }

    func testFastSwipesHitEveryCrossedNodeInTravelOrder() {
        let grid = VuoriGridLayout(side: 270)
        XCTAssertEqual(grid.crossedIndices(from: grid.center(1), to: grid.center(7)), [1, 4, 7])
        XCTAssertEqual(grid.crossedIndices(from: grid.center(7), to: grid.center(1)), [7, 4, 1])
        XCTAssertEqual(grid.crossedIndices(from: grid.center(4), to: grid.center(3)), [4, 3])
        XCTAssertEqual(grid.crossedIndices(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: 180)), [])
        XCTAssertEqual(grid.crossedIndices(from: grid.center(1), to: grid.center(1)), [1])
    }

    func testVuoriBarMemoryReturnsToOriginalRoomViewAndOverlay() {
        let store = StoreHarness.make()
        store.room = .plane
        store.exploration.views[Room.plane.rawValue] = 1
        store.collected = [.letter, .vuori]
        store.overlay = .adventure(.notebook)
        store.vuoriDraft = "vuo"
        store.sceneHint = "A remembered line."
        store.reopenVuoriFromBar()
        XCTAssertEqual(store.overlay, .vuoriMemory)
        store.reopenVuoriFromBar()
        store.cancelOverlay()
        XCTAssertEqual(store.overlay, .adventure(.notebook))
        XCTAssertEqual(store.room, .plane)
        XCTAssertEqual(store.sceneView, 1)
        XCTAssertEqual(store.vuoriDraft, "vuo")
        XCTAssertEqual(store.sceneHint, "A remembered line.")
        XCTAssertEqual(store.collected, [.letter, .vuori])
        XCTAssertTrue(store.collectionQueue.isEmpty)
    }

    func testVuoriBarMemoryCannotOpenBeforeCollectionOrDuringTransitions() {
        let store = StoreHarness.make()
        store.reopenVuoriFromBar()
        XCTAssertEqual(store.overlay, .none)
        store.collect(.vuori)
        store.reopenVuoriFromBar()
        XCTAssertEqual(store.overlay, .none)
        store.finishCollection(.vuori)
        store.isHallTransitioning = true
        store.reopenVuoriFromBar()
        XCTAssertEqual(store.overlay, .none)
        store.isHallTransitioning = false
        store.reopenVuoriFromBar()
        XCTAssertEqual(store.overlay, .vuoriMemory)
    }

    func testLegacyVuoriSaveKeepsRewardsAndDraftWhileRetiringMagnifier() {
        let suite = "ivy.vuori.legacy.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = GameStore(defaults: defaults)
        store.isIntro = false
        store.room = .hall
        store.collected = [.letter, .city]
        store.vuoriDraft = " VuO "
        store.exploration.tools = [.magnifier, .eraser]
        store.exploration.hotelCode = [1, 7, 3, 9]
        store.persistNow()
        let restored = GameStore(defaults: defaults)
        XCTAssertEqual(restored.vuoriPath, [1, 4, 3])
        XCTAssertEqual(restored.collected, [.letter, .city])
        XCTAssertEqual(restored.exploration.tools, [.eraser])
        XCTAssertEqual(restored.exploration.hotelCode, [1, 7, 3, 9])
        XCTAssertFalse(MemoryPanel.drawer.tools.contains(.magnifier))
        restored.collected.insert(.vuori)
        restored.reopenVuoriFromBar()
        restored.persistNow()
        let again = GameStore(defaults: defaults)
        XCTAssertEqual(again.collected, [.letter, .city, .vuori])
        XCTAssertEqual(again.overlay, .none)
        XCTAssertTrue(again.collectionQueue.isEmpty)
    }
}
