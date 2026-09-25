import SwiftUI

/// Closeups share a bounded content stage; feedback never changes the world's size.
struct MemoryCloseupView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel
    @State private var isEnteringText = false
    private var relevantTools: [AdventureTool] {
        let candidates: [AdventureTool]
        switch panel {
        case .drawer: candidates = store.memories.opened.contains("drawer") ? [] : [.brassKey]
        case .dispenser: candidates = store.memories.opened.contains("dispenser") ? [] : [.coin]
        case .ticket: candidates = [.eraser]
        default: candidates = []
        }
        return candidates.filter { store.exploration.tools.contains($0) }
    }
    var body: some View {
        if [.bigTop, .bigTopSign, .bigTopMenuSearch, .bigTopOrder, .bigTopMenu, .bigTopLedger, .bigTopMirror].contains(panel) {
            BigTopCloseupView(store: store, panel: panel)
        } else if [.perfume, .perfumeWood, .perfumeBotanical, .perfumeSpice, .perfumeLab, .perfumeFormula, .perfumeMix].contains(panel) {
            PerfumeCloseupView(store: store, panel: panel)
        } else if [.gelatoOrder, .gelatoNote, .rainGutter].contains(panel) {
            GelatoClueView(store: store, panel: panel)
        } else if [.menu, .tasting, .dispenser].contains(panel) {
            GelatoCloseupView(store: store, panel: panel)
        } else if [.cinema, .cinemaCase, .cinemaProjector, .cinemaTicket].contains(panel) {
            CinemaCloseupView(store: store, panel: panel)
        } else if [.ferris, .ferrisTicket, .ferrisGate, .ferrisCabin, .ferrisCamera, .ferrisPostbox, .ferrisScoreGuide].contains(panel) {
            FerrisCloseupView(store: store, panel: panel)
        } else if [.taxi, .taxiCard, .taxiReceipt].contains(panel) {
            TaxiCloseupView(store: store, panel: panel)
        } else if panel == .dictionary || panel == .dictionarySong {
            DictionaryCloseupView(store: store, panel: panel)
        } else if panel == .yunnan {
            ElementMemoryView(store: store, image: "memory-yunnan-postcard", title: "May · Yunnan",
                              line: "Same May, same Yunnan. We just hadn't met yet.", back: store.backFromMemory, decorated: false)
        } else if panel == .keycard {
            KeycardPickupView(store: store)
        } else if panel == .bouquet {
            KeepsakeSheet(back: store.backFromMemory, surface: .defocusedScene("hk-bedroom")) {
                RoseAssemblyView(store: store)
            }
        } else if panel == .city {
            CityJigsawView(store: store)
        } else if panel == .blanket {
            BlanketCloseupView(store: store)
        } else if panel == .wholeBox && !store.memories.opened.contains("wholeBox") {
            WholeBoxPuzzleView(store: store)
        } else if [.pot, .drawer, .wholeBox, .travelBook].contains(panel) {
            authoredContainer
        } else {
        KeepsakeSheet(back: store.backFromMemory, surface: inspectionSurface) {
            VStack(spacing: 8) {
                if panel == .ticket {
                    // Balance the feedback row so the paper stays centered on the panel.
                    Color.clear.frame(height: 52)
                }
                GeometryReader { geometry in
                    content(height: geometry.size.height)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .inventoryToolDrop(store: store, accepting: relevantTools) { _ in
                            if panel == .drawer || panel == .dispenser { store.openContainer(panel) }
                        }
                }
                if !isEnteringText { SceneFeedback(store: store) }
            }.foregroundStyle(IvyType.cream)
        }
        .onPreferenceChange(GameTextInputFocusKey.self) { isEnteringText = $0 }
    }
    }
    @ViewBuilder private func content(height: CGFloat) -> some View {
        switch panel {
        case .linen: linen(height: height)
        case .pot, .drawer, .wholeBox, .dispenser, .travelBook: EmptyView()
        case .flight: JourneyMapView(store: store, height: height)
        case .ticket: ticket(height: height)
        case .yunnan: EmptyView() // Dedicated element view above.
        case .bouquet: EmptyView() // Dedicated assembly-to-memory layout above.
        case .city: EmptyView() // Dedicated nine-piece puzzle above.
        case .bath: bath
        case .menu, .tasting: EmptyView()
        case .keycard: EmptyView() // Dedicated pickup view above.
        default: LaterMemoryView(store: store, panel: panel)
        }
    }
    private func linen(height: CGFloat) -> some View {
        return VStack(spacing: 12) {
            ZStack {
                Color.clear
                if !store.memories.picked.contains(.cloth) {
                    Button { store.openContainer(.linen); store.pickup(.cloth, from: .linen) } label: {
                        Color.clear.frame(width: 180, height: 100).contentShape(Rectangle())
                    }.offset(x: 60, y: 30).accessibilityLabel("Pick up the folded linen cloth")
                }
            }.frame(height: max(115, min(210, height - 80)))
        }
    }

    /// The entire plate and its transparent targets share one 320 × 160 canvas.
    /// Object footprints are measured from art/object-states/source, never inventory icons.
    private var authoredContainer: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                let opened = store.memories.opened.contains(panel.rawValue)
                ZStack(alignment: .topLeading) {
                    InspectionBackdrop(surface: inspectionSurface)
                    switch panel {
                    case .pot:
                        if !opened {
                            containerTarget("Move the terracotta pot", rect: CGRect(x: 115, y: 31, width: 80, height: 70), scale: scale) {
                                store.openContainer(.pot)
                            }
                        } else if !store.memories.picked.contains(.brassKey) {
                            // Stone bench, inside the exposed moss ring.
                            containerTarget("Pick up the garden key", rect: CGRect(x: 145, y: 70, width: 37, height: 26), scale: scale) {
                                store.pickup(.brassKey, from: .pot)
                            }
                        }
                    case .drawer:
                        if !opened {
                            containerTarget("Use selected key in drawer lock", rect: CGRect(x: 147, y: 45, width: 26, height: 25), scale: scale) {
                                store.openContainer(.drawer)
                            }
                        } else if !store.memories.picked.contains(.eraser) {
                            // Linen-lined drawer floor, left of centre.
                            containerTarget("Pick up the rubber eraser", rect: CGRect(x: 101, y: 71, width: 36, height: 25), scale: scale) {
                                store.pickup(.eraser, from: .drawer)
                            }
                        }
                    case .wholeBox:
                        // Fixed left/right positions survive either pickup order.
                        if !store.collected.contains(.rose), !store.roseProgress.found.contains(2) {
                            containerTarget("Red rose petal inside the box", rect: CGRect(x: 112, y: 88, width: 33, height: 26), scale: scale) {
                                store.takeRosePetal(2)
                            }
                        }
                        if !store.memories.picked.contains(.coin) {
                            containerTarget("Pick up the brass token", rect: CGRect(x: 171, y: 91, width: 33, height: 22), scale: scale) {
                                store.pickup(.coin, from: .wholeBox)
                            }
                        }
                    case .travelBook:
                        if !store.memories.picked.contains(.ticket) {
                            containerTarget("Ticket between the pages", rect: CGRect(x: 169, y: 50, width: 104, height: 44), scale: scale, action: store.takeTicket)
                        }
                    default: EmptyView()
                    }
                }
                .inventoryToolDrop(store: store, accepting: relevantTools) { _ in
                    if panel == .drawer { store.openContainer(.drawer) }
                }
            }
        }
        .overlay(alignment: .bottom) { SceneFeedback(store: store, height: 30) }
        .gameBackAction(store.backFromMemory)
    }

    private func containerTarget(_ label: String, rect: CGRect, scale: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Color.clear.frame(width: max(48, rect.width * scale), height: max(48, rect.height * scale))
                .contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(label)
            .position(x: rect.midX * scale, y: rect.midY * scale)
    }
    private var inspectionSurface: InspectionSurface {
        switch panel {
        case .pot: .scene(store.potImageName)
        case .drawer: .scene(store.drawerImageName)
        case .linen: .scene(store.memories.picked.contains(.cloth) ? "memory-linen-empty" : "memory-linen")
        case .dispenser: .scene(store.gelatoCabinetImageName)
        case .wholeBox: .scene(store.wholeBoxImageName)
        case .bath: .scene("memory-bath")
        case .blanket: .scene("memory-blanket-open")
        case .perfume: .scene("memory-perfume")
        case .dictionary, .dictionarySong: .scene("later-dictionary-open-book-background")
        case .cinema, .cinemaCase, .cinemaProjector, .cinemaTicket: .scene("later-cinema-projection-booth-background")
        case .taxi, .taxiCard, .taxiReceipt: .scene(store.roomImageName)
        case .bigTop, .mexican: .scene("memory-noodle")
        case .ferris, .ferrisTicket, .ferrisGate, .ferrisCabin, .ferrisCamera, .ferrisPostbox, .ferrisScoreGuide: .scene("ferris-music-cabinet")
        case .ticket: .puzzle
        case .travelBook: .scene(store.travelBookImageName)
        case .yunnan: .scene("explore-plane-window")
        case .bouquet, .city: .defocusedScene("hk-bedroom")
        case .keycard: .scene("explore-corridor-cart")
        case .menu, .tasting: .scene("explore-gelato-service")
        case .rainGutter, .gelatoOrder: .scene("gelato-word-order")
        case .gelatoNote: .scene("gelato-word-note")
        case .flight: .puzzle
        case .bigTopSign: .scene("bt2-neon-wall")
        case .bigTopMenuSearch: .scene("bt3-counter")
        case .bigTopLedger: .scene("bt3-ledger")
        case .bigTopMirror: .scene("bt3-mirror")
        case .bigTopOrder: .scene("bt2-counter")
        case .bigTopMenu: .scene("bt3-menu-compact")
        case .perfumeWood, .perfumeBotanical, .perfumeSpice, .perfumeLab: .scene("ll-cabinet")
        case .perfumeFormula, .perfumeMix: .scene("ll-bench")
        }
    }
    private func ticket(height: CGFloat) -> some View {
        GeometryReader { geometry in
            let ticketWidth = min(620, max(0, geometry.size.width),
                                  max(0, height - 24) * 2.2)
            TicketRubbingView(store: store)
                .frame(width: ticketWidth, height: ticketWidth / 2.2)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }

    private var bath: some View {
        VStack(spacing: 12) {
            ZStack {
                Color.clear.frame(height: 140)
                if store.memories.bathWarm && !store.memories.bathRevealed {
                    RoundedRectangle(cornerRadius: 20).fill(IvyType.cream.opacity(0.75)).frame(width: 280, height: 130)

                        .gesture(DragGesture(minimumDistance: 20).onEnded { _ in revealBath() })
                        .onTapGesture { revealBath() }
                }
            }
            if store.memories.bathRevealed {
                Text("Just us, warm water, and nowhere to rush.").font(IvyType.hand(22))
            } else {
                Button(store.memories.bathWarm ? "wipe the mirror" : "turn on the warm water") {
                    if store.memories.bathWarm { revealBath() }
                    else { withAnimation { store.memories.bathWarm = true }; store.persistNow() }
                }.font(IvyType.hand(22)).frame(minHeight: 44)
            }
        }
    }
    private func revealBath() { withAnimation { store.memories.bathRevealed = true }; store.persistNow() }

}

