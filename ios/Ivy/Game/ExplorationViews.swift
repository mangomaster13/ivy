import SwiftUI

struct AdventureTray: View {
    @Bindable var store: GameStore
    private var orderedTools: [AdventureTool] {
        let held = AdventureTool.allCases.filter { store.exploration.tools.contains($0) }
        return held.filter { $0.formula != nil } + held.filter { $0.formula == nil }
    }
    private var returningSlot: Int? {
        guard store.overlay == .memory(.perfume), !store.perfumery.arranged,
              let bottle = store.selectedPerfumeBottle else { return nil }
        return store.perfumery.arrangement.firstIndex(of: bottle)
    }
    var body: some View {
        HStack(spacing: 4) {
            Button {
                if let slot = returningSlot {
                    store.returnPerfume(at: slot)
                } else {
                    store.closeElementForFooter()
                    store.toolsVisible.toggle()
                }
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: store.toolsVisible && returningSlot == nil ? "heart.text.square" : "bag").font(.system(size: 18))
                    Image(store.toolsVisible && returningSlot == nil ? "ll4-footer-memories" : "ll4-footer-tools")
                        .resizable().scaledToFit().frame(width: 70, height: 16)
                }.frame(width: 76, height: 48)
            }
            .accessibilityLabel(returningSlot != nil ? "Return selected bottle to tools" : store.toolsVisible ? "Show keepsakes" : "Show tools")
            .disabled(store.collectingEgg != nil)
            Button(action: store.openNotebook) {
                Image("tool-notebook").resizable().interpolation(.high).scaledToFit()
                    .frame(width: 38, height: 38).frame(width: 48, height: 48)
                    .overlay(alignment: .topTrailing) {
                        if store.notebookClueFlash {
                            Circle().fill(IvyType.cream).frame(width: 7, height: 7)
                        }
                    }
            }
            .accessibilityLabel("Clue notebook")
            .disabled(store.overlay == .adventure(.notebook) || store.collectingEgg != nil)
            .frame(width: store.toolsVisible && store.collectingEgg == nil ? 48 : 0)
            .opacity(store.toolsVisible && store.collectingEgg == nil ? 1 : 0)
            .allowsHitTesting(store.toolsVisible && store.collectingEgg == nil)
            .accessibilityHidden(!store.toolsVisible || store.collectingEgg != nil)
            ScrollViewReader { reader in
                ZStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach((0..<3).filter { store.roseProgress.found.contains($0) && !store.rosePetals.contains($0) }, id: \.self) { index in
                                RosePetalTool(store: store, index: index)
                            }
                            ForEach(orderedTools) { tool in
                                ToolButton(store: store, tool: tool)
                            }
                        }.padding(.horizontal, 6)
                    }
                    .scrollClipDisabled()
                    .opacity(store.toolsVisible && store.collectingEgg == nil ? 1 : 0)
                    .allowsHitTesting(store.toolsVisible && store.collectingEgg == nil)
                    .accessibilityHidden(!store.toolsVisible || store.collectingEgg != nil)
                    ScrollView(.horizontal, showsIndicators: false) { InventoryBar(store: store) }
                        .opacity(store.toolsVisible && store.collectingEgg == nil ? 0 : 1)
                        .allowsHitTesting(!store.toolsVisible && store.collectingEgg == nil)
                        .accessibilityHidden(store.toolsVisible && store.collectingEgg == nil)
                }
                .onChange(of: store.collectingEgg) { _, egg in
                    if let egg {
                        store.toolsVisible = false
                        reader.scrollTo(egg, anchor: .center)
                    }
                }
            }
        }
        .font(IvyType.hand(16)).foregroundStyle(IvyType.cream)
        .padding(.horizontal, 4).frame(height: GameLayout.footerHeight).background(Color("Night"))
        .dropDestination(for: String.self) { items, _ in
            guard store.toolsVisible, store.overlay == .memory(.perfume),
                  let token = items.first, token.hasPrefix("ivy-tool:"),
                  let bottle = AdventureTool(rawValue: String(token.dropFirst("ivy-tool:".count))),
                  let slot = store.perfumery.arrangement.firstIndex(of: bottle),
                  !store.perfumery.arranged else { return false }
            store.returnPerfume(at: slot)
            return true
        }
    }
}

