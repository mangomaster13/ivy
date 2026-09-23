import XCTest
@testable import Ivy

@MainActor
final class WonderlandTests: XCTestCase {
    func testOwnedBedRoseUsesInventoryElementAndReturnsToScene() {
        let store = StoreHarness.make()
        store.room = .bedroom
        store.collected.insert(.rose)
        store.openMemory(.bouquet)
        XCTAssertEqual(store.overlay, .observation(.rose))
        XCTAssertEqual(store.elementReturnOverlay, GameOverlay.none)
        XCTAssertTrue(store.memoryNavigation.isEmpty)
        XCTAssertTrue(store.collectionQueue.isEmpty)
        store.closeElementForFooter()
        XCTAssertEqual(store.overlay, .none)
    }

    func testNewKeepsakesSwitchToMemoriesWithoutOverridingLaterTabChoice() {
        let store = StoreHarness.make()
        store.toolsVisible = true
        store.collect(.letter, playHaptic: false)
        XCTAssertFalse(store.toolsVisible)
        store.finishCollection(.letter)
        store.toolsVisible = true
        store.collect(.letter, playHaptic: false)
        XCTAssertTrue(store.toolsVisible)

        store.memories.rose = RoseProgress(revealed: Set(0..<3), found: Set(0..<3), placed: Set(0..<3))
        store.unlockAssemblyKeepsake(.rose)
        XCTAssertFalse(store.toolsVisible)
        XCTAssertTrue(store.collected.contains(.rose))
        XCTAssertTrue(store.collectionQueue.isEmpty)
        store.toolsVisible = true
        store.unlockAssemblyKeepsake(.rose)
        XCTAssertTrue(store.toolsVisible)
    }

    func testRubbingContinuousSegmentsAndSeparateTouches() throws {
        var p = RubbingProgress()
        let size = CGSize(width: 400, height: 120)
        p.begin(at: CGPoint(x: 20, y: 60), size: size)
        p.append(CGPoint(x: 380, y: 60), size: size)
        XCTAssertTrue(p.covers(.init(x: 0.5, y: 0.5)), "Fast movement must interpolate")
        XCTAssertFalse(p.covers(.init(x: 0.5, y: 0.95)))
        let decoded = try JSONDecoder().decode(RubbingProgress.self, from: JSONEncoder().encode(p))
        XCTAssertEqual(p, decoded)
        var separate = RubbingProgress()
        separate.begin(at: CGPoint(x: 20, y: 60), size: size)
        separate.begin(at: CGPoint(x: 380, y: 60), size: size)
        XCTAssertFalse(separate.covers(.init(x: 0.5, y: 0.5)), "Lifting must not bridge")
        XCTAssertFalse(separate.complete)
        for y in stride(from: 20, through: 100, by: 15) {
            p.begin(at: CGPoint(x: 0, y: y), size: size)
            p.append(CGPoint(x: 400, y: y), size: size)
        }
        XCTAssertTrue(p.complete)
    }

    func testOldPencilSaveDecodesAsEraserAndRainToolIsIndependent() throws {
        XCTAssertEqual(try JSONDecoder().decode(AdventureTool.self, from: Data("\"pencil\"".utf8)), .eraser)
        let s = StoreHarness.make()
        s.room = .gelato; s.exploration.views[Room.gelato.rawValue] = -1
        s.exploration.clues.insert(.mirror); s.memories.used.insert(.cloth)
        let spot = s.explorationSpots.first { $0.id == "dry napkin" }!
        s.inspect(spot)
        XCTAssertTrue(s.exploration.tools.contains(.napkin))
        s.overlay = .adventure(.recipe); s.chooseTool(.napkin); s.wipeRecipe()
        XCTAssertTrue(s.exploration.clues.contains(.recipe))
        XCTAssertFalse(s.exploration.tools.contains(.napkin))
        s.cancelOverlay(); s.inspect(spot)
        XCTAssertFalse(s.exploration.tools.contains(.napkin))
    }

