import Foundation
import SwiftUI

enum AdventureTool: String, Codable, CaseIterable, Identifiable {
    case brassKey, magnifier, cloth, napkin, sewingKit, coin, scoop, ticket
    // Preserve the old save identifier while replacing the physical tool.
    case eraser = "pencil"
    case dinnerMenu
    case gaiacWood, cedar, incense, oakmoss, patchouli, vetiver
    case bergamot, grapefruit, petitgrain, orangeBlossom, iris, violet, jasmine
    case cinnamon, pimentoBay, pinkPepper, cardamom, musk, crystalMoss, clearwood, ambroxyde
    case gaiac10, bergamote22, mousse30
    var id: String { rawValue }
    var label: String {
        switch self {
        case .ticket: "ticket"
        case .brassKey: "garden key"
        case .eraser: "rubber eraser"
        case .magnifier: "magnifying glass"
        case .napkin: "dry napkin"
        case .cloth: "linen cloth"
        case .sewingKit: "bouquet twine"
        case .coin: "brass token"
        case .scoop: "tasting spoon"
        case .dinnerMenu: "Big Top menu"
        default: ingredient?.name ?? formula?.name ?? rawValue
        }
    }
    var symbol: String {
        switch self {
        case .ticket: "ticket"
        case .brassKey: "key.horizontal"
        case .eraser: "eraser"
        case .magnifier: "magnifyingglass"
        case .napkin: "square.fill"
        case .cloth: "square.fill"
        case .sewingKit: "needle"
        case .coin: "circle.circle"
        case .scoop: "spoon"
        case .dinnerMenu: "menucard"
        default: "drop"
        }
    }
    var description: String {
        switch self {
        case .ticket: "A paper ticket kept between the pages."
        case .brassKey: "A tiny ivy-shaped key. Somewhere inside, a drawer is waiting."
        case .eraser: "A worn rubber eraser, with graphite on one corner."
        case .magnifier: "For the little things that are too easy to miss."
        case .napkin: "A folded napkin, sheltered from the rain."
        case .cloth: "Dry linen. Good for dusty glass and rain-soaked paper."
        case .sewingKit: "A soft length of twine for a bouquet wrapper."
        case .coin: "A brass token engraved with a little spoon."
        case .scoop: "A proper scoop. Cold enough gelato should curl right into it."
        case .dinnerMenu: "A folded menu from Big Top."
        default: ingredient != nil ? "A labelled bottle of " + label + "." : "A bottle of " + label + "."
        }
    }
}

enum AdventureClue: String, Codable, CaseIterable, Identifiable {
    case gardenDate, label, travelOrder, mirror, music, recipe, temperature, rainRelation
    case gaiacFormula, bergamoteFormula, mousseFormula, perfumeOrder
    var id: String { rawValue }
    var title: String {
        switch self {
        case .gardenDate: "a date in the garden"
        case .label: "a very small label"
        case .travelOrder: "a journey in four signs"
        case .mirror: "what the mirror kept"
        case .music: "a song in three notes"
        case .recipe: "our rainy-day order"
        case .temperature: "the cold cabinet"
        case .rainRelation: "what the rain carried"
        case .gaiacFormula: "Gaiac 10"
        case .bergamoteFormula: "Bergamote 22"
        case .mousseFormula: "Mousse de Chene 30"
        case .perfumeOrder: "the presentation box"
        }
    }
}

enum AdventurePanel: String, Equatable {
    case notebook, journal, mirror, musicScore, musicBox, recipe, freezer
}

/// Only durable puzzle facts live here. Selected tools, open panels and transition tasks do not.
struct ExplorationProgress: Codable {
    var rubbing: [String: RubbingProgress]? = nil
    var tools: Set<AdventureTool> = []
    var clues: Set<AdventureClue> = []
    var views: [String: Int] = [:]
    var hotelCode: [Int] = Array((0...9).shuffled().prefix(4))
    var drawerOpened = false
    var musicBoxOpened = false
    var musicInput: [Int] = []
    var stitches: Set<Int> = []
    var freezerTemperature = -4
    var scoops: [GelatoFlavor] = []

    static let symbolNames = ["moon", "leaf", "star", "drop"]
    static let musicAnswer = [2, 0, 1]
    static let gelatoAnswer: [GelatoFlavor] = [.pistachio, .pistachio, .stracciatella]

    var validHotelCode: Bool { hotelCode.count == 4 && hotelCode.allSatisfy { (0...9).contains($0) } }
    mutating func sanitize() {
        if views["perfume"] == nil { views["perfume"] = views["supermarket"] }
        views.removeValue(forKey: "supermarket")
        if !validHotelCode { hotelCode = Array((0...9).shuffled().prefix(4)) }
        freezerTemperature = min(0, max(-18, freezerTemperature))
        scoops = Array(scoops.prefix(3))
        stitches = stitches.intersection([0, 1, 2])
        for (key, value) in views {
            let allowed = key == "perfume" ? [0, 1, 2, 3, 4] :
                (["corridor", "gelato", "bedroom"].contains(key) ? [-1, 0, 1] :
                (["yard", "hall", "plane", "noodle"].contains(key) ? [0, 1] : [0]))
            if !allowed.contains(value) { views[key] = 0 }
        }
        musicInput = Array(musicInput.filter { (0...2).contains($0) }.prefix(2))
    }
}

