import SwiftUI

struct PerfumeCloseupView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel

    private var cabinet: String? {
        switch panel {
        case .perfumeWood: "wood"
        case .perfumeBotanical: "botanical"
        case .perfumeSpice: "spice"
        case .perfumeLab: "lab"
        default: nil
        }
    }
    private var background: String {
        if let cabinet {
            if cabinet == "botanical" { return store.perfumery.opened.contains(cabinet) ? "ll3-botanical-tray" : "ll-botanical-closed" }
            if cabinet == "spice" { return "ll-spice-open" }
            return store.perfumery.opened.contains(cabinet) ? "ll-cabinet" : "ll-cabinet-closed"
        }
        if panel == .perfumeFormula { return "ll4-formula-" + PerfumeFormula.all[store.perfumery.formulaPage].bottle.rawValue }
        if panel == .perfume { return "ll4-box" }
        return "ll4-bench"
    }

    var body: some View {
        if panel == .perfume && store.perfumery.arranged {
            ElementMemoryView(store: store, image: "ll-perfume-trio", title: "Le Labo",
                              line: EggId.perfume.memoryLine, back: store.backFromMemory)
        } else {
            FittedSceneStage {
                GeometryReader { geometry in
                    ZStack {
                        InspectionBackdrop(surface: .scene(background)).id(background).transition(.opacity)
                        if let cabinet {
                            ingredients(cabinet, size: geometry.size)
                        } else if panel == .perfumeFormula {
                            Color.clear.accessibilityElement(children: .ignore)
                                .accessibilityLabel(store.clueText(PerfumeFormula.all[store.perfumery.formulaPage].clue))
                        } else if panel == .perfumeMix {
                            mixing(size: geometry.size)
                        } else {
                            presentation(size: geometry.size)
                        }
                        if panel != .perfumeFormula {
                            VStack { Spacer(); SceneFeedback(store: store, height: 36) }.allowsHitTesting(false)
                        }
                    }
                }
            }
            .gameBackAction(store.backFromMemory)
            .onDisappear { store.selectedPerfumeBottle = nil }
            .onChange(of: store.selectedTool) { _, tool in
                if tool != nil { store.selectedPerfumeBottle = nil }
            }
            .preference(key: GamePageNavigationKey.self, value: panel == .perfumeFormula ? GamePageNavigation(
                canGoPrevious: store.perfumery.formulaPage > 0,
                canGoNext: store.perfumery.formulaPage < 2,
                previous: { store.turnFormulaPage(-1) }, next: { store.turnFormulaPage(1) }
            ) : nil)
        }
    }

    private func ingredients(_ cabinet: String, size: CGSize) -> some View {
        let opened = store.perfumery.opened.contains(cabinet)
        return ZStack {
            if opened {
                IngredientShelfObjects(store: store, cabinet: cabinet, closeup: true)
                    .frame(width: size.width, height: size.height)
            } else {
                Color.clear.frame(width: size.width, height: size.height)
                .contentShape(Rectangle())
                .onTapGesture { withAnimation(store.prefersReducedMotion ? nil : .easeInOut(duration: 0.3)) { store.openIngredientCabinet(cabinet) } }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Open the " + cabinet + " cabinet")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { store.openIngredientCabinet(cabinet) }
            }
        }
    }

    private func mixing(size: CGSize) -> some View {
        let scale = size.width / 320
        return ZStack {
            PerfumeBenchCabinet(opened: store.perfumery.opened.contains("lab"))
            if store.perfumery.opened.contains("lab") {
                IngredientShelfObjects(store: store, cabinet: "lab", closeup: false)
            }
            ForEach(0..<3) { slot in
                if let tool = store.perfumery.mixture[slot] {
                    PerfumeBenchObject(tool: tool, slot: slot)
                }
            }
            PerfumeTrayFronts()
            if let bottle = store.perfumery.output {
                FragranceBottleArtwork(tool: bottle, showLabel: false)
                    .frame(width: PerfumePlacement.output.width * scale,
                           height: PerfumePlacement.output.height * scale)
                    .position(x: PerfumePlacement.output.midX * scale,
                              y: PerfumePlacement.output.midY * scale)
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
            PerfumeBenchControls(store: store)
        }.animation(store.prefersReducedMotion ? .linear(duration: 0.12) : .easeOut(duration: 0.3), value: store.perfumery.output)
    }

    private func presentation(size: CGSize) -> some View {
        let scale = size.width / 320
        return ZStack {
            ForEach(0..<3) { slot in
                presentationSlot(slot, size: size)
                    .position(x: PerfumePlacement.boxCenters[slot] * scale,
                              y: (PerfumePlacement.boxBottleBottom - PerfumePlacement.boxBottleSize.height / 2) * scale)
            }
            PerfumeBoxFront()
        }
    }

    private func presentationSlot(_ slot: Int, size: CGSize) -> some View {
        let bottle = store.perfumery.arrangement[slot]
        return Button {
            if let held = store.selectedTool, held.formula != nil {
                store.selectedPerfumeBottle = nil; store.placePerfume(held, at: slot)
            } else if let moving = store.selectedPerfumeBottle {
                if moving != bottle { store.placePerfume(moving, at: slot) }
                store.selectedPerfumeBottle = nil
            } else {
                store.selectedTool = nil
                store.selectedPerfumeBottle = bottle
            }
        } label: {
            ZStack {
                Color.clear
                if let bottle {
                    SeatedPerfumeArtwork(tool: bottle)
                        .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
                        .opacity(store.selectedPerfumeBottle == bottle ? 0.78 : 1)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(IvyType.cream.opacity(bottle != nil && store.selectedPerfumeBottle == bottle ? 0.9 : 0), lineWidth: 2))
            .frame(width: PerfumePlacement.boxBottleSize.width * size.width / 320,
                   height: PerfumePlacement.boxBottleSize.height * size.width / 320)
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel("Presentation position \(slot + 1): " + (bottle?.label ?? "empty"))
            .accessibilityAction(named: "Return bottle") {
                store.selectedPerfumeBottle = nil
                store.returnPerfume(at: slot)
            }
            .onChange(of: store.perfumery.arrangement) { _, arrangement in
                if let selected = store.selectedPerfumeBottle, !arrangement.contains(selected) { store.selectedPerfumeBottle = nil }
            }
            .draggable(bottle.map { "ivy-tool:" + $0.rawValue } ?? "")
            .dropDestination(for: String.self) { items, _ in
                guard let token = items.first, token.hasPrefix("ivy-tool:"),
                      let tool = AdventureTool(rawValue: String(token.dropFirst("ivy-tool:".count))),
                      tool.formula != nil,
                      store.exploration.tools.contains(tool) || store.perfumery.arrangement.contains(tool) else { return false }
                store.selectedPerfumeBottle = nil; store.placePerfume(tool, at: slot)
                return true
            }
    }
}

/// The worktop is already in view: use its objects without opening another page.
struct PerfumeBenchControls: View {
    let store: GameStore

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let scale = size.width / 320
            ZStack {
                ForEach(0..<3) { slot in
                    mixtureSlot(slot, size: size)
                        .position(x: PerfumePlacement.trayCenters[slot] * scale, y: 111 * scale)
                }
                if let bottle = store.perfumery.output {
                    Button(action: store.takePerfume) {
                        Color.clear
                            .frame(width: max(48, PerfumePlacement.output.width * scale),
                                   height: max(48, PerfumePlacement.output.height * scale))
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .position(x: PerfumePlacement.output.midX * scale,
                                  y: PerfumePlacement.output.midY * scale)
                        .accessibilityLabel("Take " + bottle.label)
                }
                Button(action: store.blendPerfume) {
                    Color.clear.frame(width: max(48, size.width * 0.19), height: max(48, size.height * 0.24))
                        .contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .position(x: size.width * 0.81, y: size.height * 0.25)
                    .accessibilityLabel("Press the bottling handle")
            }
            .disabled(store.perfumery.arranged || store.collected.contains(.perfume))
        }
    }

    private func mixtureSlot(_ slot: Int, size: CGSize) -> some View {
        let tool = store.perfumery.mixture[slot]
        let available = store.perfumery.output == nil && !store.perfumery.arranged && !store.collected.contains(.perfume)
        return Button {
            if let selected = store.selectedTool, selected.ingredient != nil {
                store.putIngredient(selected, at: slot)
            } else if tool != nil {
                store.removeIngredient(at: slot)
            } else {
                store.showSceneHint("The tray is empty.", presentation: .interaction)
            }
        } label: {
            Color.clear.frame(width: max(48, size.width * 0.18), height: max(48, size.height * 0.22))
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
            .disabled(!available)
            .accessibilityLabel(tool.map { "Mixture material: " + $0.label } ?? "Empty mixture tray \(slot + 1)")
            .accessibilityAction(named: "Return ingredient") { store.removeIngredient(at: slot) }
            .inventoryToolDrop(store: store, accepting: available ? PerfumeIngredient.tools : []) { store.putIngredient($0, at: slot) }
    }
}

struct PerfumeOrderInscription: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(["X", "XXII", "XXX"].enumerated()), id: \.offset) { index, numeral in
                Text(numeral).font(IvyType.hand(19)).multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                if index < 2 { Text("→").font(IvyType.hand(16)) }
            }
        }.foregroundStyle(IvyType.ink)
    }
}