    func testOlderExplorationSaveWithoutRubbingStillLoads() throws {
        let data = try JSONEncoder().encode(ExplorationProgress())
        var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        object.removeValue(forKey: "rubbing")
        let restored = try JSONDecoder().decode(ExplorationProgress.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(restored.rubbing)
    }

    func testInspectionBackPreservesViewAndAvoidsCrossLinkLoops() {
        let store = StoreHarness.make()
        store.room = .plane
        store.exploration.views[Room.plane.rawValue] = 1
        store.collected.insert(.plane)
        store.openMemory(.ticket)
        store.openMemory(.flight)
        store.backFromMemory()
        XCTAssertEqual(store.overlay, .memory(.ticket))
        store.openMemory(.flight)
        store.openMemory(.ticket)
        store.backFromMemory()
        XCTAssertEqual(store.overlay, .none)
        XCTAssertEqual(store.sceneView, 1)
        store.openMemory(.yunnan)
        store.backFromMemory()
        XCTAssertEqual(store.overlay, .none)
    }

    func testEveryMapDecoyFailsAndCanBeCorrected() {
        XCTAssertEqual(JourneyCity.all.count, 10)
        XCTAssertEqual(Set(JourneyCity.all.map(\.id)).count, 10)
        for city in JourneyCity.all where city.name != "Hangzhou" {
            let store = StoreHarness.make(); store.room = .plane
            store.collected.insert(.plane)
            store.openMemory(.flight)
            store.selectCity(city.name); store.selectCity("Hong Kong")
            XCTAssertFalse(store.memories.routeCorrect)
            store.memories.origin = nil; store.memories.destination = nil
            store.selectCity("Hangzhou"); store.selectCity("Hong Kong")
            XCTAssertTrue(store.memories.routeCorrect)
            XCTAssertFalse(store.canDepart, "Correct geography must not bypass the concealed clue")
        }
    }

    func testPlaneNeedsMapClueAndTicketBeforeDeparture() {
        let s = StoreHarness.make(); s.room = .plane
        s.tapDiegetic(.planeDepart)
        XCTAssertEqual(s.room, .plane); XCTAssertEqual(s.overlay, .memory(.ticket))
        s.takeTicket()
        XCTAssertFalse(s.collected.contains(.plane), "The concealed ticket cannot be taken")
        s.departFlight(); XCTAssertEqual(s.room, .plane)
        s.exploration.clues.insert(.travelOrder)
        s.takeTicket()
        XCTAssertTrue(s.collected.contains(.plane), "Taking the ticket must not require solving departure first")
        XCTAssertFalse(s.memories.routeCorrect)
        s.finishCollection(.plane)
        s.openMemory(.flight)
        XCTAssertEqual(s.overlay, .memory(.flight))
        s.departFlight(); XCTAssertEqual(s.room, .plane)
        s.selectCity("Hong Kong"); s.selectCity("Hangzhou")
        XCTAssertFalse(s.canDepart)
        s.selectCity("Hong Kong"); s.selectCity("Hangzhou"); s.selectCity("Hong Kong")
        XCTAssertTrue(s.canDepart)
        s.departFlight()
        XCTAssertEqual(s.room, .corridor); XCTAssertFalse(s.corridorUnlocked)
    }

    func testHotelWrongDigitsStayAndSuccessDoesNotAwardCard() {
        let store = StoreHarness.make()
        store.room = .corridor
        store.tapMemory(.keycard)
        XCTAssertFalse(store.collected.contains(.keycard))
        store.tapMemory(.lock)
        for digits in [[0,0,0,0], [1,1,1,1], [9,9,9,9]] {
            store.corridorDigits = digits
            store.submitHotelCode()
            XCTAssertEqual(store.corridorDigits, digits)
            XCTAssertFalse(store.corridorUnlocked)
        }
        store.corridorDigits = store.exploration.hotelCode
        store.submitHotelCode()
        XCTAssertTrue(store.corridorUnlocked)
        XCTAssertEqual(store.overlay, .none)
        XCTAssertTrue(store.collected.isEmpty)
        store.tapMemory(.keycard)
        XCTAssertFalse(store.collected.contains(.keycard))
        store.collectPhysical(.keycard)
        XCTAssertEqual(store.collected, [.keycard])
        store.finishCollection(.keycard)
        store.cancelOverlay()
        store.tapDiegetic(.corridorForward)
        XCTAssertEqual(store.room, .bedroom)
    }

    func testWheelWrapAndCancelPreserveDigits() {
        let store = StoreHarness.make()
        store.room = .corridor
        store.tapMemory(.lock)
        store.turnHotelWheel(0, by: -1)
        XCTAssertEqual(store.corridorDigits[0], 9)
        store.turnHotelWheel(0, by: 1)
        XCTAssertEqual(store.corridorDigits[0], 0)
        store.turnHotelWheel(1, by: 1)
        store.cancelOverlay()
        store.tapMemory(.lock)
        XCTAssertEqual(store.corridorDigits, [0,1,0,0])
    }

    func testRoseDropTargetSurvivesEmptySiblingPreference() {
        let flower = CGRect(x: 240, y: 60, width: 190, height: 170)
        var target = RoseDropFrameKey.defaultValue
        RoseDropFrameKey.reduce(value: &target, nextValue: { flower })
        RoseDropFrameKey.reduce(value: &target, nextValue: { .null })
        RoseDropFrameKey.reduce(value: &target, nextValue: { .zero })
        XCTAssertEqual(target, flower)
        XCTAssertTrue(target.contains(CGPoint(x: 330, y: 120)))
    }

    func testRoseNeedsThreeFoundPetalsAndExplicitCollection() {
        let s = StoreHarness.make(); s.room = .bedroom
        s.openMemory(.blanket); s.revealRosePetal(0); s.takeRosePetal(0); s.backFromMemory()
        s.turnView(1); s.revealRosePetal(1); s.takeRosePetal(1)
        s.openMemory(.bouquet)
        s.placeRosePetal(2) // The box petal has not been found.
        XCTAssertTrue(s.roseProgress.placed.isEmpty)
        s.placeRosePetal(1); s.placeRosePetal(1); s.placeRosePetal(0)
        s.collectPhysical(.rose)
        XCTAssertFalse(s.collected.contains(.rose))
        XCTAssertEqual(s.roseProgress.placed, [0, 1])
        s.openMemory(.wholeBox); s.memories.wholeDraft = "as a whole"; s.submitWhole()
        s.takeRosePetal(2); s.openMemory(.bouquet); s.placeRosePetal(2)
        XCTAssertFalse(s.collected.contains(.rose))
        s.collectPhysical(.rose)
        XCTAssertEqual(s.collected, [.rose])
        s.finishCollection(.rose); s.collectPhysical(.rose); XCTAssertNil(s.collectingEgg)
    }

    func testCityAndRoseIndependentAndBedroomExitUngated() {
        let store = StoreHarness.make()
        store.room = .bedroom
        store.tapDiegetic(.bedroomForward)
        XCTAssertEqual(store.room, .gelato)
        store.tapDiegetic(.gelatoBack)
        store.tapMemory(.window)
        XCTAssertTrue(store.collected.isEmpty)
        store.swapCityPieces(0, 1); store.swapCityPieces(1, 3); store.swapCityPieces(2, 3)
        XCTAssertTrue(store.memories.citySolved)
        store.collectPhysical(.city)
        XCTAssertEqual(store.collected, [.city])
        XCTAssertFalse(store.petalHeld)
    }

    func testGelatoMenuSpoonAndExplicitFlavorConfirmation() {
        let s = StoreHarness.make(); s.room = .gelato; s.openMemory(.tasting)
        s.taste(2); s.confirmTaste(); XCTAssertTrue(s.collected.isEmpty)
        s.acquire(.scoop); s.memories.menuSolved = true
        s.taste(0); s.confirmTaste()
        XCTAssertTrue(s.collected.isEmpty); XCTAssertTrue(s.exploration.tools.contains(.scoop))
        s.taste(2); XCTAssertTrue(s.collected.isEmpty)
        s.confirmTaste(); XCTAssertEqual(s.collected, [.gelato])
        XCTAssertFalse(s.exploration.tools.contains(.scoop))
        s.finishCollection(.gelato); s.confirmTaste(); XCTAssertNil(s.collectingEgg)
    }

    func testRoomFadeBlocksRepeatedNavigationAndReleasesDismissal() async throws {
        let store = StoreHarness.make()
        store.room = .hall
        store.mailboxOpened = true
        store.prefersReducedMotion = false
        store.tapDiegetic(.hallHole)
        XCTAssertTrue(store.isHallTransitioning)
        store.tapDiegetic(.hallExit)
        store.reopenEnvelopeFromBar()
        XCTAssertEqual(store.overlay, .none)
        try await Task.sleep(for: .milliseconds(1500))
        XCTAssertEqual(store.room, .plane)
        XCTAssertFalse(store.isHallTransitioning)
        store.tapMemory(.boardingPass)
        store.finishCollection(.plane)
        store.cancelOverlay()
        XCTAssertEqual(store.overlay, .none)
    }

    func testNewPuzzleProgressRestoresWithoutReplayingRewards() {
        let suite = "ivy.wonderland.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = GameStore(defaults: defaults)
        store.room = .bedroom
        store.petalHeld = true
        store.corridorDigits = [1,6,0,8]
        store.corridorUnlocked = true
        store.gelatoSelection = [.pistachio]
        store.collected = [.letter, .plane]
        store.persistNow()
        let restored = GameStore(defaults: defaults)
        XCTAssertTrue(restored.petalHeld)
        XCTAssertEqual(restored.corridorDigits, [1,6,0,8])
        XCTAssertTrue(restored.corridorUnlocked)
        XCTAssertEqual(restored.gelatoSelection, [.pistachio])
        XCTAssertEqual(restored.collected, [.letter, .plane])
        XCTAssertNil(restored.collectingEgg)
    }
}

@MainActor
final class ExplorationTests: XCTestCase {
    private func touch(_ name: String, in store: GameStore) {
        guard let spot = store.explorationSpots.first(where: { $0.id == name }) else {
            XCTFail("Missing interactive object: " + name); return
        }
        store.inspect(spot)
    }