struct ToolButton: View {
    @Bindable var store: GameStore
    let tool: AdventureTool
    @State private var showsName = false
    @State private var nameFlash = 0
    var body: some View {
        Button { flashName(); store.chooseTool(tool) } label: {
            Group {
                if tool.isFragranceTool { FragranceBottleArtwork(tool: tool, showLabel: false) }
                else if tool == .dinnerMenu { DinnerMenuArtwork() }
                else { Image(tool.imageName).resizable().interpolation(.high).scaledToFit() }
            }
            .frame(width: 30, height: 30)
            .frame(width: 48, height: 48)
            .background(IvyType.cream.opacity(store.selectedTool == tool ? 0.2 : 0), in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(IvyType.cream.opacity(store.selectedTool == tool ? 0.8 : 0.15)))
        }.buttonStyle(.plain).accessibilityLabel(tool.label)
            .accessibilityValue(store.selectedTool == tool ? "Selected" : "Not selected")
            .accessibilityHint(tool.description)
            .draggable("ivy-tool:" + tool.rawValue)
            .simultaneousGesture(DragGesture(minimumDistance: 2).onChanged { _ in
                if !showsName { flashName() }
            })
            .overlay(alignment: .top) {
                if showsName {
                    Text(tool.label).font(IvyType.hand(13)).fixedSize()
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color("Night"), in: RoundedRectangle(cornerRadius: 5))
                        .offset(y: -25).allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .task(id: nameFlash) {
                guard nameFlash > 0 else { return }
                try? await Task.sleep(for: .seconds(1.3))
                if !Task.isCancelled { showsName = false }
            }
    }
    private func flashName() { showsName = true; nameFlash += 1 }
}

struct ExplorationNavigation: View {
    @Bindable var store: GameStore
    var body: some View {
        HStack(spacing: 0) {
            directionSlot(-1)
            Spacer(minLength: 0)
            directionSlot(1)
        }
        .foregroundStyle(IvyType.cream)
    }
    private func directionSlot(_ delta: Int) -> some View {
        ZStack {
            if store.canExplore && store.sceneViews.contains(store.sceneView + delta) {
                SceneNavigationButton(kind: .scene(previous: delta < 0),
                                      label: delta < 0 ? "Look left in this location" : "Look right in this location") {
                    store.dismissSceneHint()
                    store.turnView(delta)
                }
            }
        }
        .frame(width: GameLayout.navigationGutter, height: 48)
    }

}

struct AdventurePanelView: View {
    @Bindable var store: GameStore
    let panel: AdventurePanel
    private var title: String {
        switch panel {
        case .notebook: "little things worth keeping"
        case .journal: "the marks we leave"
        case .mirror: "a room behind the glass"
        case .musicScore: "three notes for you"
        case .musicBox: "play it back to me"
        case .recipe: "a little sweetness in the rain"
        case .freezer: "cold enough to keep"
        }
    }

    private var inspectionSurface: InspectionSurface {
        switch panel {
        case .musicBox, .freezer: .puzzle
        case .mirror: .scene("explore-corridor-mirror")
        case .journal: .puzzle
        case .recipe: .scene("explore-gelato-bench")
        case .musicScore: .scene("explore-bedroom-desk")
        case .notebook: .puzzle // Rendered by its own physical notebook below.
        }
    }

    var body: some View {
        if panel == .notebook {
            ClueNotebookView(store: store)
        } else if panel == .recipe {
            GelatoRecipeView(store: store)
        } else if panel == .mirror {
            MirrorRubbingCloseup(store: store)
                .inventoryToolDrop(store: store, accepting: [.cloth])
        } else {
        KeepsakeSheet(back: store.cancelOverlay, surface: inspectionSurface) {
            VStack(spacing: 8) {

                content.frame(maxWidth: .infinity, maxHeight: .infinity).padding(.vertical, 6)
                SceneFeedback(store: store)
            }.foregroundStyle(IvyType.cream)
        }
    }
        }


