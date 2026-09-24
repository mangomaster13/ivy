import SwiftUI

enum ExplorationAction {
    case dryCloth, pot, postcard, drawer, journal, cloth, mirror, score, musicBox, recipe, dispenser, freezer
    case memory(MemoryPanel)
    case perfumeDoor, perfumeExit, dictionaryPen
    case bigTopTool(AdventureTool), bigTopMirror
    case roseHidingPlace(Int)
}
struct ExplorationSpot: Identifiable {
    let id: String
    let rect: CGRect
    let action: ExplorationAction
    init(_ id: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ action: ExplorationAction) {
        self.id = id; rect = CGRect(x: x, y: y, width: w, height: h); self.action = action
    }
}
extension GameStore {
    var explorationSpots: [ExplorationSpot] {
        switch (room, sceneView) {
        case (.yard, 1): [
            .init("terracotta pot", 120, 47, 41, 43, .pot),
            .init("garden postcard", 174, 80, 24, 12, .postcard)]
        case (.hall, 1): [
            .init("desk drawer", 111, 93, 100, 34, .drawer)]
        case (.plane, 1): [
            .init("Yunnan postcard", 7, 93, 32, 22, .memory(.yunnan)),
            .init("travel journal", 124, 94, 71, 43, .memory(.travelBook))]
        case (.corridor, -1): [
            .init("linen cloth", 185, 73, 24, 16, .cloth)]
        case (.corridor, 1): [
            .init("misty mirror", 132, 9, 60, 77, .mirror)]
        case (.bedroom, 1): [
            .init("decorative box", 150, 69, 28, 18, .musicBox),
            .init("window", 242, 15, 60, 84, .memory(.city)),
            .init("desk lamp switch", 68, 24, 36, 56, .roseHidingPlace(1))]
        case (.gelato, -1): [
            .init("note on the bench", 131, 95, 26, 12, .memory(.gelatoNote))]
        case (.gelato, 1): [
            .init("utensil cabinet", 147, 71, 30, 30, .dispenser),
            .init("gelato counter", 18, 73, 112, 19, .memory(.tasting)),
            .init("old order slip", GelatoWordArtwork.orderRect.minX, GelatoWordArtwork.orderRect.minY,
                  GelatoWordArtwork.orderRect.width, GelatoWordArtwork.orderRect.height, .memory(.gelatoOrder))]
        case (.bedroom, 0): [
            .init("blanket fold", 153, 105, 32, 22, .memory(.blanket))]
        case (.bedroom, -1): [.init("bath taps", 80, 30, 160, 105, .memory(.bath))]
        case (.noodle, 0):
            (bigTop.orderSolved ? [
                .init("Our dinner", BigTopTableLayout.dinner.minX, BigTopTableLayout.dinner.minY,
                      BigTopTableLayout.dinner.width, BigTopTableLayout.dinner.height, .memory(.bigTop))
            ] : []) + [
                .init("Order clipboard", 208, 49, 25, 25, .memory(.bigTopOrder))
            ]
        case (.noodle, 1):
            [
                .init("Ledger impressions", BigTopCounterLayout.ledger.minX, BigTopCounterLayout.ledger.minY,
                      BigTopCounterLayout.ledger.width, BigTopCounterLayout.ledger.height, .memory(.bigTopLedger)),
                .init("Counter observation slit", BigTopCounterLayout.slit.minX, BigTopCounterLayout.slit.minY,
                      BigTopCounterLayout.slit.width, BigTopCounterLayout.slit.height, .bigTopMirror),
                .init("Menu drawer", BigTopCounterLayout.drawer.minX, BigTopCounterLayout.drawer.minY,
                      BigTopCounterLayout.drawer.width, BigTopCounterLayout.drawer.height, .memory(.bigTopMenuSearch))
            ] + ([AdventureTool.bigTopPencil, .bigTopInspectionMirror].filter {
                !bigTop.menuTaken && !memories.picked.contains($0)
            }.map { tool in
                let rect = tool == .bigTopPencil ? BigTopCounterLayout.pencil : BigTopCounterLayout.mirror
                return ExplorationSpot(tool.label, rect.minX, rect.minY, rect.width, rect.height, .bigTopTool(tool))
            })
        case (.perfume, 0): [.init("Le Labo shop door", 239, 52, 47, 78, .perfumeDoor)]
        case (.perfume, 1): [
            .init("Street door", 8, 23, 48, 106, .perfumeExit),
            .init("Presentation box", 164, 82, 54, 46, .memory(.perfume)),
            .init("Formula notebook", 229, 115, 54, 20, .memory(.perfumeFormula))]
        case (.perfume, 2): [
            .init("Wood and resin cabinet", 70, 12, 94, 111, .memory(.perfumeWood))]
        case (.perfume, 3): [
            .init("Botanical box", 31, 65, 122, 65, .memory(.perfumeBotanical)),
            .init("Spice drawer", 201, 80, 78, 51, .memory(.perfumeSpice))]
        case (.perfume, 4): [
            .init("Laboratory cabinet", 33, 9, 79, 70, .memory(.perfumeLab))]
        case (.cinema, 0): CinemaLayout.spots
        case (.dictionary, 0): DictionaryLayout.spots(penAvailable: !memories.picked.contains(.fountainPen) && !dictionary.solved)
        case (.ferris, 0): FerrisLayout.promenadeSpots
        case (.ferris, 1): FerrisLayout.boothSpots
        case (.taxi, 0): TaxiLayout.spots(progress: taxi)
        default: []
        }
    }

    func inspect(_ spot: ExplorationSpot) {
        guard canExplore else { return }
        switch spot.action {
        case .dictionaryPen: takeDictionaryPen()
        case .bigTopTool(let tool): takeBigTopTool(tool)
        case .bigTopMirror: inspectBigTopMirror()
        case .perfumeDoor: enterPerfumery()
        case .perfumeExit: leavePerfumery()
        case .roseHidingPlace(let index):
            if index == 1 { toggleBedroomLamp() }
            else { revealRosePetal(index) }
        case .dryCloth: openMemory(.menu)
        case .memory(let panel): openMemory(panel)
        case .pot: openMemory(.pot)
        case .postcard: discover(.gardenDate)
        case .drawer: openMemory(.drawer)
        case .journal: openMemory(.travelBook)
        case .cloth: openMemory(.linen)
        case .mirror:
            guard exploration.clues.contains(.mirror) || requireInteractionTool(.cloth, missing: "The mist needs something soft and dry.") else { return }
            overlay = .adventure(.mirror)
        case .score: overlay = .adventure(.musicScore)
        case .musicBox: openMemory(.wholeBox)
        case .recipe: openMemory(.menu)
        case .dispenser: openMemory(.dispenser)
        case .freezer: break
        }
    }
}
