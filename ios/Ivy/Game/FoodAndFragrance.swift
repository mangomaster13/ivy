import SwiftUI

// Optional records in MemoryProgress leave every pre-existing save field intact.
struct BigTopProgress: Codable {
    // Optional for backward-compatible decoding of existing saves.
    var signOrder: String? = Self.shuffledSign()
    static func shuffledSign() -> String {
        var result: String
        repeat { result = String("BIGTOP".shuffled()) }
        while ["BIGTOP", "POTGIB"].contains(result)
        return result
    }
    var signDraft = ""
    var wholeSignAttempt: Bool? = nil
    var signSolved = false
    var menuRevealed = false
    // Optional so the former placemat search saves continue decoding.
    var tracingAngle: Double? = nil
    var tracingOffset: Double? = nil
    var menuDrawerOpen: Bool? = nil
    var drawerSymbols: [Int]? = nil
    var menuOrder: [Int]? = nil
    var menuTaken = false
    var menuPlaced = false
    var menuPage = 0
    var order: Set<Int> = []
    var orderSolved = false
    var streetUnlocked = false

    mutating func prepareMenu() {
        if menuOrder.map({ $0.count == BigTopMenu.availableIDs.count && Set($0) == Set(BigTopMenu.availableIDs) }) != true {
            menuOrder = BigTopMenu.availableIDs.shuffled()
        }
        if drawerSymbols.map({ $0.count == 4 && $0.allSatisfy(BigTopMenu.symbols.indices.contains) }) != true {
            drawerSymbols = [1, 3, 2, 4]
        }
        if menuTaken || menuPlaced || orderSolved { menuDrawerOpen = true }
        if menuPlaced || orderSolved { menuTaken = true }
        if orderSolved { menuPlaced = true; streetUnlocked = true }
        else { order.formIntersection(BigTopMenu.availableIDs) }
    }
}

struct PerfumeProgress: Codable {
    var opened: Set<String> = []
    var found: Set<AdventureTool> = []
    var mixture: [AdventureTool?] = [nil, nil, nil]
    var brewed: Set<AdventureTool> = []
    var output: AdventureTool? = nil
    var arrangement: [AdventureTool?] = [nil, nil, nil]
    var formulaPage = 0
    var arranged = false
    var cinemaUnlocked = false
}

enum BigTopMenu {
    static let dishes = [
        "Half Roast Goose", "Quarter Roast Goose", "Roast Duck", "Barbecued Pork", "Crispy Pork Belly",
        "Steamed Rice", "Rice Noodles", "Egg Fried Rice", "Wonton Noodles", "Soy Sauce Fried Noodles",
        "Choy Sum", "Chinese Broccoli", "Marinated Egg", "Fish Balls", "Soup of the Day",
        "Lemon Tea", "Ovaltine", "Milk Tea", "Coffee", "Lemon Water"
    ]
    // Keep historical dish IDs stable: old drafts were saved as these indices.
    static let availableIDs = [0, 1, 5, 6, 7, 8, 15, 16, 17, 19]
    static let answer: Set<Int> = [0, 5, 6, 15, 16]
    static let symbols = ["bowl", "cup", "fish", "spoon", "leaf", "goose", "chopsticks", "teapot"]
    static let drawerAnswer = [0, 5, 7, 2]
    static let ledgerDescription = "Two rows of four. Top: bowl, cup, fish, spoon. Bottom: leaf, goose, chopsticks, teapot. A notch at top left; two screws at bottom right."
    static let mirrorDescription = "Reflected two-row, four-column grid. Notch at top right; two screws at bottom left. A ring starts at top column four, joins bottom column three, then bottom column one, ending with an arrow at top column two. Columns counted from the left of the reflection."
}