    func testCompleteToolAndClueRouteThroughGelato() {
        let s = StoreHarness.make(); s.doorOpened = true
        s.turnView(1); touch("terracotta pot", in: s)
        XCTAssertTrue(s.exploration.tools.isEmpty)
        s.openContainer(.pot); s.pickup(.brassKey, from: .pot)
        s.cancelOverlay(); s.turnView(-1); s.tapYardDoor(); s.turnView(1)
        touch("desk drawer", in: s); s.chooseTool(.brassKey); s.openContainer(.drawer)
        XCTAssertFalse(s.exploration.tools.contains(.brassKey))
        XCTAssertFalse(s.exploration.tools.contains(.eraser))
        s.pickup(.eraser, from: .drawer)
        s.cancelOverlay(); s.turnView(-1); s.tapVuori()
        [1, 4, 3, 6, 7].forEach(s.connectVuoriLetter)
        s.finishVuoriConnection(); s.finishCollection(.vuori)
        XCTAssertFalse(s.exploration.tools.contains(.magnifier))
        s.tapDiegetic(.hallHole); s.openMemory(.ticket); s.chooseTool(.eraser); s.traceTicket()
        XCTAssertFalse(s.exploration.tools.contains(.eraser))
        s.openMemory(.flight); s.selectCity("Hangzhou"); s.selectCity("Hong Kong")
        s.openMemory(.ticket); s.takeTicket(); s.finishCollection(.plane)
        s.openMemory(.flight); s.departFlight(); XCTAssertEqual(s.room, .corridor)
        s.turnView(-1); touch("linen cloth", in: s); s.openContainer(.linen); s.pickup(.cloth, from: .linen)
        s.cancelOverlay(); s.turnView(1); s.turnView(1); touch("misty mirror", in: s)
        s.chooseTool(.cloth); s.wipeMirror(); XCTAssertFalse(s.exploration.tools.contains(.cloth))
        s.cancelOverlay(); s.turnView(-1); s.tapMemory(.lock)
        s.corridorDigits = s.exploration.hotelCode; s.submitHotelCode(); s.tapDiegetic(.corridorForward)
        s.openMemory(.wholeBox); s.memories.wholeDraft = " As a WHOLE. "; s.submitWhole()
        XCTAssertTrue(s.exploration.tools.isEmpty)
        s.takeRosePetal(2); s.pickup(.coin, from: .wholeBox)
        s.cancelOverlay(); s.openMemory(.blanket); s.revealRosePetal(0); s.takeRosePetal(0); s.backFromMemory()
        s.turnView(1); s.revealRosePetal(1); s.takeRosePetal(1)
        s.openMemory(.bouquet)
        [2, 0, 1].forEach(s.placeRosePetal)
        s.collectPhysical(.rose); s.finishCollection(.rose)
        s.cancelOverlay(); s.turnView(-1)
        s.cancelOverlay(); s.tapDiegetic(.bedroomForward); s.openMemory(.menu)
        s.swapMenu(0, 1); s.swapMenu(1, 3); s.swapMenu(2, 3); s.confirmMenu()
        XCTAssertTrue(s.memories.menuSolved)
        s.openMemory(.dispenser); s.chooseTool(.coin); s.openContainer(.dispenser)
        XCTAssertFalse(s.exploration.tools.contains(.coin)); XCTAssertFalse(s.exploration.tools.contains(.scoop))
        s.pickup(.scoop, from: .dispenser); s.openMemory(.tasting); s.taste(2); s.confirmTaste()
        XCTAssertEqual(s.collectingEgg, .gelato); XCTAssertTrue(s.exploration.tools.isEmpty)
    }

