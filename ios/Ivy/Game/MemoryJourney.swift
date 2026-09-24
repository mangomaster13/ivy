import SwiftUI

/// Independent physical facts prevent consumed tools from respawning in an opened container.
struct MemoryProgress: Codable {
    var opened: Set<String> = []
    var picked: Set<AdventureTool> = []
    var used: Set<AdventureTool> = []
    var origin: String? = nil
    var destination: String? = nil
    var menu: [Int] = [2, 0, 3, 1]
    var menuSolved = false
    var flavor: Int? = nil
    var folds: Set<Int> = []
    // Optional so saves written before the three-petal puzzle still decode.
    var rose: RoseProgress? = nil
    var bedroomLampOn: Bool? = nil
    var gelatoWater: GelatoWaterProgress? = nil
    var gelatoWords: GelatoWordProgress? = nil
    var cityPieces: [Int] = [2, 0, 3, 1]
    var citySolved = false
    // Retain old placement data for migration into the nine-piece grid.
    var cityJigsaw: Set<Int>? = [] // Legacy six-piece save data.
    var cityGrid: Set<Int>? = [] // Legacy correct-only placements.
    var cityBoard: [Int?]? = Array(repeating: nil, count: 9) // Slot -> piece; wrong placements are persistent.
    var cityLooseOrder: [Int]? = nil // First visit shuffles the nine loose positions once.
    var legacyRoomAccess: Bool? = nil
    var scents: [Int] = [30, 22, 10]
    var cinema: CinemaProgress? = nil
    var cinemaSeats: Set<Int> = [] // Legacy decoding only.
    var sunsetFrame = 0.15 // Legacy decoding only.
    var dictionary: DictionaryProgress? = nil
    var ferrisMatches: Set<Int> = [] // Legacy pair matching, migration only.
    var ferris: FerrisProgress? = nil
    var taxi: TaxiProgress? = nil
    var bigTop: BigTopProgress? = nil
    var perfumery: PerfumeProgress? = nil
    // Stable clue identity survives new discoveries and decodes from older saves.
    var notebookClue: AdventureClue? = nil
    var bigTopDraft = ""
    var wholeDraft = ""
    var taxiDraft = ""
    var cinemaDraft = ""
    var bathWarm = false
    var bathRevealed = false
    var flightDeparted = false
    var routeCorrect: Bool { origin == "Hangzhou" && destination == "Hong Kong" }
    mutating func sanitize() {
        if !JourneyCity.all.contains(where: { $0.name == origin }) { origin = nil }
        if !JourneyCity.all.contains(where: { $0.name == destination }) { destination = nil }
        if menu.count != 4 || Set(menu) != Set(0..<4) { menu = [2, 0, 3, 1] }
        if cityPieces.count != 4 || Set(cityPieces) != Set(0..<4) { cityPieces = [2, 0, 3, 1] }
        if let placed = cityJigsaw { cityJigsaw = placed.intersection(0..<6) }
        if let placed = cityGrid { cityGrid = placed.intersection(0..<9) }
        if let board = cityBoard {
            var seen = Set<Int>()
            cityBoard = (0..<9).map { slot in
                guard slot < board.count, let piece = board[slot], (0..<9).contains(piece),
                      seen.insert(piece).inserted else { return nil }
                return piece
            }
        }
        if let order = cityLooseOrder, order.count != 9 || Set(order) != Set(0..<9) { cityLooseOrder = nil }
        gelatoWater?.sanitize()
        gelatoWords?.sanitize()
        if scents.count != 3 || Set(scents) != [10, 22, 30] { scents = [30, 22, 10] }
        if let flavor, !(0..<4).contains(flavor) { self.flavor = nil }
        folds = folds.intersection([0, 1]); cinemaSeats = cinemaSeats.intersection(0..<6)
        ferrisMatches = ferrisMatches.intersection([0, 1]); sunsetFrame = min(1, max(0, sunsetFrame))
        taxi?.sanitize()
    }
}