struct PerfumeIngredient: Identifiable {
    let tool: AdventureTool
    let name: String
    let cabinet: String
    var id: String { tool.rawValue }
    static let all: [Self] = [
        .init(tool: .gaiacWood, name: "Gaiac Wood", cabinet: "wood"),
        .init(tool: .cedar, name: "Cedar", cabinet: "wood"),
        .init(tool: .incense, name: "Olibanum / Incense", cabinet: "wood"),
        .init(tool: .oakmoss, name: "Oakmoss", cabinet: "wood"),
        .init(tool: .patchouli, name: "Patchouli", cabinet: "wood"),
        .init(tool: .vetiver, name: "Vetiver", cabinet: "wood"),
        .init(tool: .bergamot, name: "Bergamot", cabinet: "botanical"),
        .init(tool: .grapefruit, name: "Grapefruit", cabinet: "botanical"),
        .init(tool: .petitgrain, name: "Petitgrain", cabinet: "botanical"),
        .init(tool: .orangeBlossom, name: "Orange Blossom", cabinet: "botanical"),
        .init(tool: .iris, name: "Iris", cabinet: "botanical"),
        .init(tool: .violet, name: "Violet", cabinet: "botanical"),
        .init(tool: .jasmine, name: "Jasmine", cabinet: "botanical"),
        .init(tool: .cinnamon, name: "Cinnamon", cabinet: "spice"),
        .init(tool: .pimentoBay, name: "Pimento Bay Oil", cabinet: "spice"),
        .init(tool: .pinkPepper, name: "Pink Pepper", cabinet: "spice"),
        .init(tool: .cardamom, name: "Cardamom", cabinet: "spice"),
        .init(tool: .musk, name: "Musk", cabinet: "lab"),
        .init(tool: .crystalMoss, name: "Crystal Moss", cabinet: "lab"),
        .init(tool: .clearwood, name: "Clearwood", cabinet: "lab"),
        .init(tool: .ambroxyde, name: "Ambroxyde", cabinet: "lab")
    ]
    static var tools: [AdventureTool] { all.map(\.tool) }
    // The legacy ID remains decodable and usable when held in an older save.
    static var world: [Self] { all.filter { $0.tool != .ambroxyde } }
}

struct PerfumeFormula: Identifiable {
    let bottle: AdventureTool
    let name: String
    let city: String
    let core: AdventureTool
    let supporting: [AdventureTool]
    let clue: AdventureClue
    var id: String { bottle.rawValue }
    static let all: [Self] = [
        .init(bottle: .gaiac10, name: "Gaiac 10", city: "Tokyo", core: .gaiacWood,
              supporting: [.musk, .cedar, .incense], clue: .gaiacFormula),
        .init(bottle: .bergamote22, name: "Bergamote 22", city: "", core: .bergamot,
              supporting: [.grapefruit, .petitgrain, .orangeBlossom, .vetiver, .cedar], clue: .bergamoteFormula),
        .init(bottle: .mousse30, name: "Mousse de Chene 30", city: "Amsterdam", core: .oakmoss,
              supporting: [.patchouli, .crystalMoss, .clearwood, .cinnamon, .pimentoBay, .pinkPepper], clue: .mousseFormula)
    ]
    static var bottles: [AdventureTool] { all.map(\.bottle) }
    func accepts(_ ingredients: [AdventureTool]) -> Bool {
        let set = Set(ingredients)
        return ingredients.count == 3 && set.count == 3 && set.contains(core)
            && set.subtracting([core]).isSubset(of: Set(supporting))
    }
}

extension AdventureTool {
    var ingredient: PerfumeIngredient? { PerfumeIngredient.all.first { $0.tool == self } }
    var formula: PerfumeFormula? { PerfumeFormula.all.first { $0.bottle == self } }
    var isFragranceTool: Bool { ingredient != nil || formula != nil }
    var fragranceImageName: String {
        switch self {
        case .gaiac10: "ll4-upright-gaiac10"
        case .bergamote22: "ll4-upright-bergamote22"
        case .mousse30: "ll4-upright-mousse30"
        default: "ll3-ingredient-" + rawValue
        }
    }
}

extension GameStore {
    var bigTop: BigTopProgress {
        get { memories.bigTop ?? BigTopProgress() }
        set { memories.bigTop = newValue }
    }
    var perfumery: PerfumeProgress {
        get { memories.perfumery ?? PerfumeProgress() }
        set { memories.perfumery = newValue }
    }

    func openNotebook() {
        guard overlay != .adventure(.notebook), collectingEgg == nil, !isHallTransitioning else { return }
        notebookReturnOverlay = overlay
        notebookClueFlash = false
        notebookFlashTask?.cancel()
        dismissSceneHint(); overlay = .adventure(.notebook)
    }
    func closeNotebook() {
        guard overlay == .adventure(.notebook) else { return }
        overlay = notebookReturnOverlay ?? .none
        notebookReturnOverlay = nil
        dismissSceneHint()
    }

