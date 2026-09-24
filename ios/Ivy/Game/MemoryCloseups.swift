import SwiftUI

/// Closeups share a bounded content stage; feedback never changes the world's size.
struct MemoryCloseupView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel
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
                SceneFeedback(store: store)
            }.foregroundStyle(IvyType.cream)
        }
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
        case .ferris: .scene("memory-ferris")
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

/// Deliberate letter selection only; never invokes the system keyboard.
/// The box and inscription share the artwork coordinates; controls stay native.
private struct WholeBoxPuzzleView: View {
    @Bindable var store: GameStore
    private let keyboardWidth: CGFloat = 272

    var body: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let size = geometry.size
                let compact = size.height < 280
                let stackedActions = size.height >= 324
                let controlsHeight: CGFloat = compact ? 160 : (stackedActions ? 272 : 216)
                let controlsX = size.width - keyboardWidth / 2 - 16
                let controlsY = (size.height - 52) / 2

                ZStack(alignment: .topLeading) {
                    InspectionBackdrop(surface: .scene("memory-box-puzzle"))
                    IvyType.inscription("i love u")
                        .font(IvyType.script(min(36, size.width * 0.052)))
                        .foregroundStyle(IvyType.ink)
                        .position(x: size.width * 0.23, y: size.height * 0.43)

                    if compact {
                        answer
                            .frame(width: min(220, size.width * 0.42))
                            .position(x: size.width * 0.23, y: 28)
                    }

                    VStack(spacing: 8) {
                        if !compact { answer }
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(48), spacing: 8), count: 5), spacing: 8) {
                            ForEach(Array("aswholevri").map(String.init), id: \.self) { glyph in
                                PuzzleButton(glyph, width: 48) { append(glyph) }
                                    .frame(width: 48, height: 48)
                            }
                        }
                        if stackedActions {
                            PuzzleButton("space", width: keyboardWidth) { append(" ") }
                            PuzzleButton("Enter", width: keyboardWidth, action: store.submitWhole)
                        } else {
                            HStack(spacing: 8) {
                                PuzzleButton("space", width: 132) { append(" ") }
                                PuzzleButton("Enter", width: 132, action: store.submitWhole)
                            }
                        }
                    }
                    .frame(width: keyboardWidth, height: controlsHeight)
                    .position(x: controlsX, y: controlsY)

                    SceneFeedback(store: store)
                        .frame(width: size.width - 32)
                        .position(x: size.width / 2, y: size.height - 26)
                }
            }
        }
        .gameBackAction(store.backFromMemory)
        .onChange(of: store.memories.wholeDraft) { _, _ in
            store.dismissSceneHint()
            store.persistNow()
        }
    }

    private var answer: some View {
        HStack(spacing: 4) {
            Text(store.memories.wholeDraft.isEmpty ? "…" : store.memories.wholeDraft)
                .font(IvyType.hand(26))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(store.memories.wholeDraft.isEmpty ? "Empty answer" : "Assembled: " + store.memories.wholeDraft)
            Button {
                if !store.memories.wholeDraft.isEmpty { store.memories.wholeDraft.removeLast() }
            } label: {
                Image(systemName: "delete.left")
                    .font(.system(size: 23, weight: .regular))
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(store.memories.wholeDraft.isEmpty)
            .opacity(store.memories.wholeDraft.isEmpty ? 0.4 : 1)
            .accessibilityLabel("Delete last character")
        }
        .foregroundStyle(IvyType.ink)
        .padding(.leading, 12).padding(.trailing, 4)
        .background(HandcutKey().fill(IvyType.cream))
        .overlay(HandcutKey().stroke(IvyType.ink.opacity(0.65), lineWidth: 1))
    }

    private func append(_ glyph: String) {
        guard store.memories.wholeDraft.count < 10 else { return }
        if glyph == " " && (store.memories.wholeDraft.isEmpty || store.memories.wholeDraft.hasSuffix(" ")) { return }
        store.memories.wholeDraft += glyph
    }
}

struct WordAnswer: View {
    @Binding var text: String
    let placeholder: String
    let glyphs: String
    var limit: Int = 12
    var spaces = false
    var feedbackStore: GameStore? = nil
    let submit: () -> Void
    var body: some View {
        VStack(spacing: 8) {
            PuzzleInputLine(text: text) { if !text.isEmpty { text.removeLast() } }
            SuppliedKeyGrid(glyphs: Array(glyphs).map(String.init), columns: 5, append: { glyph in
                guard text.count < limit else { return }
                if glyph == " " && (text.isEmpty || text.hasSuffix(" ")) { return }
                text += glyph
            }, submit: submit, spaces: spaces)

        }
        // The enclosing closeup owns the reserved feedback row. Duplicating it
        // here pushes this fixed-size keyboard outside short landscape stages.
        .background(HandcutKey().fill(IvyType.ink.opacity(0.93)))
        .frame(minWidth: 272, maxWidth: 430)
        .onChange(of: text) { _, _ in feedbackStore?.dismissSceneHint() }
    }
}

extension AdventureTool {
    var imageName: String { self == .cinemaFilm ? "later-cinema-acetate-film" : self == .fountainPen ? "later-dictionary-fountain-pen" : isFragranceTool ? fragranceImageName : self == .dinnerMenu ? "bt2-menu-cover" : self == .ticket ? "ticket-paper" : self == .sewingKit ? "memory-twine" : self == .eraser ? "tool-eraser" : self == .napkin ? "tool-cloth" : "tool-" + rawValue }
}
extension GameStore {
    func traceTicket() {
        guard room == .plane, overlay == .memory(.ticket), !exploration.clues.contains(.travelOrder) else { return }
        guard use(.eraser) else { return }
        discover(.travelOrder); consume(.eraser); sceneHint = ""; persistNow()
    }
}