/// The box and inscription share the artwork coordinates; only the answer well is interactive.
private struct WholeBoxPuzzleView: View {
    @Bindable var store: GameStore
    @State private var isEnteringText = false

    var body: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let size = geometry.size

                ZStack(alignment: .topLeading) {
                    InspectionBackdrop(surface: .scene("box-state-closed"))
                    PuzzleInputLine(text: $store.memories.wholeDraft, limit: 10,
                                    mode: .phrase, submit: store.submitWhole,
                                    onFocusChange: { isEnteringText = $0 })
                        .accessibilityHint("Complete the inscription: i love u")
                        .frame(width: isEnteringText ? min(300, size.width - 32) : min(300, size.width * 0.40))
                        .position(x: size.width * (isEnteringText ? 0.56 : 0.76), y: size.height * 0.43)
                    if !isEnteringText {
                        VStack {
                            Spacer(minLength: 0)
                            SceneFeedback(store: store, height: 32)
                                .frame(height: 32)
                                .padding(.bottom, 8)
                        }
                        .frame(width: size.width, height: size.height)
                    }
                }
            }
        }
        .gameBackAction(store.backFromMemory)
        .onChange(of: store.memories.wholeDraft) { _, _ in
            store.dismissSceneHint()
            store.persistNow()
        }
    }
}