extension GameStore {
    var sceneView: Int { exploration.views[room.rawValue] ?? 0 }
    var sceneViews: [Int] { room == .perfume ? (sceneView == 0 ? [0] : [1, 2, 3, 4]) : Self.sceneViews(in: room) }
    static func sceneViews(in room: Room) -> [Int] {
        switch room {
        case .corridor, .gelato: [-1, 0, 1]
        case .yard, .hall, .plane, .bedroom, .noodle: [0, 1]
        case .perfume: [0, 1, 2, 3, 4]
        default: [0]
        }
    }
    var sideImageName: String? {
        switch (room, sceneView) {
        case (.bedroom, -1): "memory-bath"
        case (.noodle, 1): "bt2-counter-eight"
        case (.perfume, 1): "ll4-entry"
        case (.perfume, 2): perfumery.opened.contains("wood") ? "ll-wood-open" : "ll-wood"
        case (.perfume, 3): perfumery.opened.contains("botanical") ? "ll-botanical-room-open" : "ll-botanical"
        case (.perfume, 4): "ll4-bench"
        case (.yard, 1): "explore-yard-garden"
        case (.hall, 1): "explore-hall-desk"
        case (.plane, 1): "explore-plane-window"
        case (.corridor, -1): "explore-corridor-cart"
        case (.corridor, 1): "explore-corridor-mirror"
        case (.bedroom, 1): memories.bedroomLampOn == true ? "explore-bedroom-desk" : "explore-bedroom-desk-off"
        case (.gelato, -1): "explore-gelato-bench"
        case (.gelato, 1): "explore-gelato-service"
        default: nil
        }
    }
    var canExplore: Bool { !isIntro && overlay == .none && !isHallTransitioning && collectingEgg == nil }

    func turnView(_ delta: Int) {
        guard canExplore, sceneViews.contains(sceneView + delta) else { return }
        exploration.views[room.rawValue] = sceneView + delta
        sceneHint = ""
        persistNow()
    }

    func chooseTool(_ tool: AdventureTool) {
        guard exploration.tools.contains(tool), !isHallTransitioning, collectingEgg == nil else { return }
        closeElementForFooter()
        selectedPerfumeBottle = nil
        if tool == .ticket { openMemory(.ticket); return }
        selectedTool = selectedTool == tool ? nil : tool
        sceneHint = ""
    }

    func acquire(_ tool: AdventureTool) {
        guard !memories.used.contains(tool), exploration.tools.insert(tool).inserted else {
            showSceneHint("Already tucked safely in your satchel."); return
        }
        memories.picked.insert(tool)
        toolsVisible = true
        sceneHint = ""
        IvyHaptics.light()
        persistNow()
    }

    /// Gate tool-only interactions before changing the overlay or return stack.
    /// Ownership allows inspection; selecting/using the tool remains a separate action.
    func requireInteractionTool(_ tool: AdventureTool, missing line: String) -> Bool {
        guard exploration.tools.contains(tool) else {
            showSceneHint(line, presentation: .interaction)
            return false
        }
        return true
    }

    @discardableResult
    func use(_ tool: AdventureTool) -> Bool {
        guard selectedTool == tool, exploration.tools.contains(tool) else {
            IvyHaptics.light()
            return false
        }
        selectedTool = nil
        return true
    }