enum MemoryPanel: String, CaseIterable {
    case ferrisTicket, ferrisGate, ferrisCabin, ferrisCamera
    case cinemaCase, cinemaProjector, cinemaTicket
    case gelatoOrder, gelatoNote, dictionarySong
    case pot, drawer, linen, wholeBox, dispenser, flight, ticket, travelBook, yunnan, bouquet, city, bath, menu, tasting, keycard
    case bigTop, mexican, perfume, cinema, dictionary, ferris, taxi, taxiCard, taxiReceipt, blanket
    case bigTopSign, bigTopMenuSearch, bigTopOrder, bigTopMenu, bigTopLedger, bigTopMirror, rainGutter
    case perfumeWood, perfumeBotanical, perfumeSpice, perfumeLab, perfumeFormula, perfumeMix
    var tools: [AdventureTool] {
        switch self {
        case .pot: [.brassKey]
        case .drawer: [.eraser]
        case .linen: [.cloth]
        case .wholeBox: [.coin]
        case .dispenser: [.scoop]
        default: []
        }
    }
    var room: Room {
        switch self {
        case .pot: .yard
        case .drawer: .hall
        case .linen, .keycard: .corridor
        case .wholeBox, .bouquet, .city, .bath, .blanket: .bedroom
        case .flight, .ticket, .travelBook, .yunnan: .plane
        case .dispenser, .menu, .tasting, .rainGutter, .gelatoOrder, .gelatoNote: .gelato
        case .bigTop, .mexican, .bigTopMenuSearch, .bigTopOrder, .bigTopMenu, .bigTopLedger, .bigTopMirror: .noodle
        case .bigTopSign: .gelato
        case .perfume, .perfumeWood, .perfumeBotanical, .perfumeSpice, .perfumeLab, .perfumeFormula, .perfumeMix: .perfume
        case .cinema, .cinemaCase, .cinemaProjector, .cinemaTicket: .cinema
        case .dictionary, .dictionarySong: .dictionary
        case .ferris, .ferrisTicket, .ferrisGate, .ferrisCabin, .ferrisCamera: .ferris
        case .taxi, .taxiCard, .taxiReceipt: .taxi
        }
    }
}

struct JourneyCity: Identifiable {
    let name: String
    let longitude: Double, latitude: Double
    var id: String { name }
    static let all = [
        Self(name: "Beijing", longitude: 116.4074, latitude: 39.9042),
        Self(name: "Hangzhou", longitude: 120.1551, latitude: 30.2741),
        Self(name: "Hong Kong", longitude: 114.1694, latitude: 22.3193),
        Self(name: "Kunming", longitude: 102.8329, latitude: 24.8801),
        Self(name: "Chengdu", longitude: 104.0665, latitude: 30.5723),
        Self(name: "Harbin", longitude: 126.6424, latitude: 45.7560),
        Self(name: "Xian", longitude: 108.9398, latitude: 34.3416),
        Self(name: "Lhasa", longitude: 91.1322, latitude: 29.6604),
        Self(name: "Urumqi", longitude: 87.6168, latitude: 43.8256),
        Self(name: "Sanya", longitude: 109.5119, latitude: 18.2528)
    ]
}

enum RememberedFlavor {
    static let names = ["Pomelo, Mandarin & Pink Peppercorn", "Magnolia & Fresh Longan", "White Loquat & Jasmine", "Basil & Green Tomato"]
    static let labels = ["Citrus & Pepper", "Magnolia & Longan", "Loquat & Jasmine", "Basil & Tomato"]
    static let ingredients = ["pomelo · mandarin\npink peppercorn", "magnolia\nfresh longan", "white loquat\njasmine", "basil\ngreen tomato"]
    static let notes = ["Bright citrus, then a little pepper.", "Longan sweetness, a magnolia finish.", "Pale fruit, jasmine, and a very particular memory.", "Green tomato, sweet basil, a garden after rain."]
}