struct WordAnswer: View {
    @Binding var text: String
    var limit: Int = 12
    var feedbackStore: GameStore? = nil
    let submit: () -> Void
    var onFocusChange: (Bool) -> Void = { _ in }

    var body: some View {
        PuzzleInputLine(text: $text, limit: limit, mode: .letters,
                        submit: submit, onFocusChange: onFocusChange)
        .frame(maxWidth: 300)
        .onChange(of: text) { _, _ in feedbackStore?.dismissSceneHint() }
    }
}

extension AdventureTool {
    var imageName: String { self == .ferrisPostcard ? "ferris-postcard" : self == .ferrisTicket ? "ferris-navigation-ticket" : self == .ferrisPhone ? "ferris-selfie-phone" : self == .cinemaFilm ? "cinema-film-blank" : self == .fountainPen ? "later-dictionary-fountain-pen" : isFragranceTool ? fragranceImageName : self == .dinnerMenu ? "bt2-menu-cover" : self == .ticket ? "ticket-paper" : self == .sewingKit ? "memory-twine" : self == .eraser ? "tool-eraser" : self == .napkin ? "tool-cloth" : "tool-" + rawValue }
}
extension GameStore {
    var potImageName: String {
        guard memories.opened.contains("pot") else { return "pot-state-covered" }
        return memories.picked.contains(.brassKey) ? "pot-state-empty" : "pot-state-key"
    }
    var drawerImageName: String {
        guard memories.opened.contains("drawer") else { return "drawer-state-closed" }
        return memories.picked.contains(.eraser) ? "drawer-state-empty" : "drawer-state-eraser"
    }
    var wholeBoxImageName: String {
        guard memories.opened.contains("wholeBox") else { return "box-state-closed" }
        let petal = !collected.contains(.rose) && !roseProgress.found.contains(2)
        let token = !memories.picked.contains(.coin)
        if petal { return token ? "box-state-both" : "box-state-petal" }
        return token ? "box-state-token" : "box-state-empty"
    }
    var travelBookImageName: String {
        memories.picked.contains(.ticket) ? "book-state-empty" : "book-state-ticket"
    }

    func traceTicket() {
        guard room == .plane, overlay == .memory(.ticket), !exploration.clues.contains(.travelOrder) else { return }
        guard use(.eraser) else { return }
        discover(.travelOrder); consume(.eraser); sceneHint = ""; persistNow()
    }
}
