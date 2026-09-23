import SwiftUI

enum ExplorationAction {
    case dryCloth, pot, postcard, drawer, journal, cloth, mirror, score, musicBox, recipe, dispenser, freezer
    case memory(MemoryPanel)
    case perfumeDoor, perfumeExit
    case roseHidingPlace(Int)
    case ambient(String)
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
            .init("garden postcard", 174, 80, 24, 12, .postcard),
            .init("watering can", 197, 58, 42, 33, .ambient("Even the ivy needs a little looking after.")),
            .init("garden gate", 37, 61, 42, 35, .ambient("The path can wait. There is a whole world in this little house.")),
            .init("lantern", 18, 14, 27, 35, .ambient("Someone left the light on for you."))]
        case (.hall, 1): [
            .init("desk drawer", 111, 93, 100, 34, .drawer),
            .init("notebook", 128, 83, 36, 12, .ambient("A few blank pages. Room for whatever comes next.")),
            .init("desk lamp", 99, 55, 35, 33, .ambient("A small pool of gold. Just enough for two.")),
            .init("clock", 126, 29, 31, 32, .ambient("The clock is in no hurry tonight.")),
            .init("books", 160, 73, 26, 18, .ambient("Love stories, mostly. Some with the corners folded."))]
        case (.plane, 1): [
            .init("Yunnan postcard", 7, 93, 32, 22, .memory(.yunnan)),
            .init("travel journal", 124, 94, 71, 43, .memory(.travelBook)),
            .init("cup of tea", 204, 91, 36, 31, .ambient("The tea is warm. Your hands are finally steady.")),
            .init("window", 32, 13, 70, 65, .ambient("All those lights. Somewhere down there, a room is waiting.")),
            .init("scarf", 22, 99, 55, 45, .ambient("A little piece of home came along."))]
        case (.corridor, -1): [
            .init("linen cloth", 185, 73, 24, 16, .cloth),
            .init("botanical painting", 30, 18, 56, 75, .ambient("Pressed leaves. The hotel keeps things, too.")),
            .init("vase", 248, 42, 27, 53, .ambient("Empty, but carefully placed.")),
            .init("trolley wheel", 124, 124, 80, 19, .ambient("One wheel squeaks. Best not wake the whole floor."))]
        case (.corridor, 1): [
            .init("misty mirror", 132, 9, 60, 77, .mirror),
            .init("brass lamp", 117, 53, 23, 34, .ambient("The lamp makes a second moon in the glass.")),
            .init("pale vase", 180, 66, 20, 21, .ambient("The flowers are gone. Their reflection stayed.")),
            .init("service lift", 20, 24, 58, 97, .ambient("The service lift sleeps. Our room is around the corner.")),
            .init("another guest's door", 238, 21, 60, 101, .ambient("Someone else's story. Best leave it closed."))]
        case (.bedroom, 1): [
            .init("decorative box", 150, 69, 28, 18, .musicBox),
            .init("window", 242, 15, 60, 84, .memory(.city)),
            .init("desk lamp switch", 68, 24, 36, 56, .roseHidingPlace(1))]
        case (.gelato, -1): [
            .init("Menu", 131, 95, 26, 12, .recipe),
            .init("potted plant", 81, 60, 38, 61, .ambient("The basil likes this weather better than we do.")),
            .init("rain puddle", 108, 143, 78, 13, .ambient("The whole street fits inside this puddle."))]
        case (.gelato, 1): [
            .init("utensil cabinet", 145, 69, 39, 31, .dispenser),
            .init("gelato counter", 14, 64, 119, 28, .memory(.tasting)),
            .init("rain gutter", 153, 5, 55, 39, .memory(.rainGutter)),
            .init("awning", 15, 5, 138, 21, .ambient("A little roof against a very big rain."))]
        case (.yard, 0): [
            .init("sky", 115, 1, 115, 25, .ambient("Some words hide behind clouds. Some stay with you.")),
            .init("garden path", 122, 122, 85, 31, .ambient("The stones still remember your footsteps."))]
        case (.hall, 0): [
            .init("fireplace", 157, 60, 66, 45, .ambient("Come closer. The house has kept some warmth for you.")),
            .init("books", 116, 80, 28, 16, .ambient("Someone stopped reading at the happy part.")),
            .init("bench cushion", 99, 75, 25, 18, .ambient("Your place is still here."))]
        case (.plane, 0): [
            .init("arrival lights", 216, 14, 66, 45, .ambient("A thousand little windows. And one night that belongs to us.")),
            .init("seat", 50, 52, 48, 37, .ambient("We can sit for a moment. The city isn't going anywhere."))]
        case (.corridor, 0): [
            .init("harbour window", 123, 18, 43, 64, .ambient("Across the water, the lights are still awake.")),
            .init("ivy planter", 166, 62, 26, 45, .ambient("Even here, a little ivy found its way."))]
        case (.bedroom, 0): [
            .init("pillow", 233, 83, 44, 29, .ambient("The cool side of the pillow. Saved for you.")),
            .init("blanket fold", 153, 105, 32, 22, .memory(.blanket)),
            .init("bedside lamp", 268, 59, 28, 37, .ambient("Leave it on a little longer."))]
        case (.gelato, 0): [
            .init("street lamp", 223, 7, 15, 31, .ambient("Rain turns even an ordinary lamp into a star.")),
            .init("puddle", 110, 145, 90, 12, .ambient("Rain keeps the streetlights in little silver cups."))]
        case (.bedroom, -1): [.init("bath taps", 80, 30, 160, 105, .memory(.bath))]
        case (.noodle, 0):
            (bigTop.orderSolved ? [
                .init("Our dinner", BigTopTableLayout.dinner.minX, BigTopTableLayout.dinner.minY,
                      BigTopTableLayout.dinner.width, BigTopTableLayout.dinner.height, .memory(.bigTop))
            ] : []) + [
                .init("Order clipboard", 208, 49, 25, 25, .memory(.bigTopOrder))
            ]
        case (.noodle, 1): [.init("Eight-drawer menu cabinet", 141, 113, 109, 47, .memory(.bigTopMenuSearch))]
        case (.perfume, 0): [.init("Le Labo shop door", 239, 52, 47, 78, .perfumeDoor)]
        case (.perfume, 1): [
            .init("Street door", 8, 23, 48, 106, .perfumeExit),
            .init("Presentation box", 164, 82, 54, 46, .memory(.perfume)),
            .init("Formula notebook", 229, 115, 54, 20, .memory(.perfumeFormula))]
        case (.perfume, 2): [
            .init("Wood and resin cabinet", 70, 12, 94, 111, .memory(.perfumeWood)),
            .init("Specimen chest", 213, 75, 62, 25, .ambient("A little forest, tucked into a box."))]
        case (.perfume, 3): [
            .init("Botanical box", 31, 65, 122, 65, .memory(.perfumeBotanical)),
            .init("Spice drawer", 201, 80, 78, 51, .memory(.perfumeSpice))]
        case (.perfume, 4): [
            .init("Laboratory cabinet", 33, 9, 79, 70, .memory(.perfumeLab)),
            .init("Blending bench", 42, 68, 183, 71, .memory(.perfumeMix)),
            .init("Bottling press", 235, 19, 49, 112, .memory(.perfumeMix))]
        case (.cinema, 0): [.init("tickets", 95, 45, 135, 75, .memory(.cinema))]
        case (.sunset, 0): [.init("camera", 95, 45, 135, 75, .memory(.sunset))]
        case (.ferris, 0): [.init("ride tickets", 95, 45, 135, 75, .memory(.ferris))]
        case (.taxi, 0): [.init("taxi meter", 95, 45, 135, 65, .memory(.taxi))]
        default: []
        }
    }

    var ambientLine: String {
        switch room {
        case .yard: "The garden rustles."
        case .hall: "The fire answers with a soft crackle."
        case .plane: "A low hum, and the feeling of almost being there."
        case .corridor: "Soft carpet, quiet doors."
        case .bedroom: "The room feels like a pause in the middle of a song."
        case .gelato: "Rain on canvas. Somewhere, a freezer is humming."
        case .noodle: "The bowls are warm. We take our time."
        case .perfume: "A familiar scent follows us out into the street."
        case .cinema: "The lights dim. Your hand finds mine."
        case .sunset: "The light will change. This moment can stay."
        case .ferris: "Above the city, everything feels a little quieter."
        case .taxi: "The meter is running. Neither of us is in a hurry."
        }
    }

    func inspect(_ spot: ExplorationSpot) {
        guard canExplore else { return }
        switch spot.action {
        case .perfumeDoor: enterPerfumery()
        case .perfumeExit: leavePerfumery()
        case .roseHidingPlace(let index):
            if index == 1 { toggleBedroomLamp() }
            else { revealRosePetal(index) }
        case .dryCloth: openMemory(.menu)
        case .memory(let panel): openMemory(panel)
        case .pot: openMemory(.pot)
        case .postcard: discover(.gardenDate); showSceneHint(clueText(.gardenDate), tone: .success)
        case .drawer: openMemory(.drawer)
        case .journal: openMemory(.travelBook)
        case .cloth: openMemory(.linen)
        case .mirror:
            guard exploration.clues.contains(.mirror) || requireInteractionTool(.cloth, missing: "The glass is hidden beneath the mist.") else { return }
            overlay = .adventure(.mirror)
        case .score: overlay = .adventure(.musicScore)
        case .musicBox: openMemory(.wholeBox)
        case .recipe: openMemory(.menu)
        case .dispenser: openMemory(.dispenser)
        case .freezer: showSceneHint("A quiet hum. Cold enough for another spoonful.", presentation: .interaction)
        case .ambient(let line):
            showSceneHint(selectedTool == nil ? line : "The " + selectedTool!.label + " isn't needed here. " + line, tone: selectedTool == nil ? .ordinary : .wrong, presentation: .interaction)
        }
    }
}