    @ViewBuilder private var content: some View {
        switch panel {
        case .notebook:
            EmptyView() // The notebook has its own surface and navigation.
        case .journal:
            discovery(.travelOrder, tool: .eraser, instruction: "Paper impressions", action: store.rubJournal)
        case .mirror:
            discovery(.mirror, tool: .cloth, instruction: "Misted mirror", action: store.wipeMirror)
        case .musicScore:
            VStack(spacing: 16) {
                HStack(spacing: 35) {
                    ForEach([2, 0, 1], id: \.self) { note in
                        VStack {
                            Image(systemName: "music.note").font(.system(size: 28))
                                .offset(y: CGFloat(1 - note) * 8).frame(height: 48)
                            Text(["low", "middle", "high"][note]).font(IvyType.hand(20))
                        }
                    }
                }
                IvyType.inscription("high, low, then somewhere in between.").font(IvyType.script(24))
            }
        case .musicBox:
            VStack(spacing: 14) {
                if store.exploration.musicBoxOpened {
                    Text("The melody opened a little secret.").font(IvyType.hand(20))
                } else {
                    HStack(spacing: 24) {
                        ForEach(0..<3) { note in
                            Button { store.playMusicNote(note) } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: "music.note").font(.system(size: CGFloat(22 + note * 6)))
                                    Text(["low", "middle", "high"][note]).font(IvyType.hand(20))
                                }.frame(width: 100, height: 96)
                                    .background(IvyType.cream.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                            }.buttonStyle(.plain)
                        }
                    }
                    Text(store.exploration.musicInput.map { ["low", "middle", "high"][$0] }.joined(separator: " · "))
                        .font(IvyType.hand(20)).frame(height: 24)
                }
            }
        case .recipe:
            discovery(.recipe, tool: .napkin, instruction: "Rain-marked paper", action: store.wipeRecipe)
        case .freezer:
            VStack(spacing: 12) {
                IvyType.inscription("service note: keep at −12°C").font(IvyType.script(24))
                HStack(spacing: 30) {
                    action("−") { store.setFreezer(-1) }
                    Text("\(store.exploration.freezerTemperature)°C").font(IvyType.hand(43)).monospacedDigit().frame(width: 140)
                    action("+") { store.setFreezer(1) }
                }

            }
        }
    }

    private func discovery(_ clue: AdventureClue, tool: AdventureTool, instruction: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 16) {
            RubbingSurface(progress: store.rubbingBinding(clue), material: clue == .travelOrder ? .graphite : .rain,
                           revealed: store.exploration.clues.contains(clue), canRub: store.selectedTool == tool,
                           toolImage: tool.imageName, label: instruction, save: store.persistNow, completion: action) {
                IvyType.inscription(clue == .travelOrder ? "moon → leaf → star → drop" : "pale fruit · jasmine")
                    .font(IvyType.script(25)).foregroundStyle(IvyType.ink).multilineTextAlignment(.center)
            }.frame(height: 110).padding(18).frame(maxWidth: 350)
                .background(PuzzlePaper())
            if clue == .recipe && store.exploration.clues.contains(.recipe) {
                PuzzleButton("open the menu") { store.openMemory(.menu) }
            }
        }.frame(maxWidth: 560)
    }
    private func action(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(title, action: action).font(IvyType.hand(20))
            .padding(.horizontal, 20).frame(minHeight: 44)
            .background(IvyType.cream.opacity(0.14), in: Capsule()).buttonStyle(.plain)
    }
}



/// A reading object, independent of whichever room the player opened it from.
private struct ClueNotebookView: View {
    @Bindable var store: GameStore

    private var clues: [AdventureClue] {
        AdventureClue.allCases.filter { store.exploration.clues.contains($0) && !Self.fragranceClues.contains($0) }
    }
    private static let fragranceClues: [AdventureClue] = [.gaiacFormula, .bergamoteFormula, .mousseFormula, .perfumeOrder]
    private var fragrancePages: [AdventureClue] { Self.fragranceClues.filter { store.exploration.clues.contains($0) } }
    private var ordinaryPageCount: Int { max(1, (clues.count + 1) / 2) }
    private var pageCount: Int { ordinaryPageCount + fragrancePages.count }
    private var page: Int {
        guard let clue = store.memories.notebookClue else { return 0 }
        if let index = fragrancePages.firstIndex(of: clue) { return ordinaryPageCount + index }
        if let index = clues.firstIndex(of: clue) { return index / 2 }
        return 0
    }

    private func turnPage(_ delta: Int) {
        let next = min(pageCount - 1, max(0, page + delta))
        if next < ordinaryPageCount {
            let index = next * 2
            store.memories.notebookClue = clues.indices.contains(index) ? clues[index] : nil
        } else {
            store.memories.notebookClue = fragrancePages[next - ordinaryPageCount]
        }
        store.persistNow()
    }