    private var canChangeFoodPuzzle: Bool { !isIntro && !isHallTransitioning && collectingEgg == nil }

    func tapNeonLetter(_ letter: String) {
        guard canChangeFoodPuzzle else { return }
        guard room == .gelato, overlay == .memory(.bigTopSign), !bigTop.signSolved else { return }
        guard letter.count == 1, "BIGTOP".contains(letter) else { return }
        bigTop.wholeSignAttempt = true
        if bigTop.signDraft.contains(letter) {
            if bigTop.signDraft.hasSuffix(letter) {
                bigTop.signDraft.removeLast()
                persistNow()
            }
            return
        }
        bigTop.signDraft += letter
        guard bigTop.signDraft.count == 6 else { persistNow(); return }
        if bigTop.signDraft == "BIGTOP" {
            bigTop.signSolved = true
            IvyHaptics.success()
            dismissSceneHint()
            persistNow()
            if prefersReducedMotion {
                transition(to: .noodle)
            } else {
                Task { [weak self] in
                    try? await Task.sleep(for: .milliseconds(450))
                    guard let self, self.room == .gelato,
                          self.overlay == .memory(.bigTopSign) else { return }
                    self.transition(to: .noodle)
                }
            }
            return
        }
        // The whole attempt resets together; individual positions never disclose correctness.
        bigTop.signDraft = ""
        IvyHaptics.warning()
        dismissSceneHint(); persistNow()
    }
    func prepareBigTopMenu() {
        bigTop.prepareMenu()
        persistNow()
    }
    func takeBigTopTool(_ tool: AdventureTool) {
        guard canChangeFoodPuzzle, room == .noodle, canExplore, sceneView == 1,
              [.bigTopPencil, .bigTopInspectionMirror].contains(tool),
              !bigTop.menuTaken, !bigTop.orderSolved,
              !memories.picked.contains(tool), !memories.used.contains(tool) else { return }
        acquire(tool)
    }
    func revealBigTopLedger() {
        guard canChangeFoodPuzzle, room == .noodle, overlay == .memory(.bigTopLedger),
              !exploration.clues.contains(.bigTopLedger), use(.bigTopPencil) else { return }
        dismissSceneHint()
        discover(.bigTopLedger)
    }
    func placeBigTopMirror() {
        guard canChangeFoodPuzzle, room == .noodle, canExplore, sceneView == 1,
              !exploration.clues.contains(.bigTopMirror), use(.bigTopInspectionMirror) else { return }
        consume(.bigTopInspectionMirror)
        discover(.bigTopMirror)
        openMemory(.bigTopMirror)
    }
    func inspectBigTopMirror() {
        guard room == .noodle, canExplore, sceneView == 1 else { return }
        if exploration.clues.contains(.bigTopMirror) { openMemory(.bigTopMirror) }
        else if selectedTool == .bigTopInspectionMirror { placeBigTopMirror() }
        else { showSceneHint("There are scratches behind the wooden lip.", presentation: .interaction) }
    }
    func turnBigTopSymbol(_ index: Int, by step: Int = 1) {
        guard canChangeFoodPuzzle, room == .noodle, overlay == .memory(.bigTopMenuSearch),
              bigTop.menuDrawerOpen != true, (0..<4).contains(index), [-1, 1].contains(step) else { return }
        bigTop.prepareMenu()
        var symbols = bigTop.drawerSymbols ?? [1, 3, 2, 4]
        symbols[index] = (symbols[index] + step + 8) % 8
        bigTop.drawerSymbols = symbols
        dismissSceneHint(); persistNow()
    }
    func openBigTopMenuDrawer() {
        guard canChangeFoodPuzzle, room == .noodle, overlay == .memory(.bigTopMenuSearch),
              bigTop.menuDrawerOpen != true, !bigTop.menuTaken else { return }
        guard bigTop.drawerSymbols == BigTopMenu.drawerAnswer else {
            showSceneHint("The drawer stays shut.", presentation: .interaction)
            return
        }
        dismissSceneHint()
        bigTop.menuDrawerOpen = true
        IvyHaptics.success(); persistNow()
    }
    func takeBigTopMenu() {
        guard canChangeFoodPuzzle else { return }
        guard room == .noodle, overlay == .memory(.bigTopMenuSearch), bigTop.menuDrawerOpen == true,
              !bigTop.menuTaken, !bigTop.orderSolved else { return }
        bigTop.menuTaken = true
        for tool in [AdventureTool.bigTopPencil, .bigTopInspectionMirror] where exploration.tools.contains(tool) {
            consume(tool)
        }
        acquire(.dinnerMenu); persistNow()
    }
    func placeBigTopMenu() {
        guard canChangeFoodPuzzle else { return }
        guard room == .noodle, overlay == .memory(.bigTopOrder), !bigTop.menuPlaced,
              use(.dinnerMenu) else { return }
        bigTop.menuPlaced = true; consume(.dinnerMenu)
        // Placement leads straight to the usable menu; Back returns to the scene.
        overlay = .memory(.bigTopMenu)
        memoryNavigation.removeAll { $0 == .bigTopOrder }
        persistNow()
    }
    func selectDish(_ index: Int) {
        guard canChangeFoodPuzzle else { return }
        guard room == .noodle, overlay == .memory(.bigTopMenu), bigTop.menuPlaced,
              !bigTop.orderSolved, BigTopMenu.availableIDs.contains(index) else { return }
        if bigTop.order.contains(index) { bigTop.order.remove(index) } else { bigTop.order.insert(index) }
        dismissSceneHint(); persistNow()
    }
    func placeDinnerOrder() {
        guard canChangeFoodPuzzle else { return }
        guard room == .noodle, overlay == .memory(.bigTopMenu), bigTop.menuPlaced, !bigTop.orderSolved else { return }
        guard bigTop.order == BigTopMenu.answer else { showInputError("That wasn't our order."); return }
        bigTop.orderSolved = true; bigTop.streetUnlocked = true
        memories.opened.insert("bigTop")
        dismissSceneHint(); IvyHaptics.success(); persistNow()
    }
    func collectDinner() {
        guard canChangeFoodPuzzle else { return }
        guard room == .noodle, overlay == .memory(.bigTop), bigTop.orderSolved, collectingEgg == nil else { return }
        guard !collected.contains(.noodle) else { return }
        bigTop.streetUnlocked = true
        // The player already tapped the meal. Element is the reward, not another pickup gate.
        collected.insert(.noodle)
        toolsVisible = false
        IvyHaptics.success()
        persistNow()
    }