struct FragranceBottleArtwork: View {
    let tool: AdventureTool
    var showLabel = true
    var body: some View {
        GeometryReader { geometry in
            let spriteSize = SceneArtwork.image(named: tool.fragranceImageName).size
            let aspect = max(1, spriteSize.width) / max(1, spriteSize.height)
            let width = min(geometry.size.width, geometry.size.height * aspect)
            let height = width / aspect
            ZStack {
                Image(tool.fragranceImageName).resizable().interpolation(.high).scaledToFit()
            }.frame(width: width, height: height)
                .frame(width: geometry.size.width, height: geometry.size.height,
                       alignment: tool.ingredient == nil ? .center : .bottom)
        }
        .accessibilityLabel(tool.label)
    }
}

struct PerfumeTrioArtwork: View {
    var body: some View {
        HStack(spacing: 2) {
            ForEach(PerfumeFormula.bottles) { bottle in
                FragranceBottleArtwork(tool: bottle)
            }
        }
    }
}

/// Reference-canvas placement: bottom is the physical support line, not sprite centre.
struct IngredientShelfSlot {
    let x: CGFloat
    let bottom: CGFloat
    let width: CGFloat
    let height: CGFloat
    init(_ x: CGFloat, _ bottom: CGFloat, _ width: CGFloat, _ height: CGFloat) {
        self.x = x; self.bottom = bottom; self.width = width; self.height = height
    }
}

