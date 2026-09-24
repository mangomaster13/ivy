import XCTest
@testable import Ivy

@MainActor
final class WonderlandTests: XCTestCase {
    func testPerfumeBenchWorksInSceneWithoutOpeningAnotherPage() {
        let store = StoreHarness.make()
        store.room = .perfume
        store.exploration.views[Room.perfume.rawValue] = 4
        let ingredients: [AdventureTool] = [.gaiacWood, .musk, .cedar, .bergamot]
        store.perfumery.found.formUnion(ingredients)
        ingredients.forEach(store.acquire)

        XCTAssertFalse(store.explorationSpots.contains {
            if case .memory(.perfumeMix) = $0.action { return true }
            return false
        })
        store.blendPerfume()
        XCTAssertEqual(store.sceneHint, "The mixing trays are empty.")
        XCTAssertEqual(store.overlay, .none)
        XCTAssertTrue(store.memoryNavigation.isEmpty)
        XCTAssertNil(store.perfumery.output)

        store.putIngredient(.gaiacWood, at: 0)
        store.blendPerfume()
        XCTAssertEqual(store.sceneHint, "The mixture is still incomplete.")
        XCTAssertEqual(store.perfumery.mixture, [.gaiacWood, nil, nil])
        store.putIngredient(.musk, at: 1)
        store.putIngredient(.bergamot, at: 2)
        store.blendPerfume()
        XCTAssertEqual(store.perfumery.mixture, [.gaiacWood, .musk, .bergamot])
        XCTAssertNil(store.perfumery.output)

        store.putIngredient(.cedar, at: 2)
        XCTAssertTrue(store.exploration.tools.contains(.bergamot))
        store.removeIngredient(at: 1)
        XCTAssertTrue(store.exploration.tools.contains(.musk))
        store.putIngredient(.musk, at: 1)

        store.openNotebook()
        store.removeIngredient(at: 0)
        store.blendPerfume()
        XCTAssertEqual(store.perfumery.mixture, [.gaiacWood, .musk, .cedar])
        XCTAssertNil(store.perfumery.output)
        store.closeNotebook()
        store.turnView(-1)
        store.blendPerfume()
        XCTAssertNil(store.perfumery.output)
        store.turnView(1)
        store.blendPerfume()
        XCTAssertEqual(store.perfumery.output, .gaiac10)
        XCTAssertTrue(store.perfumery.mixture.allSatisfy { $0 == nil })
        XCTAssertTrue(Set(ingredients).isSubset(of: store.exploration.tools))
        XCTAssertFalse(store.exploration.tools.contains(.gaiac10))

        store.blendPerfume()
        XCTAssertEqual(store.sceneHint, "A finished bottle is still under the press.")
        XCTAssertEqual(store.perfumery.output, .gaiac10)
        store.takePerfume()
        store.takePerfume()
        XCTAssertNil(store.perfumery.output)
        XCTAssertTrue(store.exploration.tools.contains(.gaiac10))
        XCTAssertEqual(store.perfumery.brewed, [.gaiac10])
        XCTAssertEqual(store.overlay, .none)
        XCTAssertEqual(store.sceneView, 4)
        XCTAssertTrue(store.memoryNavigation.isEmpty)
        XCTAssertTrue(store.collected.isEmpty)
    }

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