    func testWrongToolAndDuplicatePickupAreSafe() {
        let s = StoreHarness.make()
        s.room = .hall; s.exploration.views["hall"] = 1
        s.exploration.tools.insert(.cloth); s.selectedTool = .cloth
        touch("desk drawer", in: s)
        XCTAssertFalse(s.exploration.drawerOpened)
        XCTAssertEqual(s.selectedTool, .cloth)
        XCTAssertEqual(s.exploration.tools, [.cloth])
        s.acquire(.cloth)
        XCTAssertTrue(s.collected.isEmpty)
        XCTAssertNil(s.collectingEgg)
    }

    func testGeneratedRoomCodeAndCluesPersistTogether() {
        let suite = "ivy.exploration." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let s = GameStore(defaults: defaults)
        s.exploration.tools = [.eraser, .cloth]
        s.exploration.clues = [.travelOrder, .mirror]
        s.exploration.views["corridor"] = -1
        s.exploration.scoops = [.pistachio, .pistachio]
        let code = s.exploration.hotelCode
        s.persistNow()
        let r = GameStore(defaults: defaults)
        XCTAssertEqual(r.exploration.hotelCode, code)
        XCTAssertEqual(r.clueText(.mirror), s.clueText(.mirror))
        XCTAssertTrue(r.exploration.tools.isEmpty, "Completed old clue tools migrate out of the bag")
        XCTAssertTrue(r.memories.used.isSuperset(of: [.eraser, .cloth]))
        XCTAssertEqual(r.exploration.scoops, [.pistachio, .pistachio])
        XCTAssertEqual(r.exploration.views["corridor"], -1)
        XCTAssertNil(r.selectedTool)
        XCTAssertNil(r.collectingEgg)
    }