enum IngredientShelfLayout {
    // Measured against the authored 320×160 backgrounds. IDs never shift after pickup.
    static let world: [AdventureTool: IngredientShelfSlot] = [
        .gaiacWood: .init(92, 42, 18, 17), .cedar: .init(126, 42, 17, 20),
        .incense: .init(92, 64, 18, 16), .oakmoss: .init(126, 64, 18, 17),
        .patchouli: .init(92, 87, 17, 19), .vetiver: .init(126, 87, 17, 20),
        .bergamot: .init(65, 76, 9, 11), .grapefruit: .init(75, 76, 9, 11),
        .petitgrain: .init(85, 76, 9, 13), .orangeBlossom: .init(95, 76, 9, 13),
        .iris: .init(105, 76, 9, 12), .violet: .init(115, 76, 9, 9),
        .jasmine: .init(125, 76, 9, 13),
        .musk: .init(56, 36, 18, 23), .crystalMoss: .init(89, 36, 18, 23),
        .clearwood: .init(56, 73, 18, 27), .ambroxyde: .init(89, 73, 18, 27)
    ]
    static let closeup: [AdventureTool: IngredientShelfSlot] = [
        .gaiacWood: .init(74, 67, 52, 43), .cedar: .init(160, 67, 50, 49),
        .incense: .init(246, 67, 52, 41), .oakmoss: .init(74, 129, 52, 43),
        .patchouli: .init(160, 129, 48, 48), .vetiver: .init(246, 129, 48, 49),
        .bergamot: .init(60, 66, 45, 39), .grapefruit: .init(121, 66, 45, 39),
        .petitgrain: .init(183, 66, 43, 43), .orangeBlossom: .init(246, 66, 42, 43),
        .iris: .init(60, 124, 43, 43), .violet: .init(121, 124, 45, 36),
        .jasmine: .init(183, 124, 43, 43),
        .cinnamon: .init(59, 86, 46, 52), .pimentoBay: .init(126, 86, 46, 55),
        .pinkPepper: .init(193, 86, 46, 42), .cardamom: .init(260, 86, 46, 39),
        .musk: .init(104, 67, 55, 47), .crystalMoss: .init(215, 67, 55, 47),
        .clearwood: .init(104, 129, 55, 49), .ambroxyde: .init(215, 129, 55, 49)
    ]
}

/// Art, touch target and shelf anchor share one transform. Captions never push art off a shelf.
struct IngredientShelfObjects: View {
    let store: GameStore
    let cabinet: String
    let closeup: Bool
    // Lettering belongs to the solid divider/front face, never the open compartment.
    private func labelBaseline(for slot: IngredientShelfSlot) -> CGFloat {
        switch cabinet {
        case "botanical": slot.bottom < 100 ? 78 : 137
        case "spice": 96
        default: slot.bottom < 100 ? 74 : 139
        }
    }
    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 320, geometry.size.height / 160)
            ZStack(alignment: .topLeading) {
                ForEach(PerfumeIngredient.world.filter { $0.cabinet == cabinet }) { ingredient in
                    if !store.perfumery.found.contains(ingredient.tool),
                       let slot = (closeup ? IngredientShelfLayout.closeup : IngredientShelfLayout.world)[ingredient.tool] {
                        Group {
                            if closeup {
                                Button { store.takeIngredient(ingredient.tool) } label: {
                                    FragranceBottleArtwork(tool: ingredient.tool, showLabel: false)
                                        .frame(width: slot.width * scale, height: slot.height * scale)
                                        .contentShape(Rectangle())
                                }.buttonStyle(.plain)
                                    .disabled(store.perfumery.arranged || store.collected.contains(.perfume))
                                    .accessibilityLabel("Take " + ingredient.name)
                            } else {
                                FragranceBottleArtwork(tool: ingredient.tool, showLabel: false)
                                    .frame(width: slot.width * scale, height: slot.height * scale)
                            }
                        }
                        .position(x: slot.x * scale, y: (slot.bottom - slot.height / 2) * scale)
                        if closeup {
                            Image("ll4-label-" + ingredient.tool.rawValue)
                                .resizable().interpolation(.high).scaledToFit()
                                .frame(width: (slot.width + 8) * scale, height: 7 * scale)
                                .position(x: slot.x * scale, y: labelBaseline(for: slot) * scale)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }.frame(width: 320 * scale, height: 160 * scale)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}