extension GameStore {
    func openMemory(_ requestedPanel: MemoryPanel) {
        let panel: MemoryPanel
        if requestedPanel == .bigTop && !bigTop.orderSolved { panel = .bigTopMenuSearch }
        else if requestedPanel == .bigTopOrder && bigTop.menuPlaced { panel = .bigTopMenu }
        else if requestedPanel == .rainGutter { panel = .gelatoOrder }
        else if requestedPanel == .menu && collected.contains(.gelato) { panel = .tasting }
        else if requestedPanel == .tasting && !gelatoWords.flavorSolved && !collected.contains(.gelato) { panel = .menu }
        else { panel = requestedPanel }
        guard room == panel.room, !isHallTransitioning, collectingEgg == nil else { return }
        if panel == .tasting, collected.contains(.gelato) {
            replayKeepsake(.gelato)
            return
        }
        if panel == .bouquet, collected.contains(.rose) {
            replayKeepsake(.rose)
            return
        }
        if panel == .dictionary, collected.contains(.dictionary) {
            replayKeepsake(.dictionary)
            return
        }
        if panel == .cinema, collected.contains(.cinema) {
            replayKeepsake(.cinema)
            return
        }
        if panel == .taxiReceipt, collected.contains(.taxi) {
            replayKeepsake(.taxi)
            return
        }
        if panel.room == .perfume, sceneView == 0 { return }
        switch panel {
        case .taxi where !taxi.cardTaken:
            showSceneHint("A folded route card sits in the seat pocket.", presentation: .interaction)
            return
        case .taxiReceipt where !taxi.arrived:
            showSceneHint("The cab is still on its way.", presentation: .interaction)
            return
        case .ferrisTicket where !ferris.playlistSolved:
            showSceneHint("The ticket is waiting on a few familiar songs.", presentation: .interaction)
            return
        case .ferrisCabin where !ferris.ticketUsed:
            showSceneHint("The gate hasn't let us through yet.", presentation: .interaction)
            return
        case .ferrisCamera:
            guard ferris.ticketUsed else { return }
            if ferris.photoTaken { replayKeepsake(.ferris); return }
            guard ferris.phoneTaken, selectedTool == .ferrisPhone,
                  exploration.tools.contains(.ferrisPhone) else { hintForTool(.ferrisPhone); return }
        case .cinemaProjector where !cinema.filmInserted && !cinema.solved:
            guard requireInteractionTool(.cinemaFilm, missing: "An empty space where the film should be.") else { return }
        case .bigTopLedger where !exploration.clues.contains(.bigTopLedger):
            guard requireInteractionTool(.bigTopPencil, missing: "Faint impressions linger in the paper.") else { return }
        case .bigTopMirror:
            guard exploration.clues.contains(.bigTopMirror) else { return }
        case .bigTopOrder where !bigTop.menuPlaced:
            guard requireInteractionTool(.dinnerMenu, missing: "The clipboard is missing its menu.") else { return }
        case .drawer where !memories.opened.contains("drawer"):
            guard requireInteractionTool(.brassKey, missing: "A small keyhole beneath the handle.") else { return }
        case .dispenser where !memories.opened.contains("dispenser"):
            guard requireInteractionTool(.coin, missing: "A small slot, just the size of a token.") else { return }
        case .tasting where !collected.contains(.gelato):
            guard requireInteractionTool(.scoop, missing: "Just missing a spoon.") else { return }
        default: break
        }
        if panel == .bigTopMenu && !bigTop.menuPlaced { return }
        if [.bigTopMenuSearch, .bigTopMenu].contains(panel) { prepareBigTopMenu() }
        if panel == .perfumeFormula { discover(PerfumeFormula.all[perfumery.formulaPage].clue) }
        if panel == .perfume { discover(.perfumeOrder) }
        if panel == .perfumeSpice { perfumery.opened.insert("spice"); persistNow() }
        if panel == .flight {
            guard sceneView == 0 else { return }
            if memories.flightDeparted {
                transition(to: .corridor)
                return
            }
            guard exploration.tools.contains(.ticket) else {
                showSceneHint("A ticket is missing from this journey.", presentation: .interaction)
                return
            }
        }
        if panel == .ticket { guard exploration.tools.contains(.ticket) else { return } }
        if case .memory(let current) = overlay {
            guard current != panel else { return }
            if let ancestor = memoryNavigation.firstIndex(of: panel) {
                memoryNavigation = Array(memoryNavigation.prefix(ancestor))
            } else {
                memoryNavigation.append(current)
            }
        } else {
            returnToRecipe = overlay == .adventure(.recipe) && panel == .menu
            memoryNavigation = []
        }
        if panel == .cinemaTicket { discover(.cinemaTicket) }
        if panel == .dictionary { discover(.dictionaryEntries) }
        if panel == .dictionarySong { discover(.dictionaryLyric) }
        if panel == .taxiCard, taxi.cardTaken { discover(.taxiRoute) }
        if panel == .taxiReceipt && !taxi.receiptPrinted {
            taxi.receiptPrinted = true
            persistNow()
        }
        if panel == .menu { discover(.recipe) }
        if panel == .gelatoOrder { discover(.gelatoOrder) }
        if panel == .gelatoNote { discover(.gelatoLeaves) }
        if panel == .city, memories.cityLooseOrder == nil {
            memories.cityLooseOrder = Array(0..<9).shuffled()
            persistNow()
        }
        sceneHint = ""; overlay = .memory(panel)
        if panel == .cinemaCase { openCinemaCase() }
        if panel == .bigTopSign { persistNow() }
        if panel == .bigTop && bigTop.orderSolved { collectDinner() }
        if panel == .perfume && perfumery.arranged && !collected.contains(.perfume) { collectPerfumes() }
    }
    func backFromMemory() {
        guard case .memory = overlay else { return }
        sceneHint = ""
        if let previous = memoryNavigation.popLast(), previous.room == room {
            overlay = .memory(previous)
        } else if returnToRecipe {
            returnToRecipe = false
            overlay = .adventure(.recipe)
        } else {
            cancelOverlay()
        }
    }
    func consume(_ tool: AdventureTool) {
        exploration.tools.remove(tool); memories.picked.insert(tool); memories.used.insert(tool)
        if selectedTool == tool { selectedTool = nil }
        persistNow()
    }
    func openContainer(_ panel: MemoryPanel) {
        guard overlay == .memory(panel), room == panel.room, !memories.opened.contains(panel.rawValue) else { return }
        switch panel {
        case .pot, .linen: break
        case .drawer:
            guard use(.brassKey) else { return }
            consume(.brassKey); exploration.drawerOpened = true
        case .dispenser:
            guard use(.coin) else { return }
            consume(.coin)
        default: return
        }
        withAnimation(prefersReducedMotion ? nil : .easeInOut(duration: 0.65)) { memories.opened.insert(panel.rawValue) }
        sceneHint = ""; IvyHaptics.light(); persistNow()
    }
    func pickup(_ tool: AdventureTool, from panel: MemoryPanel) {
        guard room == panel.room, overlay == .memory(panel), memories.opened.contains(panel.rawValue),
              panel.tools.contains(tool), !memories.picked.contains(tool) else { return }
        memories.picked.insert(tool); acquire(tool); sceneHint = ""
        persistNow()
    }
    func submitWhole() {
        guard room == .bedroom, overlay == .memory(.wholeBox), !memories.opened.contains("wholeBox") else { return }
        let answer = memories.wholeDraft.lowercased().components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }.joined(separator: " ")
        guard answer == "as a whole" else { dismissSceneHint(); return }
        withAnimation(prefersReducedMotion ? nil : .easeInOut(duration: 0.65)) { memories.opened.insert("wholeBox") }
        exploration.musicBoxOpened = true; sceneHint = ""; IvyHaptics.success(); persistNow()
    }
    func selectCity(_ name: String) {
        guard overlay == .memory(.flight), room == .plane, JourneyCity.all.contains(where: { $0.name == name }) else { return }
        if memories.origin == name { memories.origin = nil; memories.destination = nil }
        else if memories.destination == name { memories.destination = nil }
        else if memories.origin == nil || memories.destination != nil { memories.origin = name; memories.destination = nil }
        else { memories.destination = name }
        sceneHint = ""
        persistNow()
    }
    var canDepart: Bool { memories.routeCorrect && exploration.clues.contains(.travelOrder) && exploration.tools.contains(.ticket) }
    func takeTicket() {
        guard room == .plane, overlay == .memory(.travelBook),
              !memories.picked.contains(.ticket) else { return }
        memories.picked.insert(.ticket)
        acquire(.ticket)
        sceneHint = ""
        persistNow()
    }
    func prepareFlightDeparture() -> Bool {
        guard room == .plane, overlay == .memory(.flight), !isHallTransitioning else { return false }
        if !exploration.tools.contains(.ticket) {
            showSceneHint("A ticket is missing from this journey.", presentation: .interaction)
        } else if memories.origin == nil || memories.destination == nil {
            showSceneHint("The journey still needs its beginning and end.", presentation: .interaction)
        } else if !exploration.clues.contains(.travelOrder) {
            showSceneHint("Something is still hidden beneath the pencil marks.", presentation: .interaction)
        } else {
            dismissSceneHint()
            return canDepart
        }
        return false
    }

    func departFlight() {
        guard room == .plane, overlay == .memory(.flight), canDepart, !isHallTransitioning else { return }
        memories.flightDeparted = true
        consume(.ticket)
        if collected.contains(.plane) {
            transition(to: .corridor)
        } else {
            collect(.plane)
        }
        persistNow()
    }
    func swapCityPieces(_ a: Int, _ b: Int) {
        guard overlay == .memory(.city), room == .bedroom, !memories.citySolved,
              (0..<4).contains(a), (0..<4).contains(b) else { return }
        memories.cityPieces.swapAt(a, b)
        memories.citySolved = memories.cityPieces == [0, 1, 2, 3]; persistNow()
    }
    func placeCityPiece(_ piece: Int, at target: Int) {
        guard room == .bedroom, overlay == .memory(.city), !memories.citySolved,
              collectingEgg == nil, (0..<9).contains(piece), (0..<9).contains(target),
              var board = memories.cityBoard, board.count == 9 else { return }
        let source = board.firstIndex { $0 == piece }
        guard source != target else { return }
        let displaced = board[target]
        if let source { board[source] = displaced }
        // A displaced piece returns to the tray if the incoming piece came from it.
        board[target] = piece
        memories.cityBoard = board
        memories.citySolved = board.enumerated().allSatisfy { $0.element == $0.offset }
        if memories.citySolved { unlockAssemblyKeepsake(.city) }
        persistNow()
    }
    func returnCityPiece(_ piece: Int) {
        guard room == .bedroom, overlay == .memory(.city), !memories.citySolved,
              collectingEgg == nil, var board = memories.cityBoard,
              let slot = board.firstIndex(where: { $0 == piece }) else { return }
        board[slot] = nil
        memories.cityBoard = board
        persistNow()
    }
    func moveCityLoosePiece(_ piece: Int, to position: Int) {
        guard room == .bedroom, overlay == .memory(.city), !memories.citySolved,
              collectingEgg == nil, (0..<9).contains(piece), (0..<9).contains(position),
              var order = memories.cityLooseOrder,
              let source = order.firstIndex(of: piece) else { return }
        order.swapAt(source, position)
        memories.cityLooseOrder = order
        if memories.cityBoard?.contains(where: { $0 == piece }) == true { returnCityPiece(piece) }
        else { persistNow() }
    }
    // Legacy entry points cannot bypass the complete-chain and typed-answer gates.
    func confirmMenu() { submitGelatoChain() }
    func taste(_ index: Int) {
        guard room == .gelato, (overlay == .memory(.tasting) || overlay == .memory(.menu)), !isIntro,
              !isHallTransitioning, collectingEgg == nil, !collected.contains(.gelato),
              gelatoWords.flavorSolved, index == 2 else { return }
        guard selectedTool == .scoop, exploration.tools.contains(.scoop) else {
            hintForTool(.scoop)
            return
        }
        memories.flavor = 2
        consume(.scoop); collect(.gelato)
    }
    func confirmTaste() {
        if let flavor = memories.flavor { taste(flavor) }
    }
    func recallGelatoJoke() {
        guard room == .gelato, overlay == .memory(.tasting), collected.contains(.gelato), collectingEgg == nil else { return }
        replayKeepsake(.gelato)
    }
    func collectPhysical(_ egg: EggId) {
        guard case .memory(let panel) = overlay, room == panel.room else { return }
        let allowed: Bool
        switch (overlay, egg) {
        case (.memory(.bouquet), .rose): allowed = roseProgress.placed.count == 3
        case (.memory(.keycard), .keycard): allowed = corridorUnlocked
        case (.memory(.city), .city): allowed = memories.citySolved
        case (.memory(.bigTop), .noodle): collectDinner(); return
        case (.memory(.perfume), .perfume): collectPerfumes(); return
        case (.memory(.cinema), .cinema): allowed = memories.opened.contains("cinema")
        case (.memory(.dictionary), .dictionary): allowed = memories.opened.contains("dictionary")
        case (.memory(.ferris), .ferris): return // The camera owns this keepsake.
        case (.memory(.taxiReceipt), .taxi): takeTaxiReceipt(); return
        default: allowed = false
        }
        guard allowed, collectingEgg == nil else { return }; collect(egg)
    }
    func solveLater(_ panel: MemoryPanel) {
        // Retired word-answer entry point; existing callers cannot bypass physical puzzles.
    }
    func migrateMemories() {
        memories.sanitize()
        migrateDictionary()
        migrateCinema()
        migrateFerris()
        migrateTaxi()
        if memories.cityJigsaw == nil && memories.cityPieces == [2, 0, 3, 1] && !memories.citySolved {
            memories.cityJigsaw = []
        }
        if memories.cityGrid == nil {
            // Preserve completed image regions from the former 3-by-2 board.
            if let old = memories.cityJigsaw {
                memories.cityGrid = Set((0..<9).filter { piece in
                    let column = piece % 3, row = piece / 3
                    if row == 0 { return old.contains(column) }
                    if row == 2 { return old.contains(column + 3) }
                    return old.contains(column) && old.contains(column + 3)
                })
            } else {
                // Older four-strip saves retain every fully assembled image region.
                memories.cityGrid = Set((0..<9).filter { piece in
                    let column = piece % 3
                    let firstStrip = column * 4 / 3
                    let lastStrip = ((column + 1) * 4 - 1) / 3
                    return (firstStrip...lastStrip).allSatisfy { memories.cityPieces[$0] == $0 }
                })
            }
        }
        if memories.cityBoard == nil {
            memories.cityBoard = (0..<9).map { memories.cityGrid?.contains($0) == true ? $0 : nil }
        }
        if collected.contains(.city) || memories.cityBoard?.enumerated().allSatisfy({ $0.element == $0.offset }) == true {
            memories.citySolved = true
        }
        if memories.legacyRoomAccess == nil {
            memories.legacyRoomAccess = [.bedroom, .gelato, .noodle, .perfume, .cinema, .dictionary, .ferris, .taxi].contains(room)
                || !collected.isDisjoint(with: [.city, .rose, .gelato, .noodle, .perfume, .cinema, .dictionary, .ferris, .taxi])
        }
        if collected.contains(.keycard) { corridorUnlocked = true }
        exploration.tools.remove(.napkin)
        memories.used.insert(.napkin)
        if selectedTool == .napkin { selectedTool = nil }
        migrateRose()
        // Old completed-but-unclaimed assemblies now follow automatic ownership.
        // Migration changes no navigation or transient animation state.
        if memories.citySolved { collected.insert(.city) }
        if roseProgress.placed.count == 3 { collected.insert(.rose) }
        memories.picked.formUnion(exploration.tools)
        // Keep the legacy enum/save ID readable, but retire the obsolete tool.
        exploration.tools.remove(.magnifier)
        memories.picked.insert(.magnifier)
        memories.used.insert(.magnifier)
        if exploration.drawerOpened { memories.opened.insert("drawer") }
        if exploration.musicBoxOpened { memories.opened.insert("wholeBox") }
        for (clue, tool) in [(AdventureClue.travelOrder, AdventureTool.eraser), (.mirror, .cloth)] {
            if exploration.clues.contains(clue) { consume(tool) }
        }
        if exploration.drawerOpened { consume(.brassKey) }
        if collected.contains(.rose) { consume(.sewingKit) }
        if exploration.tools.contains(.scoop) || collected.contains(.gelato) { memories.opened.insert("dispenser"); consume(.coin) }
        if collected.contains(.gelato) { consume(.scoop); memories.menuSolved = true }
        if memories.flightDeparted || collected.contains(.plane) {
            memories.flightDeparted = true
            exploration.clues.insert(.travelOrder)
            consume(.ticket)
        }
        exploration.tools.subtract(memories.used)
        migrateGelatoWords()
        migrateFoodAndFragrance()
    }
}