    func testWholeBoxWrongAnswerNeverOpensOrAwardsTools() {
        let s = StoreHarness.make(); s.room = .bedroom; s.openMemory(.wholeBox)
        s.memories.wholeDraft = "your smile"; s.submitWhole()
        XCTAssertFalse(s.memories.opened.contains("wholeBox")); XCTAssertTrue(s.exploration.tools.isEmpty)
        s.memories.wholeDraft = "as a whole"; s.submitWhole()
        XCTAssertTrue(s.memories.opened.contains("wholeBox")); XCTAssertTrue(s.exploration.tools.isEmpty)
        s.pickup(.coin, from: .wholeBox); XCTAssertEqual(s.exploration.tools, [.coin])
        XCTAssertFalse(s.memories.picked.contains(.sewingKit))
    }

    func testEveryRoomFadeHasZeroOffsetAndRejectsSecondNavigation() async throws {
        let s = StoreHarness.make()
        s.prefersReducedMotion = false
        s.doorOpened = true
        s.tapYardDoor()
        XCTAssertTrue(s.isHallTransitioning)
        XCTAssertEqual(s.room, .yard)
        XCTAssertEqual(s.worldOffsetX, 0)
        s.transition(to: .taxi)
        try await Task.sleep(for: .milliseconds(480))
        XCTAssertEqual(s.worldDim, 1, "Room replacement must be under an opaque curtain")
        XCTAssertEqual(s.worldOffsetX, 0)
        try await Task.sleep(for: .milliseconds(700))
        XCTAssertEqual(s.room, .hall)
        XCTAssertFalse(s.isHallTransitioning)
        for room in [Room.plane, .corridor, .bedroom, .gelato] {
            s.transition(to: room)
            XCTAssertEqual(s.worldOffsetX, 0)
            XCTAssertTrue(s.isHallTransitioning)
            try await Task.sleep(for: .milliseconds(1180))
            XCTAssertEqual(s.room, room)
            XCTAssertEqual(s.worldOffsetX, 0)
            XCTAssertEqual(s.worldDim, 0)
            XCTAssertFalse(s.isHallTransitioning)
        }
    }

