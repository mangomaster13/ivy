import SwiftUI

/// Closeups share a bounded content stage; feedback never changes the world's size.
struct MemoryCloseupView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel
    @State private var isEnteringText = false
    private var isContainer: Bool { [.pot, .drawer, .linen, .dispenser].contains(panel) || (panel == .wholeBox && store.memories.opened.contains("wholeBox")) }
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
        } else if [.ferris, .ferrisTicket, .ferrisGate, .ferrisCabin, .ferrisCamera].contains(panel) {
            FerrisCloseupView(store: store, panel: panel)
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
        case .pot, .drawer, .linen, .dispenser: container(height: height)
        case .wholeBox:
            if store.memories.opened.contains("wholeBox") { container(height: height) }
            else { WholeBoxPuzzleView(store: store) }
        case .flight: JourneyMapView(store: store, height: height)
        case .travelBook:
            GeometryReader { geometry in
                if !store.memories.picked.contains(.ticket) {
                    Button(action: store.takeTicket) {
                        Image("ticket-paper").resizable().interpolation(.high).scaledToFit()
                            .frame(width: min(280, geometry.size.width * 0.34))
                            .frame(minHeight: 48)
                    }.buttonStyle(.plain)
                        .rotationEffect(.degrees(-7))
                        .position(x: geometry.size.width * 0.68, y: geometry.size.height * 0.42)
                        .accessibilityLabel("Ticket between the pages")
                }
            }
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
    private func container(height: CGFloat) -> some View {
        let opened = store.memories.opened.contains(panel.rawValue)
        let remaining = panel.tools.filter { !store.memories.picked.contains($0) }
        return VStack(spacing: 12) {
            ZStack {
                Color.clear
                if opened && panel != .linen {
                    HStack(spacing: 60) {
                        if panel == .wholeBox, !store.collected.contains(.rose), !store.roseProgress.found.contains(2) {
                            Button { store.takeRosePetal(2) } label: {
                                RosePetalArtwork(index: 2)
                                    .frame(width: 82, height: 90).rotationEffect(.degrees(-18))
                            }.buttonStyle(.plain).accessibilityLabel("Red rose petal inside the box")
                        }
                        ForEach(remaining) { tool in
                            Button { withAnimation(.easeInOut(duration: 0.5)) { store.pickup(tool, from: panel) } } label: {
                                Image(tool.imageName).resizable().interpolation(.high).scaledToFit()
                                    .frame(width: 105, height: 105).shadow(color: .black.opacity(0.2), radius: 3, y: 4)
                            }.buttonStyle(.plain).accessibilityLabel("Pick up " + tool.label)
                                .transition(.scale(scale: 0.1).combined(with: .opacity))
                        }
                    }.offset(x: panel == .dispenser ? -35 : 0, y: panel == .wholeBox ? 35 : 0)
                } else if panel == .linen {
                    if !store.memories.picked.contains(.cloth) {
                        Button { store.openContainer(.linen); store.pickup(.cloth, from: .linen) } label: {
                            Color.clear.frame(width: 180, height: 100).contentShape(Rectangle())
                        }.offset(x: 60, y: 30).accessibilityLabel("Pick up the folded linen cloth")
                    }
                } else if panel != .drawer {
                    Button { store.openContainer(panel) } label: {
                        Color.clear.frame(width: 180, height: 100).contentShape(Rectangle())
                    }.accessibilityLabel(panel == .pot ? "Terracotta pot" : "Token slot")
                } else {
                    Button { store.openContainer(panel) } label: {
                        Image(systemName: "key.fill").font(.system(size: 24)).frame(width: 70, height: 60)
                            .background(IvyType.cream.opacity(0.15), in: Circle())
                    }.offset(y: -max(115, min(210, height - 80)) * 0.125).accessibilityLabel("Use selected key in drawer lock")
                }
            }.frame(height: max(115, min(210, height - 80))).animation(store.prefersReducedMotion ? nil : .easeInOut(duration: 0.65), value: opened)

        }
    }
    private var inspectionSurface: InspectionSurface {
        switch panel {
        case .pot, .drawer, .linen, .dispenser: .scene(containerImage(store.memories.opened.contains(panel.rawValue)))
        case .wholeBox: .scene(store.memories.opened.contains("wholeBox") ? "memory-box" : "memory-box-closed")
        case .bath: .scene("memory-bath")
        case .blanket: .scene("memory-blanket-open")
        case .perfume: .scene("memory-perfume")
        case .dictionary, .dictionarySong: .scene("later-dictionary-open-book-background")
        case .cinema, .cinemaCase, .cinemaProjector, .cinemaTicket: .scene("later-cinema-projection-booth-background")
        case .taxi: .scene("memory-taxi")
        case .bigTop, .mexican: .scene("memory-noodle")
        case .ferris, .ferrisTicket, .ferrisGate, .ferrisCabin, .ferrisCamera: .scene("later-ferris-exterior-background")
        case .ticket: .puzzle
        case .travelBook: .scene("memory-travel-book")
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
    private func containerImage(_ opened: Bool) -> String {
        switch panel {
        case .drawer: opened ? "memory-drawer" : "memory-drawer-closed"
        case .wholeBox: "memory-box"
        case .dispenser: opened ? "memory-cabinet" : "memory-cabinet-closed"
        case .pot: opened ? "memory-pot" : "memory-pot-covered"
        default: store.memories.picked.contains(.cloth) ? "memory-linen-empty" : "memory-linen"
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
                    InspectionBackdrop(surface: .scene("memory-box-puzzle"))
                    if !isEnteringText {
                        IvyType.inscription("i love u")
                            .font(IvyType.script(min(36, size.width * 0.052)))
                            .foregroundStyle(IvyType.ink)
                            .position(x: size.width * 0.23, y: size.height * 0.43)
                    }
                    PuzzleInputLine(text: $store.memories.wholeDraft, limit: 10,
                                    mode: .phrase, submit: store.submitWhole,
                                    onFocusChange: { isEnteringText = $0 })
                        .frame(width: isEnteringText ? min(300, size.width - 32) : min(300, size.width * 0.42))
                        .position(x: size.width * (isEnteringText ? 0.56 : 0.73), y: size.height * 0.43)
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
    var imageName: String { self == .ferrisTicket ? "ferris-ride-ticket" : self == .ferrisPhone ? "ferris-selfie-phone" : self == .cinemaFilm ? "cinema-film-blank" : self == .fountainPen ? "later-dictionary-fountain-pen" : isFragranceTool ? fragranceImageName : self == .dinnerMenu ? "bt2-menu-cover" : self == .ticket ? "ticket-paper" : self == .sewingKit ? "memory-twine" : self == .eraser ? "tool-eraser" : self == .napkin ? "tool-cloth" : "tool-" + rawValue }
}
extension GameStore {
    func traceTicket() {
        guard room == .plane, overlay == .memory(.ticket), !exploration.clues.contains(.travelOrder) else { return }
        guard use(.eraser) else { return }
        discover(.travelOrder); consume(.eraser); sceneHint = ""; persistNow()
    }
}
