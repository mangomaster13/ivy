import SwiftUI

/// Coordinates follow the complete 2:1 artwork within the content viewport.
private struct GelatoStageGeometry {
    let size: CGSize
    var artWidth: CGFloat { size.width }
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: (size.width - artWidth) / 2 + artWidth * x,
                y: (size.height - artWidth / 2) / 2 + artWidth / 2 * y)
    }
}

/// Gelato uses physical artwork with the game's existing Back and feedback controls.
private struct GelatoStage<Content: View>: View {
    let store: GameStore
    let image: String
    let back: () -> Void
    var feedbackHeight: CGFloat = 58
    @ViewBuilder var content: (GelatoStageGeometry) -> Content

    var body: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let stage = GelatoStageGeometry(size: geometry.size)
                ZStack(alignment: .topLeading) {
                    InspectionBackdrop(surface: .scene(image))
                    content(stage)
                    SceneFeedback(store: store, height: feedbackHeight)
                        .padding(.horizontal, 20)
                        .frame(width: geometry.size.width)
                        .position(x: geometry.size.width / 2, y: geometry.size.height - feedbackHeight / 2 - 2)
                    // Dismissing a reaction consumes the tap, never touching the object below it.
                    if !store.sceneHint.isEmpty && store.sceneHintPresentation == .interaction {
                        Color.clear.contentShape(Rectangle())
                            .onTapGesture { store.dismissSceneHint() }
                            .accessibilityLabel("Dismiss memory")
                            .accessibilityAddTraits(.isButton)
                            .accessibilityAction(.escape) { store.dismissSceneHint() }
                    }
                }
            }
        }.foregroundStyle(IvyType.cream)
            .gameBackAction(back)
    }
}

struct GelatoCloseupView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel
    private var opened: Bool { store.memories.opened.contains("dispenser") }
    private var kept: Bool { store.collected.contains(.gelato) }
    private var image: String {
        switch panel {
        case .dispenser: store.gelatoCabinetImageName
        default: store.gelatoServingImageName
        }
    }

    var body: some View {
        // A restored legacy overlay may render before openMemory redirects it.
        // Keep both the cup artwork and its flavour accessibility label gated.
        if (panel == .menu || panel == .tasting) && !store.gelatoWords.flavorSolved && !kept {
            GelatoWordMenuView(store: store)
        } else {
            GelatoStage(store: store, image: image, back: store.backFromMemory) { stage in
                if panel == .dispenser { utensils(stage) }
                else { tasting(stage) }
            }
            .inventoryToolDrop(store: store, accepting: panel == .dispenser && !opened ? [.coin] : []) { _ in
                store.openContainer(.dispenser)
            }
        }
    }

    private func utensils(_ stage: GelatoStageGeometry) -> some View {
        ZStack(alignment: .topLeading) {
            if opened {
                if !store.memories.picked.contains(.scoop) {
                    Button { store.pickup(.scoop, from: .dispenser) } label: {
                        // Painted scoop hangs from the cabinet-back clip, x140...165/y42...110.
                        Color.clear
                            .frame(width: max(48, stage.artWidth * 25 / 320), height: max(48, stage.size.height * 68 / 160))
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel("Gelato scoop")
                        .position(stage.point(152.5 / 320, 76 / 160))
                }
            } else {
                Button { store.openContainer(.dispenser) } label: {
                    Color.clear.frame(width: stage.artWidth * 0.2, height: max(48, stage.size.height * 0.38))
                        .contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("Utensil box token slot")
                    .position(stage.point(0.48, 0.48))
            }
        }
    }

    private func tasting(_ stage: GelatoStageGeometry) -> some View {
        Button { store.taste(2) } label: {
            // Cup is painted into its saucer; the pickup target uses the same footprint.
            Color.clear
                .frame(width: max(48, stage.artWidth * 28 / 320), height: max(48, stage.size.height * 34 / 160))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .inventoryToolDrop(store: store, accepting: kept ? [] : [.scoop]) { _ in store.taste(2) }
        .accessibilityLabel("Taste the jasmine gelato with the selected spoon")
        .position(stage.point(258 / 320, 102 / 160))
    }

}

extension GameStore {
    var gelatoCabinetImageName: String {
        guard memories.opened.contains("dispenser") else { return "cabinet-state-closed" }
        return memories.picked.contains(.scoop) ? "cabinet-state-empty" : "cabinet-state-scoop"
    }
    var gelatoServingImageName: String {
        if collected.contains(.gelato) { return "gelato-state-tasted" }
        return gelatoWords.flavorSolved ? "gelato-state-served" : "gelato-state-empty"
    }
}

/// Legacy recipe entry uses the readable menu, without a second inspection layer.
struct GelatoRecipeView: View {
    @Bindable var store: GameStore
    var body: some View {
        GelatoCloseupView(store: store, panel: .menu)
            .onAppear {
                store.returnToRecipe = false
                store.memoryNavigation = []
                store.overlay = .memory(.menu)
                store.discover(.recipe)
            }
    }
}