    var body: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let compact = geometry.size.height < 340
                let spreadWidth = geometry.size.width
                let spreadHeight = geometry.size.height
                let currentPage = min(page, pageCount - 1)
                let fragrance = currentPage >= ordinaryPageCount ? fragrancePages[currentPage - ordinaryPageCount] : nil
                let formula = PerfumeFormula.all.first { $0.clue == fragrance }
                ZStack {
                    Color("Night")
                    Image(formula.map { "ll4-formula-" + $0.bottle.rawValue } ?? "ll4-notes")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: spreadWidth, height: spreadHeight)
                    if currentPage < ordinaryPageCount {
                        ForEach(0..<2) { side in
                            let index = currentPage * 2 + side
                            notebookPage(clue: index < clues.count ? clues[index] : nil, compact: compact)
                                .frame(width: spreadWidth * 0.32, height: spreadHeight * 0.53)
                                .position(x: spreadWidth * (side == 0 ? 0.29 : 0.71), y: spreadHeight * 0.44)
                        }
                    } else {
                        let clue = fragrancePages[currentPage - ordinaryPageCount]
                        if formula == nil {
                            PerfumeOrderInscription()
                                .frame(width: spreadWidth * 0.32, height: spreadHeight * 0.64)
                                .position(x: spreadWidth * 0.71, y: spreadHeight * 0.46)
                        } else {
                            Color.clear.accessibilityElement(children: .ignore)
                                .accessibilityLabel(store.clueText(clue))
                        }
                    }
                    Text("\(currentPage + 1)  ·  \(pageCount)")
                        .font(IvyType.hand(18))
                        .foregroundStyle(IvyType.ink.opacity(0.68))
                        .monospacedDigit()
                        .position(x: spreadWidth * 0.43, y: spreadHeight * 0.82)
                }
            }
        }
        .gameBackAction(store.closeNotebook)
        .onAppear {
            // Remember a real clue even when the first page was opened implicitly.
            if store.memories.notebookClue == nil { turnPage(0) }
        }
        .preference(key: GamePageNavigationKey.self, value: GamePageNavigation(
            canGoPrevious: page > 0,
            canGoNext: min(page, pageCount - 1) < pageCount - 1,
            previous: { turnPage(-1) },
            next: { turnPage(1) }
        ))
    }

    private func notebookPage(clue: AdventureClue?, compact: Bool) -> some View {
        VStack(spacing: compact ? 9 : 16) {
            Text(clue?.title ?? "little things worth keeping")
                .font(IvyType.hand(compact ? 17 : 19))
                .foregroundStyle(IvyType.ink.opacity(0.68))
            Spacer(minLength: 0)
            if let clue {
                switch clue {
                case .bigTopLedger, .bigTopMirror:
                    BigTopEvidenceArtwork(mirrored: clue == .bigTopMirror, notebook: true)
                        .frame(maxHeight: compact ? 105 : 150)
                case .travelOrder:
                    TravelOrderSymbols(symbolSize: compact ? 27 : 33)
                case .gelatoOrder:
                    GelatoOrderPaper().aspectRatio(1.5, contentMode: .fit)
                        .accessibilityLabel(store.clueText(clue))
                case .gelatoLeaves:
                    GelatoPaperExcerpt(image: "gelato-word-note", sourceSize: CGSize(width: 1536, height: 1024),
                                       bounds: CGRect(x: 200, y: 220, width: 1100, height: 590))
                        .accessibilityLabel(store.clueText(clue))
                case .recipe:
                    GelatoPaperExcerpt(image: store.gelatoWords.chainSolved ? "gelato-words-marked" : "gelato-words-unmarked",
                                       sourceSize: CGSize(width: 1774, height: 887),
                                       bounds: CGRect(x: 190, y: 220, width: 1140, height: 530))
                        .accessibilityLabel(store.clueText(clue))
                case .rainRelation:
                    Image("gelato-float-tag").resizable().interpolation(.high).scaledToFit()
                        .accessibilityLabel(store.clueText(.rainRelation))
                case .mirror:
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: compact ? 2 : 1),
                        spacing: compact ? 8 : 10
                    ) {
                        ForEach([2, 0, 3, 1], id: \.self) { index in
                            HStack(spacing: 14) {
                                Image(systemName: ["moon", "leaf", "star", "drop"][index])
                                    .font(.system(size: 20))
                                Text(String(store.exploration.hotelCode[index]))
                                    .font(IvyType.hand(compact ? 23 : 27))
                            }
                        }
                    }
                    .foregroundStyle(IvyType.ink)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(store.clueText(.mirror))
                default:
                    IvyType.inscription(store.clueText(clue))
                        .font(IvyType.script(compact ? 21 : 24))
                        .foregroundStyle(IvyType.ink)
                }
            } else {
                IvyType.inscription("No clues recorded yet.")
                    .font(IvyType.script(compact ? 21 : 24))
                    .foregroundStyle(IvyType.ink.opacity(0.65))
            }
            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A tool drop selects the held object; rubbing still follows actual finger strokes.
extension View {
    func inventoryToolDrop(store: GameStore, accepting tools: [AdventureTool],
                           action: @escaping (AdventureTool) -> Void = { _ in }) -> some View {
        dropDestination(for: String.self) { items, _ in
            guard let token = items.first, token.hasPrefix("ivy-tool:"),
                  let tool = AdventureTool(rawValue: String(token.dropFirst("ivy-tool:".count))),
                  tools.contains(tool), store.exploration.tools.contains(tool),
                  store.collectingEgg == nil, !store.isHallTransitioning else { return false }
            store.selectedTool = tool
            action(tool)
            return true
        }
    }
}