    func testTurningViewsCannotUsePrimaryRoomExitAndResetPreservesEarlierProgress() {
        let s = StoreHarness.make()
        s.room = .corridor
        s.turnView(-1)
        s.tapDiegetic(.corridorBack)
        XCTAssertEqual(s.room, .corridor)
        XCTAssertEqual(s.sceneView, -1)
        s.turnView(-1)
        XCTAssertEqual(s.sceneView, -1)
        s.exploration.tools.insert(.cloth)
        s.exploration.tools.insert(.scoop)
        s.memories.opened = ["linen", "wholeBox"]
        s.memories.picked = [.cloth, .eraser, .coin]
        s.memories.used = [.eraser, .coin]
        s.collected.insert(.keycard)
        let hotelCode = s.exploration.hotelCode
        s.resetToUnlockedRoom()
        XCTAssertEqual(s.exploration.tools, [.cloth])
        XCTAssertEqual(s.memories.opened, ["linen"])
        XCTAssertEqual(s.memories.picked, [.cloth, .eraser])
        XCTAssertEqual(s.memories.used, [.eraser])
        XCTAssertEqual(s.exploration.hotelCode, hotelCode)
        XCTAssertEqual(s.sceneView, 0)
        XCTAssertEqual(s.room, .bedroom)
        XCTAssertTrue(s.doorOpened)
        XCTAssertTrue(s.mailboxOpened)
        XCTAssertTrue(s.corridorUnlocked)
        XCTAssertTrue(s.memories.flightDeparted)
        XCTAssertEqual(s.corridorDigits, s.exploration.hotelCode)
        XCTAssertEqual(s.collected, [.letter, .vuori, .plane, .keycard])
    }

    func testCorruptProgressDoesNotStrandNavigationOrMusic() {
        var progress = ExplorationProgress()
        progress.hotelCode = [123]
        progress.views = ["yard": 99, "corridor": -1]
        progress.musicInput = [2, 2, 2, 2]
        progress.sanitize()
        XCTAssertTrue(progress.validHotelCode)
        XCTAssertEqual(progress.views["yard"], 0)
        XCTAssertEqual(progress.views["corridor"], -1)
        XCTAssertEqual(progress.musicInput.count, 2)
    }
}

@MainActor
final class ExplorationCompatibilityTests: XCTestCase {
    func testLegacySnapshotWithoutExplorationKeepsExistingRewards() throws {
        let suite = "ivy.legacy-exploration." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = GameStore(defaults: defaults)
        original.room = .bedroom
        original.doorOpened = true
        original.corridorUnlocked = true
        original.collected = [.letter, .rose, .gelato]
        original.persistNow()
        let key = "ivy.game.snapshot.v4"
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(defaults.data(forKey: key))) as? [String: Any])
        json.removeValue(forKey: "exploration")
        json.removeValue(forKey: "memories")
        defaults.set(try JSONSerialization.data(withJSONObject: json), forKey: key)
        let restored = GameStore(defaults: defaults)
        XCTAssertEqual(restored.room, .bedroom)
        XCTAssertEqual(restored.collected, [.letter, .rose, .gelato])
        XCTAssertTrue(restored.corridorUnlocked)
        XCTAssertTrue(restored.exploration.validHotelCode)
        XCTAssertNil(restored.collectingEgg)
    }

    func testOpenedDrawerAndPartialPickupPersistAndConsumedKeyNeverRespawns() {
        let suite = "ivy.memory." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let s = GameStore(defaults: defaults); s.isIntro = false
        s.room = .yard; s.openMemory(.pot); s.openContainer(.pot); s.pickup(.brassKey, from: .pot)
        s.room = .hall; s.openMemory(.drawer); s.chooseTool(.brassKey); s.openContainer(.drawer)
        s.pickup(.eraser, from: .drawer); s.persistNow()
        let r = GameStore(defaults: defaults)
        XCTAssertTrue(r.memories.opened.contains("drawer")); XCTAssertEqual(r.exploration.tools, [.eraser])
        r.openMemory(.drawer); r.pickup(.magnifier, from: .drawer)
        XCTAssertEqual(r.exploration.tools, [.eraser])
        r.room = .yard; r.openMemory(.pot); r.pickup(.brassKey, from: .pot)
        XCTAssertFalse(r.exploration.tools.contains(.brassKey))
    }
}

