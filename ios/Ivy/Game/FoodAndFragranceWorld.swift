import SwiftUI

/// Authored lettering and removable objects share the background's exact canvas transform.
struct FoodAndFragranceWorld: View {
    let store: GameStore
    let scale: CGFloat
    var body: some View {
        ZStack(alignment: .topLeading) {
            if store.room == .gelato && store.sceneView == 0 {
                BigTopNeonLetters(order: store.bigTop.signOrder ?? "GPIBTO", progress: store.bigTop.signDraft, solved: store.bigTop.signSolved,
                                  reducedMotion: store.prefersReducedMotion)
                    .frame(width: 38 * scale, height: 15 * scale)
                    .rotationEffect(.degrees(5))
                    .position(x: 281 * scale, y: 28 * scale)
            }
            if store.room == .noodle && store.sceneView == 1 {
                BigTopCounterArtwork(store: store).frame(width: 320 * scale, height: 160 * scale)
            }
            if store.room == .noodle && store.sceneView == 0 {
                if store.bigTop.orderSolved {
                    Image("bt-dinner").resizable().interpolation(.high).scaledToFit()
                        .frame(width: BigTopTableLayout.dinner.width * scale, height: BigTopTableLayout.dinner.height * scale)
                        .position(x: BigTopTableLayout.dinner.midX * scale, y: BigTopTableLayout.dinner.midY * scale)
                }
            }
            if store.room == .noodle && store.sceneView == 0 && store.bigTop.menuPlaced {
                DinnerMenuArtwork()
                    .frame(width: 9 * scale, height: 13 * scale)
                    .position(x: 218 * scale, y: 60 * scale)
            }
            if store.room == .perfume && store.sceneView == 4 {
                PerfumeBenchCabinet(opened: store.perfumery.opened.contains("lab"))
                    .frame(width: 320 * scale, height: 160 * scale)
            }
            if store.room == .perfume && [2, 3, 4].contains(store.sceneView) {
                let cabinet = store.sceneView == 2 ? "wood" : store.sceneView == 3 ? "botanical" : "lab"
                if store.perfumery.opened.contains(cabinet) {
                    IngredientShelfObjects(store: store, cabinet: cabinet, closeup: false)
                        .frame(width: 320 * scale, height: 160 * scale)
                }
            }
            if store.room == .perfume && store.sceneView == 1 {
                ForEach(0..<3) { slot in
                    if let bottle = store.perfumery.arrangement[slot] {
                        SeatedPerfumeArtwork(tool: bottle)
                            .frame(width: 10 * scale, height: 16 * scale)
                            .position(x: PerfumePlacement.worldBoxCenters[slot] * scale, y: 112 * scale)
                    }
                }
            }
            if store.room == .perfume && store.sceneView == 1 {
                PerfumeWorldBoxFront().frame(width: 320 * scale, height: 160 * scale)
            }
            if store.room == .perfume && store.sceneView == 4 {
                ForEach(0..<3) { slot in
                    if let tool = store.perfumery.mixture[slot] {
                        PerfumeBenchObject(tool: tool, slot: slot)
                            .frame(width: 320 * scale, height: 160 * scale)
                    }
                }
                PerfumeTrayFronts().frame(width: 320 * scale, height: 160 * scale)
                if let tool = store.perfumery.output {
                    FragranceBottleArtwork(tool: tool, showLabel: false)
                        .frame(width: PerfumePlacement.output.width * scale, height: PerfumePlacement.output.height * scale)
                        .position(x: PerfumePlacement.output.midX * scale, y: PerfumePlacement.output.midY * scale)
                }
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Authored bt2-room tabletop (320×160): back edge y≈95, front edge y≈115.
/// Keep the whole visible silhouette within this inset, not merely its centre.
enum BigTopTableLayout {
    static let surface = CGRect(x: 112, y: 96, width: 98, height: 18)
    static let dinner = CGRect(x: 145, y: 96, width: 34, height: 18)
}