    func testGelatoRequiresExplicitSpoonAfterFlavorInput() {
        let s = StoreHarness.make(); s.room = .gelato
        s.openMemory(.menu)
        GelatoWordProgress.answer.forEach(s.selectGelatoWord); s.submitGelatoChain()
        s.setGelatoFlavorDraft("jasmine"); s.submitGelatoFlavor()
        s.openMemory(.tasting)
        XCTAssertEqual(s.overlay, .memory(.menu), "Missing spoon leaves the current view in place")
        s.acquire(.scoop); s.openMemory(.tasting)
        s.taste(2); XCTAssertFalse(s.collected.contains(.gelato))
        s.chooseTool(.scoop); s.taste(2)
        XCTAssertTrue(s.collected.contains(.gelato))
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
        GelatoWordProgress.answer.forEach(s.selectGelatoWord); s.submitGelatoChain()
        s.setGelatoFlavorDraft("jasmine"); s.submitGelatoFlavor()
        XCTAssertTrue(s.gelatoWords.flavorSolved)
        s.openMemory(.dispenser); s.chooseTool(.coin); s.openContainer(.dispenser)
        XCTAssertFalse(s.exploration.tools.contains(.coin)); XCTAssertFalse(s.exploration.tools.contains(.scoop))
        s.pickup(.scoop, from: .dispenser); s.openMemory(.tasting); s.chooseTool(.scoop); s.taste(2)
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
        let cases: [(Room, MemoryPanel, EggId)] = [(.noodle,.bigTop,.noodle),(.perfume,.perfume,.perfume),(.cinema,.cinema,.cinema),(.taxi,.taxi,.taxi)]
        for (room, panel, egg) in cases {
            s.room = room; s.openMemory(panel); s.collectPhysical(egg)
            XCTAssertFalse(s.collected.contains(egg))
            switch panel {
            case .bigTop: s.memories.bigTopDraft = "BIGTOP"
            case .perfume: s.memories.scents = [10,30,22]
            case .cinema: s.memories.cinemaDraft = "hope"; s.memories.cinemaSeats = [2,3]
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

    func testGelatoChainDraftSurvivesHotelRoundtrip() {
        let store = StoreHarness.make(); store.room = .gelato
        store.openMemory(.menu)
        [4, 2, 6].forEach(store.selectGelatoWord)
        store.submitGelatoChain()
        XCTAssertFalse(store.gelatoWords.chainSolved)
        XCTAssertEqual(store.gelatoWords.order, [4, 2, 6])
        store.backFromMemory(); store.tapDiegetic(.gelatoBack)
        XCTAssertEqual(store.room, .bedroom)
        store.tapDiegetic(.bedroomForward); store.openMemory(.menu)
        XCTAssertEqual(store.gelatoWords.order, [4, 2, 6])
    }

    func testOwnedGelatoOpensElementWithoutAwardingAgain() {
        let store = StoreHarness.make(); store.room = .gelato
        store.collected.insert(.gelato)
        store.openMemory(.tasting)
        XCTAssertEqual(store.overlay, .observation(.gelato))
        XCTAssertEqual(store.collected, [.gelato])
        XCTAssertNil(store.collectingEgg)
    }

    func testMenuBackReturnsToRainPaperThenOriginalBench() {
        let store = StoreHarness.make(); store.room = .gelato
        store.exploration.views[Room.gelato.rawValue] = -1
        store.overlay = .adventure(.recipe); store.openMemory(.menu)
        store.selectGelatoWord(4)
        let draft = store.gelatoWords.order
        store.backFromMemory()
        XCTAssertEqual(store.overlay, .adventure(.recipe))
        store.cancelOverlay()
        XCTAssertEqual(store.sceneView, -1)
        XCTAssertEqual(store.gelatoWords.order, draft)
    }

    func testHotelExitDoesNotOverlapCounterOrAmbientHotspots() throws {
        let store = StoreHarness.make(); store.room = .gelato
        let exit = try XCTUnwrap(RoomGraph.hotspots(in: .gelato).first { $0.edge == .gelatoBack })
        XCTAssertTrue(exit.label.contains("hotel"))
        for spot in store.explorationSpots { XCTAssertFalse(exit.rect.intersects(spot.rect)) }
        for spot in store.memoryHotspots { XCTAssertFalse(exit.rect.intersects(spot.rect)) }
    }
}

@MainActor
final class BigTopMenuPuzzleTests: XCTestCase {
    func testToolsEvidenceDrawerAndPersistentOrder() throws {
        let store = StoreHarness.make()
        store.room = .noodle
        store.exploration.views[Room.noodle.rawValue] = 1
        store.openMemory(.bigTopLedger)
        XCTAssertEqual(store.overlay, .none, "No inert tool-only page")
        store.takeBigTopTool(.bigTopPencil)
        store.takeBigTopTool(.bigTopInspectionMirror)
        XCTAssertNil(store.selectedTool)
        store.openMemory(.bigTopLedger)
        store.revealBigTopLedger()
        XCTAssertFalse(store.exploration.clues.contains(.bigTopLedger), "Holding is not using")
        store.chooseTool(.bigTopPencil)
        store.revealBigTopLedger()
        XCTAssertTrue(store.exploration.clues.contains(.bigTopLedger))
        store.backFromMemory()
        store.chooseTool(.bigTopInspectionMirror)
        store.inspectBigTopMirror()
        XCTAssertEqual(store.overlay, .memory(.bigTopMirror))
        XCTAssertTrue(store.exploration.clues.contains(.bigTopMirror))
        XCTAssertFalse(store.exploration.tools.contains(.bigTopInspectionMirror))
        store.backFromMemory()
        store.openMemory(.bigTopMenuSearch)
        let shuffle = store.bigTop.menuOrder
        store.openBigTopMenuDrawer()
        XCTAssertNotEqual(store.bigTop.menuDrawerOpen, true)
        XCTAssertEqual(store.bigTop.drawerSymbols, [1, 3, 2, 4])
        for (index, target) in BigTopMenu.drawerAnswer.enumerated() {
            for _ in 0..<8 where store.bigTop.drawerSymbols?[index] != target { store.turnBigTopSymbol(index) }
        }
        store.openBigTopMenuDrawer()
        XCTAssertEqual(store.bigTop.menuDrawerOpen, true)
        XCTAssertFalse(store.exploration.tools.contains(.dinnerMenu), "Opening never picks up")
        store.takeBigTopMenu()
        XCTAssertTrue(store.exploration.tools.contains(.dinnerMenu))
        XCTAssertFalse(store.exploration.tools.contains(.bigTopPencil))
        store.backFromMemory()
        store.openMemory(.bigTopOrder)
        store.chooseTool(.dinnerMenu)
        store.placeBigTopMenu()
        XCTAssertEqual(store.overlay, .memory(.bigTopMenu))
        store.selectDish(1)
        store.placeDinnerOrder()
        XCTAssertEqual(store.bigTop.order, [1])
        XCTAssertFalse(store.bigTop.orderSolved)
        store.selectDish(1)
        for id in BigTopMenu.answer { store.selectDish(id) }
        store.placeDinnerOrder()
        XCTAssertTrue(store.bigTop.orderSolved)
        XCTAssertTrue(store.bigTop.streetUnlocked)
        let restored = try JSONDecoder().decode(BigTopProgress.self, from: JSONEncoder().encode(store.bigTop))
        XCTAssertEqual(restored.menuOrder, shuffle)
        XCTAssertEqual(restored.order, BigTopMenu.answer)
        store.backFromMemory()
        store.openMemory(.bigTop)
        XCTAssertTrue(store.collected.contains(.noodle))
    }

    func testLegacyMenuProgressKeepsIdentityAndCompletion() throws {
        // Missing optional new fields must not invalidate an existing save.
        let legacy = Data("""
        {"signDraft":"BIGTOP","signSolved":true,"menuRevealed":true,
         "menuTaken":true,"menuPlaced":true,"menuPage":3,"order":[0,6,18],
         "orderSolved":false,"streetUnlocked":true}
        """.utf8)
        var progress = try JSONDecoder().decode(BigTopProgress.self, from: legacy)
        progress.prepareMenu()
        XCTAssertEqual(progress.order, [0, 6])
        XCTAssertEqual(progress.menuDrawerOpen, true)
        XCTAssertTrue(progress.streetUnlocked)
        XCTAssertEqual(Set(progress.menuOrder ?? []), Set(BigTopMenu.availableIDs))
        let shuffle = progress.menuOrder
        progress.prepareMenu()
        XCTAssertEqual(progress.menuOrder, shuffle)
        progress.orderSolved = true
        progress.prepareMenu()
        XCTAssertTrue(progress.orderSolved)
        XCTAssertTrue(progress.menuPlaced)
        XCTAssertEqual(AdventureTool(rawValue: "pencil"), .eraser)
        XCTAssertNotEqual(AdventureTool.bigTopPencil.rawValue, "pencil")
    }
    func testCinemaRequiresSelectedFilmAndCompleteProjectionAndPreservesLegacy() throws {
        let store = StoreHarness.make()
        store.room = .cinema
        store.openMemory(.cinemaProjector)
        XCTAssertEqual(store.overlay, .none)
        store.openMemory(.cinemaCase)
        XCTAssertTrue(store.cinema.caseOpened)
        XCTAssertFalse(store.exploration.tools.contains(.cinemaFilm))
        store.takeCinemaFilm()
        XCTAssertNil(store.selectedTool)
        store.openMemory(.cinemaProjector)
        store.insertCinemaFilm()
        XCTAssertFalse(store.cinema.filmInserted)
        store.chooseTool(.cinemaFilm)
        store.insertCinemaFilm()
        XCTAssertEqual(store.overlay, .memory(.cinema))
        XCTAssertFalse(store.exploration.tools.contains(.cinemaFilm))
        XCTAssertFalse(store.cinema.projectionReady)
        store.selectCinemaSeat(12)
        XCTAssertTrue(store.cinema.seats.isEmpty, "Seats cannot bypass the optical puzzle")
        let draft = store.cinema.layers
        store.submitCinemaProjection()
        XCTAssertEqual(store.cinema.layers, draft)
        XCTAssertFalse(store.cinema.projectionReady)
        for index in 0..<3 {
            store.selectCinemaFilm(index)
            store.moveCinemaFilm(x: 14, y: -8)
            if store.cinema.layers[index].flipped { store.flipCinemaFilm() }
        }
        XCTAssertTrue(store.cinema.aligned, "A common translation is a valid whole image")
        XCTAssertFalse(store.cinema.projectionReady, "Matching alone must not reveal the heart")
        store.flipCinemaFilm()
        store.submitCinemaProjection()
        XCTAssertFalse(store.cinema.projectionReady, "All three films must face forward")
        store.flipCinemaFilm()
        store.openMemory(.cinemaProjector)
        store.insertCinemaFilm()
        XCTAssertEqual(store.cinema.layers.map(\.x), [14, 14, 14])
        XCTAssertTrue(store.cinema.filmInserted)
        XCTAssertFalse(store.exploration.tools.contains(.cinemaFilm), "Installed film never returns to inventory")
        store.openMemory(.cinema)
        store.submitCinemaProjection()
        XCTAssertTrue(store.cinema.projectionReady)
        XCTAssertEqual(store.cinema.layers.map(\.x), [14, 14, 14], "Project must not teleport the assembled image")
        XCTAssertEqual(store.cinema.layers.map(\.y), [-8, -8, -8])
        XCTAssertEqual(store.cinema.projectionOffset, CGPoint(x: 14, y: -8))
        let seat = CinemaLayout.seatCenter(12, offset: store.cinema.projectionOffset)
        XCTAssertEqual(seat.x, CinemaLayout.seatCenter(12).x + 14)
        XCTAssertEqual(seat.y, CinemaLayout.seatCenter(12).y - 8)
        var legacySolved = CinemaProgress(solved: true)
        legacySolved.sanitize()
        XCTAssertTrue(legacySolved.filmInserted)
        XCTAssertTrue(legacySolved.aligned)
        store.migrateCinema()
        XCTAssertEqual(store.cinema.layers.map(\.x), [14, 14, 14], "Restoring must keep the projection in place")
        XCTAssertFalse(store.collected.contains(.cinema))
        store.selectCinemaSeat(0)
        store.selectCinemaSeat(1)
        store.submitCinemaSeats()
        XCTAssertEqual(store.cinema.seats, [0, 1])
        XCTAssertTrue(store.cinema.projectionReady)
        XCTAssertFalse(store.cinema.solved)
        store.selectCinemaSeat(0)
        store.selectCinemaSeat(1)
        store.selectCinemaSeat(12)
        store.selectCinemaSeat(13)
        let restored = try JSONDecoder().decode(MemoryProgress.self, from: JSONEncoder().encode(store.memories))
        XCTAssertEqual(restored.cinema, store.cinema)
        store.submitCinemaSeats()
        XCTAssertTrue(store.collected.contains(.cinema))
        XCTAssertEqual(store.overlay, .observation(.cinema))
        store.cancelOverlay()
        store.migrateCinema()
        XCTAssertEqual(store.cinema.seats, [12, 13])
        XCTAssertEqual(store.cinema.layers.map(\.x), [14, 14, 14])
        XCTAssertFalse(store.exploration.tools.contains(.cinemaFilm))

        let legacy = StoreHarness.make()
        let oldFilm = Data("""
        {"caseOpened":true,"filmTaken":true,"filmInserted":true,"flipped":false,
         "x":18,"y":-7,"seats":[12],"solved":false,"exitUnlocked":false}
        """.utf8)
        legacy.memories.cinema = try JSONDecoder().decode(CinemaProgress.self, from: oldFilm)
        legacy.migrateCinema()
        XCTAssertEqual(legacy.cinema.layers[0], CinemaFilmPosition(x: 18, y: -7, flipped: false))
        XCTAssertEqual(legacy.cinema.layers.count, 3)
        XCTAssertFalse(legacy.cinema.projectionReady)
        XCTAssertEqual(legacy.cinema.seats, [12])
        legacy.memories.opened.insert("cinema")
        legacy.migrateCinema()
        XCTAssertTrue(legacy.cinema.complete)
        XCTAssertTrue(legacy.collected.contains(.cinema))
        XCTAssertNil(legacy.collectingEgg)
        legacy.memories = MemoryProgress()
        legacy.collected = []
        legacy.room = .dictionary
        legacy.migrateCinema()
        XCTAssertTrue(legacy.cinema.exitUnlocked)
        XCTAssertFalse(legacy.collected.contains(.cinema))
    }

}