@MainActor
final class LaterMemoryTests: XCTestCase {
    func testAllLaterRewardsRequireSolvingAndPhysicalPickup() {
        let s = StoreHarness.make()
        let cases: [(Room, MemoryPanel, EggId)] = [(.noodle,.bigTop,.noodle),(.perfume,.perfume,.perfume),(.cinema,.cinema,.cinema),(.sunset,.sunset,.sunset),(.ferris,.ferris,.ferris),(.taxi,.taxi,.taxi)]
        for (room, panel, egg) in cases {
            s.room = room; s.openMemory(panel); s.collectPhysical(egg)
            XCTAssertFalse(s.collected.contains(egg))
            switch panel {
            case .bigTop: s.memories.bigTopDraft = "BIGTOP"
            case .perfume: s.memories.scents = [10,30,22]
            case .cinema: s.memories.cinemaDraft = "hope"; s.memories.cinemaSeats = [2,3]
            case .sunset: s.memories.sunsetFrame = 0.65
            case .ferris: s.memories.ferrisMatches = [0,1]
            case .taxi: s.memories.taxiDraft = "stay"
            default: break
            }
            s.solveLater(panel); XCTAssertFalse(s.collected.contains(egg))
            s.collectPhysical(egg); XCTAssertTrue(s.collected.contains(egg))
            s.finishCollection(egg); s.collectPhysical(egg); XCTAssertNil(s.collectingEgg)
        }
        XCTAssertEqual(EggId.allCases.count, 13)
    }
    func testNoContainerAllowsTakingWrongToolOrTakingBeforeOpen() {
        let s = StoreHarness.make(); s.room = .hall; s.openMemory(.drawer)
        s.pickup(.eraser, from: .drawer); XCTAssertTrue(s.exploration.tools.isEmpty)
        s.memories.opened.insert("drawer"); s.pickup(.coin, from: .drawer)
        XCTAssertTrue(s.exploration.tools.isEmpty)
        s.pickup(.eraser, from: .drawer); s.consume(.eraser); s.pickup(.eraser, from: .drawer)
        XCTAssertTrue(s.exploration.tools.isEmpty)
    }
}

@MainActor
final class GelatoFlowTests: XCTestCase {
    func testCloseupCannotWalkAndBackKeepsSideView() {
        let store = StoreHarness.make()
        store.room = .gelato
        store.exploration.views[Room.gelato.rawValue] = 1
        store.openMemory(.dispenser)
        store.tapDiegetic(.gelatoBack)
        XCTAssertEqual(store.room, .gelato)
        store.backFromMemory()
        XCTAssertEqual(store.sceneView, 1)
        store.turnView(-1)
        store.openMemory(.tasting)
        store.tapDiegetic(.gelatoBack)
        XCTAssertEqual(store.room, .gelato, "Hidden scene exits must not activate through an inspection")
        store.backFromMemory()
        store.tapDiegetic(.gelatoBack)
        XCTAssertEqual(store.room, .bedroom)
    }

