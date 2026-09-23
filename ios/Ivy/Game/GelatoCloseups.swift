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
        case .menu: "gelato-menu-readable"
        case .dispenser: opened ? "gelato-box-open" : "gelato-box-closed"
        default: "gelato-tasting"
        }
    }

    var body: some View {
        GelatoStage(store: store, image: image, back: store.backFromMemory, feedbackHeight: panel == .menu ? 40 : 58) { stage in
            switch panel {
            case .menu: menu()
            case .dispenser: utensils(stage)
            default: tasting(stage)
            }
        }
        .inventoryToolDrop(store: store, accepting: panel == .dispenser && !opened ? [.coin] : panel == .tasting && !kept ? [.scoop] : []) { _ in
            if panel == .dispenser { store.openContainer(.dispenser) }
        }
    }

    private func menu() -> some View {
        Color.clear.accessibilityElement(children: .ignore)
            .accessibilityLabel("Dry menu: Citrus and Pepper, pomelo, mandarin and pink peppercorn; Magnolia and Longan, magnolia and fresh longan; Loquat and Jasmine, white loquat and jasmine; Basil and Tomato, basil and green tomato. The fruit and flowers came after the other fruit and flowers.")
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
        let centers: [CGFloat] = [0.235, 0.405, 0.585, 0.756]
        return ZStack(alignment: .topLeading) {
            ForEach(0..<4) { index in
                Button { store.taste(index) } label: {
                    Color.clear.frame(width: stage.artWidth * 0.155, height: max(48, stage.artWidth * 0.115))
                        .contentShape(Rectangle())
                }.buttonStyle(.plain).disabled(kept)
                    .accessibilityLabel(RememberedFlavor.names[index])
                    .accessibilityValue(store.memories.flavor == index ? "Selected" : "")
                    .position(stage.point(centers[index], 0.42))
            }
            if kept {
                Image("memory-gelato-cup").resizable().interpolation(.high).scaledToFit()
                    .frame(width: 116, height: 116)
                    .position(stage.point(0.50, 0.73))
                    .accessibilityLabel("White loquat and jasmine gelato keepsake")
                Button(action: store.recallGelatoJoke) {
                    Image(AdventureTool.scoop.imageName).resizable().interpolation(.high).scaledToFit()
                        .frame(width: 65, height: 48).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityLabel("Little spoon dish")
                    .position(stage.point(0.81, 0.72))
            } else {
                if let flavor = store.memories.flavor {
                    Image("memory-flavor-\(flavor)").resizable().interpolation(.high).scaledToFit()
                        .frame(width: 42, height: 42)
                        .position(stage.point(0.81, 0.695)).accessibilityHidden(true)
                }
            }
        }
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