    func enterPerfumery() {
        guard room == .perfume, sceneView == 0, canExplore else { return }
        transition(to: .perfume, view: 1)
    }
    func leavePerfumery() {
        guard room == .perfume, sceneView > 0, canExplore else { return }
        transition(to: .perfume, view: 0)
    }
    func openIngredientCabinet(_ cabinet: String) {
        guard canChangeFoodPuzzle else { return }
        guard room == .perfume, overlay == .memory(Self.cabinetPanel(cabinet)),
              ["wood", "botanical", "spice", "lab"].contains(cabinet) else { return }
        perfumery.opened.insert(cabinet); persistNow()
    }
    static func cabinetPanel(_ cabinet: String) -> MemoryPanel {
        switch cabinet {
        case "wood": .perfumeWood
        case "botanical": .perfumeBotanical
        case "spice": .perfumeSpice
        default: .perfumeLab
        }
    }
    func takeIngredient(_ tool: AdventureTool) {
        guard canChangeFoodPuzzle else { return }
        guard let ingredient = tool.ingredient, room == .perfume,
              overlay == .memory(Self.cabinetPanel(ingredient.cabinet)),
              perfumery.opened.contains(ingredient.cabinet), !perfumery.found.contains(tool),
              !perfumery.arranged, !collected.contains(.perfume) else { return }
        perfumery.found.insert(tool); acquire(tool); persistNow()
    }
    func turnFormulaPage(_ delta: Int) {
        guard canChangeFoodPuzzle else { return }
        guard room == .perfume, overlay == .memory(.perfumeFormula) else { return }
        perfumery.formulaPage = min(2, max(0, perfumery.formulaPage + delta))
        discover(PerfumeFormula.all[perfumery.formulaPage].clue)
    }
    func putIngredient(_ tool: AdventureTool, at slot: Int) {
        guard canChangeFoodPuzzle else { return }
        guard room == .perfume, overlay == .memory(.perfumeMix), !perfumery.arranged,
              perfumery.output == nil, (0..<3).contains(slot), tool.ingredient != nil,
              perfumery.found.contains(tool), exploration.tools.contains(tool) else { return }
        if let previous = perfumery.mixture[slot] { exploration.tools.insert(previous) }
        perfumery.mixture[slot] = tool; exploration.tools.remove(tool)
        selectedTool = nil; dismissSceneHint(); persistNow()
    }
    func removeIngredient(at slot: Int) {
        guard canChangeFoodPuzzle else { return }
        guard room == .perfume, overlay == .memory(.perfumeMix), !perfumery.arranged,
              perfumery.output == nil, (0..<3).contains(slot), let tool = perfumery.mixture[slot] else { return }
        perfumery.mixture[slot] = nil; exploration.tools.insert(tool)
        dismissSceneHint(); persistNow()
    }
    func blendPerfume() {
        guard canChangeFoodPuzzle else { return }
        guard room == .perfume, overlay == .memory(.perfumeMix), !perfumery.arranged,
              perfumery.output == nil else { return }
        let ingredients = perfumery.mixture.compactMap { $0 }
        guard let formula = PerfumeFormula.all.first(where: { $0.accepts(ingredients) }) else {
            showInputError("Something feels out of place."); return
        }
        guard !perfumery.brewed.contains(formula.bottle) else {
            showInputError("We've bottled this one already."); return
        }
        exploration.tools.formUnion(ingredients)
        perfumery.mixture = [nil, nil, nil]
        perfumery.brewed.insert(formula.bottle); perfumery.output = formula.bottle
        selectedTool = nil; dismissSceneHint(); IvyHaptics.success(); persistNow()
    }
    func takePerfume() {
        guard canChangeFoodPuzzle else { return }
        guard room == .perfume, overlay == .memory(.perfumeMix), let bottle = perfumery.output else { return }
        perfumery.output = nil; acquire(bottle); persistNow()
    }
    func placePerfume(_ bottle: AdventureTool, at slot: Int) {
        guard canChangeFoodPuzzle else { return }
        guard room == .perfume, overlay == .memory(.perfume), !perfumery.arranged,
              (0..<3).contains(slot), bottle.formula != nil, perfumery.brewed.contains(bottle) else { return }
        if let source = perfumery.arrangement.firstIndex(of: bottle) {
            guard source != slot else { return }
            perfumery.arrangement.swapAt(source, slot)
        } else {
            guard exploration.tools.contains(bottle) else { return }
            if let displaced = perfumery.arrangement[slot] { exploration.tools.insert(displaced) }
            perfumery.arrangement[slot] = bottle; exploration.tools.remove(bottle)
        }
        selectedTool = nil; selectedPerfumeBottle = nil; dismissSceneHint()
        if perfumery.arrangement == PerfumeFormula.bottles.map(Optional.some) {
            perfumery.arranged = true; memories.opened.insert("perfume"); IvyHaptics.success()
            collectPerfumes()
        }
        persistNow()
    }
    func returnPerfume(at slot: Int) {
        guard canChangeFoodPuzzle else { return }
        guard room == .perfume, overlay == .memory(.perfume), !perfumery.arranged,
              (0..<3).contains(slot), let bottle = perfumery.arrangement[slot] else { return }
        perfumery.arrangement[slot] = nil; exploration.tools.insert(bottle)
        selectedPerfumeBottle = nil; selectedTool = nil; toolsVisible = true
        persistNow()
    }
    func collectPerfumes() {
        guard canChangeFoodPuzzle else { return }
        guard room == .perfume, overlay == .memory(.perfume), perfumery.arranged, collectingEgg == nil else { return }
        perfumery.cinemaUnlocked = true
        perfumery.mixture = [nil, nil, nil]
        perfumery.output = nil
        let tools = Set(PerfumeIngredient.tools + PerfumeFormula.bottles)
        exploration.tools.subtract(tools)
        memories.used.formUnion(tools)
        memories.picked.formUnion(perfumery.found.union(perfumery.brewed))
        if let tool = selectedTool, tools.contains(tool) { selectedTool = nil }
        if collected.insert(.perfume).inserted { toolsVisible = false }
        persistNow()
    }