    func discover(_ clue: AdventureClue) {
        guard exploration.clues.insert(clue).inserted else { return }
        notebookClueFlash = true
        notebookFlashTask?.cancel()
        notebookFlashTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            self?.notebookClueFlash = false
        }
        persistNow()
    }

    func clueText(_ clue: AdventureClue) -> String {
        return switch clue {
        case .gardenDate: "August. Seventeen.\nThe day the garden began to grow."
        case .label: "vuori.\nA little name, a familiar feeling."
        case .travelOrder: "moon → leaf → star → drop"
        case .mirror:
            [2, 0, 3, 1].map { "\(ExplorationProgress.symbolNames[$0]): \(exploration.hotelCode[$0])" }.joined(separator: "    ")
        case .music: "high → low → middle"
        case .recipe: "Citrus · pepper\nMagnolia · longan\nLoquat · jasmine\nBasil · tomato\nFruit and flowers came after the other fruit and flowers."
        case .temperature: "Serving temperature: −12°C."
        case .rainRelation: "Five-petal blossom points to crescent moon."
        case .gaiacFormula, .bergamoteFormula, .mousseFormula:
            PerfumeFormula.all.first { $0.clue == clue }.map { $0.name + "\n" + $0.core.label + "\n" + $0.supporting.map(\.label).joined(separator: " · ") } ?? ""
        case .perfumeOrder: "X → XXII → XXX"
        }
    }


    /// Read-only guidance follows saved progress without exposing undiscovered answers.
    var notebookHint: String {
        if !collected.contains(.letter) {
            return "The mailbox is keeping something for you. The ivy nearby may remember more."
        }
        if !doorOpened {
            return "A letter, a lyric, a date. The front door is waiting for their story."
        }
        if !collected.contains(.vuori) {
            return "A familiar shirt is waiting inside the house. Its little label holds a memory."
        }
        if !collected.contains(.plane) {
            if !memories.routeCorrect {
                return "The ticket remembers our first journey. Two places belong together on the map."
            }
            if !exploration.clues.contains(.travelOrder) {
                return exploration.tools.contains(.eraser)
                    ? "There is more beneath the graphite on the ticket."
                    : "The locked desk drawer may hold something for the marks on the ticket."
            }
            return "The journey is there on the ticket now. A little piece of it can come with you."
        }
        if !corridorUnlocked {
            return exploration.clues.contains(.mirror)
                ? "The ticket kept an order. The mirror kept the numbers. They belong to the same door."
                : "The hotel mirror is misted over. Something is waiting beneath the glass."
        }
        if !collected.contains(.keycard) { return "A small card waits beside the door we remembered." }
        if !collected.contains(.city) { return "The bedroom window holds a whole city, and one of our memories." }
        if !collected.contains(.rose) {
            return "All the little pieces. Still part of the same flower."
        }
        if !collected.contains(.gelato) {
            if !exploration.clues.contains(.recipe) { return "The rain left part of our order on the paper by the bench." }
            if !exploration.tools.contains(.scoop) { return "A little spoon token belongs to the utensil cabinet." }
            return "Our order is written down. One taste at the counter might bring it back."
        }
        if !collected.contains(.noodle) { return "A warm bowl, an order slip. Big Top kept a little of our evening." }
        if !collected.contains(.perfume) { return "Beyond the groceries, a familiar scent is waiting." }
        if !collected.contains(.cinema) { return "Two cinema tickets still remember the dark and the screen." }
        if !collected.contains(.sunset) { return "Outside the cinema, the camera is waiting for the last light." }
        if !collected.contains(.ferris) { return "The ride tickets promise a quieter view above the city." }
        if !collected.contains(.taxi) { return "One last ride. The taxi meter has kept the end of our night." }
        return "Every keepsake is here. The pages still remember, whenever you want to return."
    }

    func rubJournal() {
        guard room == .plane, overlay == .adventure(.journal) else { return }
        guard use(.eraser) else { return }
        discover(.travelOrder)
        consume(.eraser)
        IvyHaptics.light()
    }

    func wipeMirror() {
        guard room == .corridor, overlay == .adventure(.mirror) else { return }
        guard use(.cloth) else { return }
        discover(.mirror)
        consume(.cloth)
        showSceneHint("Four signs. Four numbers. But which comes first?", tone: .success)
    }

    func playMusicNote(_ note: Int) {
        guard room == .bedroom, overlay == .adventure(.musicBox),
              !exploration.musicBoxOpened, (0...2).contains(note) else { return }
        exploration.musicInput.append(note)
        IvyHaptics.light()
        if exploration.musicInput.count == 3 {
            if exploration.musicInput == ExplorationProgress.musicAnswer {
                exploration.musicBoxOpened = true
                memories.opened.insert("wholeBox")
                openMemory(.wholeBox)
                showSceneHint("The melody opened a little secret.", presentation: .interaction)
                IvyHaptics.success()
            } else {
                showSceneHint("The melody trails off. The score is beside the box.", tone: .wrong)
            }
            exploration.musicInput = []
        }
        persistNow()
    }

    func wipeRecipe() {
        guard room == .gelato, overlay == .adventure(.recipe) else { return }
        guard use(.napkin) else { return }
        discover(.recipe)
        consume(.napkin)
        IvyHaptics.light()
    }

    func setFreezer(_ delta: Int) {
        guard room == .gelato, overlay == .adventure(.freezer) else { return }
        exploration.freezerTemperature = min(0, max(-18, exploration.freezerTemperature + delta))
        showSceneHint(exploration.freezerTemperature == -12 ? "A quiet hum. Ready to scoop." : "The dial settles.")
        persistNow()
    }

    func serveGelato() {
        guard room == .gelato, overlay == .gelato, !collected.contains(.gelato) else { return }
        guard exploration.tools.contains(.scoop), exploration.freezerTemperature == -12 else {
            IvyHaptics.light(); return
        }
        guard exploration.scoops.count == 3 else { IvyHaptics.light(); return }
        guard exploration.scoops == ExplorationProgress.gelatoAnswer else {
            IvyHaptics.light()
            IvyHaptics.warning()
            return
        }
        collect(.gelato)
        persistNow()
    }

    func undoScoop() {
        guard room == .gelato, overlay == .gelato, !collected.contains(.gelato), !exploration.scoops.isEmpty else { return }
        exploration.scoops.removeLast()
        sceneHint = ""
        persistNow()
    }
}
