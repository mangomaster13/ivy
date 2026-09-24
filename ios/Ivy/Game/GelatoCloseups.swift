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
        case .dispenser: opened ? "gelato-box-open" : "gelato-box-closed"
        default: "gelato-tasting"
        }
    }

    var body: some View {
        if panel == .menu {
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
                        Image(AdventureTool.scoop.imageName).resizable().interpolation(.high).scaledToFit()
                            .frame(width: stage.artWidth * 0.18, height: stage.size.height * 0.43)
                    }.buttonStyle(.plain).accessibilityLabel("Gelato scoop")
                        .position(stage.point(0.48, 0.49))
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
            Image("memory-gelato-cup").resizable().interpolation(.high).scaledToFit()
                .frame(width: stage.artWidth * 0.17, height: stage.size.height * 0.28)
                .frame(minWidth: 48, minHeight: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .inventoryToolDrop(store: store, accepting: kept ? [] : [.scoop]) { _ in store.taste(2) }
        .accessibilityLabel("Taste the jasmine gelato with the selected spoon")
        .position(stage.point(0.50, 0.77))
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