    /// Old completion and access remain valid, without awarding a missing collectible.
    func migrateFoodAndFragrance() {
        if memories.bigTop == nil {
            var progress = BigTopProgress()
            progress.signSolved = room == .noodle || [.perfume, .cinema, .sunset, .ferris, .taxi].contains(room)
                || !collected.isDisjoint(with: [.noodle, .perfume, .cinema, .sunset, .ferris, .taxi])
            progress.orderSolved = collected.contains(.noodle) || memories.opened.contains("bigTop")
            progress.signSolved = progress.signSolved || progress.orderSolved
            progress.menuPlaced = progress.orderSolved
            progress.menuTaken = progress.orderSolved
            progress.streetUnlocked = collected.contains(.noodle) || [.perfume, .cinema, .sunset, .ferris, .taxi].contains(room)
            bigTop = progress
        }
        // Serving dinner unlocks the street independently of claiming the memory.
        if bigTop.orderSolved { bigTop.streetUnlocked = true }
        if collected.contains(.noodle) || memories.opened.contains("bigTop") { bigTop.orderSolved = true }
        if exploration.tools.contains(.dinnerMenu) { bigTop.menuTaken = true }
        bigTop.prepareMenu()
        if bigTop.signOrder.map({ $0.count == 6 && Set($0) == Set("BIGTOP") && !["BIGTOP", "POTGIB"].contains($0) }) != true {
            bigTop.signOrder = BigTopProgress.shuffledSign()
        }
        // Only the former per-letter feedback drafts are discarded. New attempts resume.
        if bigTop.wholeSignAttempt == nil {
            if bigTop.signDraft == "BIGTOP" { bigTop.signSolved = true }
            else { bigTop.signDraft = "" }
        }
        bigTop.wholeSignAttempt = true
        if bigTop.signSolved { bigTop.signDraft = "BIGTOP" }
        else if bigTop.signDraft.count > 5 || Set(bigTop.signDraft).count != bigTop.signDraft.count
                    || !Set(bigTop.signDraft).isSubset(of: Set("BIGTOP")) { bigTop.signDraft = "" }
        if memories.perfumery == nil {
            var progress = PerfumeProgress()
            progress.arranged = collected.contains(.perfume) || memories.opened.contains("perfume")
            progress.cinemaUnlocked = collected.contains(.perfume) || [.cinema, .sunset, .ferris, .taxi].contains(room)
            if progress.arranged {
                progress.brewed = Set(PerfumeFormula.bottles)
                progress.arrangement = PerfumeFormula.bottles.map(Optional.some)
            }
            perfumery = progress
        }
        perfumery.formulaPage = min(2, max(0, perfumery.formulaPage))
        perfumery.found = perfumery.found.intersection(PerfumeIngredient.tools)
        perfumery.brewed = perfumery.brewed.intersection(PerfumeFormula.bottles)
        perfumery.mixture = normalizedSlots(perfumery.mixture, allowed: perfumery.found)
        perfumery.arrangement = normalizedSlots(perfumery.arrangement, allowed: perfumery.brewed)
        if let output = perfumery.output,
           !perfumery.brewed.contains(output) || perfumery.arrangement.contains(output) { perfumery.output = nil }
        exploration.tools.subtract(PerfumeIngredient.tools + PerfumeFormula.bottles)
        if !collected.contains(.perfume) {
            exploration.tools.formUnion(perfumery.found.subtracting(perfumery.mixture.compactMap { $0 }))
            let onTable = Set(perfumery.arrangement.compactMap { $0 }).union([perfumery.output].compactMap { $0 })
            exploration.tools.formUnion(perfumery.brewed.subtracting(onTable))
        }
        if bigTop.menuTaken && !bigTop.menuPlaced && !bigTop.orderSolved { exploration.tools.insert(.dinnerMenu) }
        else { exploration.tools.remove(.dinnerMenu) }
        if bigTop.menuTaken {
            for tool in [AdventureTool.bigTopPencil, .bigTopInspectionMirror] where exploration.tools.contains(tool) {
                consume(tool)
            }
        }
    }
    private func normalizedSlots(_ slots: [AdventureTool?], allowed: Set<AdventureTool>) -> [AdventureTool?] {
        var seen = Set<AdventureTool>()
        return (0..<3).map { slot in
            guard slot < slots.count, let tool = slots[slot], allowed.contains(tool), seen.insert(tool).inserted else { return nil }
            return tool
        }
    }
}