    func testMenuDraftWrongTasteAndHotelRoundtripSurviveReload() {
        let suite = "ivy.gelato.tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = GameStore(defaults: defaults)
        store.isIntro = false; store.prefersReducedMotion = true
        store.room = .gelato; store.overlay = .none
        store.collected = [.letter, .vuori]
        store.openMemory(.menu)
        store.swapMenu(0, 1)
        let draft = store.memories.menu
        store.confirmMenu()
        XCTAssertFalse(store.memories.menuSolved)
        XCTAssertEqual(store.memories.menu, draft)
        XCTAssertEqual(store.sceneHintTone, .wrong)
        store.backFromMemory(); store.tapDiegetic(.gelatoBack)
        XCTAssertEqual(store.room, .bedroom)
        store.persistNow()
        let restored = GameStore(defaults: defaults)
        restored.isIntro = false; restored.prefersReducedMotion = true
        XCTAssertEqual(restored.room, .bedroom)
        XCTAssertEqual(restored.collected, [.letter, .vuori])
        restored.tapDiegetic(.bedroomForward)
        XCTAssertEqual(restored.room, .gelato)
        XCTAssertEqual(restored.memories.menu, draft)
        restored.openMemory(.menu)
        restored.swapMenu(1, 3); restored.swapMenu(2, 3); restored.confirmMenu()
        XCTAssertTrue(restored.memories.menuSolved)
        restored.acquire(.coin); restored.openMemory(.dispenser)
        restored.chooseTool(.coin); restored.openContainer(.dispenser)
        restored.backFromMemory(); restored.openMemory(.dispenser)
        XCTAssertTrue(restored.memories.opened.contains("dispenser"))
        XCTAssertFalse(restored.exploration.tools.contains(.coin))
        restored.pickup(.scoop, from: .dispenser)
        restored.openMemory(.tasting); restored.taste(0); restored.confirmTaste()
        XCTAssertEqual(restored.memories.flavor, 0)
        XCTAssertTrue(restored.exploration.tools.contains(.scoop))
        restored.persistNow()
        let again = GameStore(defaults: defaults)
        again.isIntro = false; again.prefersReducedMotion = true
        XCTAssertEqual(again.memories.flavor, 0)
        XCTAssertTrue(again.memories.menuSolved)
        again.openMemory(.tasting); again.taste(2); again.confirmTaste()
        XCTAssertEqual(again.collected, [.letter, .vuori, .gelato])
        XCTAssertFalse(again.exploration.tools.contains(.scoop))
        again.finishCollection(.gelato); again.backFromMemory()
        again.tapDiegetic(.gelatoBack)
        XCTAssertEqual(again.room, .bedroom)
    }

    func testSpoonDishIsOptionalEnglishMemoryAndDoesNotAwardAgain() {
        let store = StoreHarness.make(); store.room = .gelato
        store.openMemory(.tasting); store.recallGelatoJoke()
        XCTAssertTrue(store.sceneHint.isEmpty)
        store.collected.insert(.gelato)
        store.recallGelatoJoke()
        XCTAssertTrue(store.sceneHint.contains("your review"))
        XCTAssertEqual(store.sceneHintPresentation, .interaction)
        XCTAssertEqual(store.collected, [.gelato])
        XCTAssertNil(store.collectingEgg)
        store.dismissSceneHint()
        XCTAssertEqual(store.overlay, .memory(.tasting))
        store.openMemory(.menu); store.openMemory(.tasting)
        store.backFromMemory()
        XCTAssertEqual(store.overlay, .none, "Menu cross-links must not leave a navigation loop")
    }

    func testMenuBackReturnsToRainPaperThenOriginalBench() {
        let store = StoreHarness.make(); store.room = .gelato
        store.exploration.views[Room.gelato.rawValue] = -1
        store.overlay = .adventure(.recipe); store.openMemory(.menu)
        store.swapMenu(0, 1)
        let draft = store.memories.menu
        store.backFromMemory()
        XCTAssertEqual(store.overlay, .adventure(.recipe))
        store.cancelOverlay()
        XCTAssertEqual(store.sceneView, -1)
        XCTAssertEqual(store.memories.menu, draft)
    }

    func testHotelExitDoesNotOverlapCounterOrAmbientHotspots() throws {
        let store = StoreHarness.make(); store.room = .gelato
        let exit = try XCTUnwrap(RoomGraph.hotspots(in: .gelato).first { $0.edge == .gelatoBack })
        XCTAssertTrue(exit.label.contains("hotel"))
        for spot in store.explorationSpots { XCTAssertFalse(exit.rect.intersects(spot.rect)) }
        for spot in store.memoryHotspots { XCTAssertFalse(exit.rect.intersects(spot.rect)) }
    }
}
