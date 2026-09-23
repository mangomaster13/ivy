import SwiftUI

struct RoseProgress: Codable {
    var revealed: Set<Int> = []
    var found: Set<Int> = []
    var placed: Set<Int> = []

    mutating func sanitize() {
        found = found.intersection(0..<3)
        revealed = revealed.intersection(0..<3).union(found)
        placed = placed.intersection(found)
    }
}

extension GameStore {
    var roseProgress: RoseProgress { memories.rose ?? RoseProgress() }
    var rosePetals: Set<Int> { collected.contains(.rose) ? Set(0..<3) : roseProgress.placed }

    func toggleBedroomLamp() {
        guard canExplore, room == .bedroom, sceneView == 1 else { return }
        memories.bedroomLampOn = !(memories.bedroomLampOn ?? false)
        if memories.bedroomLampOn == true, !roseProgress.revealed.contains(1) { revealRosePetal(1) }
        else { persistNow() }
    }

    func migrateRose() {
        if memories.rose == nil {
            var progress = RoseProgress()
            // Credit old wrapping work and the old box reward, without replaying them.
            progress.placed = memories.folds.intersection(0..<2).union(exploration.stitches.intersection(0..<3))
            progress.found = progress.placed
            if petalHeld { progress.found.insert(0) }
            if exploration.tools.contains(.sewingKit) || memories.picked.contains(.sewingKit) {
                progress.found.insert(2)
            }
            if collected.contains(.rose) {
                progress.found = Set(0..<3)
                progress.placed = progress.found
            }
            memories.rose = progress
        }
        memories.rose?.sanitize()
        petalHeld = false
        // Retain the legacy save identifier, but never show the retired twine tool.
        exploration.tools.remove(.sewingKit)
        memories.picked.insert(.sewingKit)
        memories.used.insert(.sewingKit)
        if selectedTool == .sewingKit { selectedTool = nil }
    }

    func revealRosePetal(_ index: Int) {
        guard room == .bedroom, collectingEgg == nil, !isHallTransitioning,
              (index == 0 && overlay == .memory(.blanket)) ||
              (index == 1 && canExplore && sceneView == 1) else { return }
        guard !collected.contains(.rose), !roseProgress.found.contains(index) else {
            showSceneHint(index == 0 ? "A little warmth, caught in the folds." : "A small pool of gold.", presentation: .interaction)
            return
        }
        var progress = roseProgress
        progress.revealed.insert(index)
        withAnimation(prefersReducedMotion ? nil : .easeOut(duration: 0.25)) { memories.rose = progress }
        IvyHaptics.light()
        persistNow()
    }

    func takeRosePetal(_ index: Int) {
        guard room == .bedroom, collectingEgg == nil, !collected.contains(.rose),
              (0..<3).contains(index), !roseProgress.found.contains(index) else { return }
        if index == 2 {
            guard overlay == .memory(.wholeBox), memories.opened.contains("wholeBox") else { return }
        } else if index == 0 {
            guard overlay == .memory(.blanket), roseProgress.revealed.contains(0) else { return }
        } else {
            guard canExplore, sceneView == 1, roseProgress.revealed.contains(1) else { return }
        }
        var progress = roseProgress
        progress.found.insert(index)
        toolsVisible = true
        progress.revealed.insert(index)
        withAnimation(prefersReducedMotion ? nil : .easeOut(duration: 0.2)) { memories.rose = progress }
        IvyHaptics.light()
        showSceneHint("A little piece of something we kept.", presentation: .interaction)
        persistNow()
    }

    func placeRosePetal(_ index: Int) {
        guard room == .bedroom, overlay == .memory(.bouquet), collectingEgg == nil,
              !collected.contains(.rose), roseProgress.found.contains(index),
              !roseProgress.placed.contains(index) else { return }
        var progress = roseProgress
        progress.placed.insert(index)
        memories.rose = progress
        if progress.placed.count == 3 {
            unlockAssemblyKeepsake(.rose)
            IvyHaptics.success()
        } else { IvyHaptics.light() }
        persistNow()
    }
}

struct RoseWorldPetals: View {
    @Bindable var store: GameStore
    let scale: CGFloat
    var body: some View {
        if store.room == .bedroom, store.sceneView == 1, store.memories.bedroomLampOn == true,
           !store.collected.contains(.rose) {
            let index = 1
            if store.roseProgress.revealed.contains(index), !store.roseProgress.found.contains(index) {
                Button { store.takeRosePetal(index) } label: {
                    RosePetalArtwork(index: index)
                        .frame(width: 11 * scale, height: 10 * scale)
                        .rotationEffect(.degrees(24))
                        .frame(width: max(48, 17 * scale), height: max(48, 17 * scale))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: 115 * scale, y: 82 * scale)
                .accessibilityLabel("Red rose petal")
            }
        }
    }
}

/// Global target geometry lets a footer drag cross the content boundary without clipping.
struct RoseDropFrameKey: PreferenceKey {
    static let defaultValue: CGRect = .null
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        // Siblings without a flower must not erase its measured drop region.
        if !next.isNull && !next.isEmpty { value = next }
    }
}

struct RosePetalTool: View {
    @Bindable var store: GameStore
    let index: Int
    @State private var showsName = false
    @State private var nameFlash = 0
    private var available: Bool {
        store.roseProgress.found.contains(index) && !store.rosePetals.contains(index)
    }
    var body: some View {
        RosePetalArtwork(index: index)
        .frame(width: 30, height: 30)
        .opacity(store.draggedRosePetal == index ? 0 : 1)
        .frame(width: 64, height: 48)
        .opacity(available ? 1 : 0)
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(IvyType.cream.opacity(0.15)))
        .contentShape(Rectangle())
        .onTapGesture { flashName() }
        .highPriorityGesture(DragGesture(minimumDistance: 4, coordinateSpace: .named("rose-drag"))
            .onChanged { value in
                guard available, store.collectingEgg == nil else { return }
                if !showsName { flashName() }
                store.draggedRosePetal = index
                store.roseDragLocation = value.location
            }
            .onEnded { value in
                guard store.draggedRosePetal == index else { return }
                if store.roseDropFrame.contains(value.location) { store.placeRosePetal(index) }
                store.draggedRosePetal = nil
            })
        .overlay(alignment: .top) {
            if showsName {
                Text("Red rose petal").font(IvyType.hand(13)).fixedSize()
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Red rose petal \(index + 1)")
        .accessibilityHidden(!available)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Place on bouquet") { store.placeRosePetal(index) }
    }

    private func flashName() { showsName = true; nameFlash += 1 }
}

struct RoseAssemblyView: View {
    @Bindable var store: GameStore
    @State private var reveal: CGFloat = 0
    private var complete: Bool { store.rosePetals.count == 3 }

    var body: some View {
        ElementMemoryComposition(store: store, image: "rose-bouquet", title: EggId.rose.memoryTitle,
                                 line: EggId.rose.memoryLine, progress: reveal, assembly: true,
                                 petals: store.rosePetals)
            .background {
                GeometryReader { geometry in
                    let height = min(330, geometry.size.height * 0.96)
                    let width = height * RoseArtwork.aspect
                    let frame = geometry.frame(in: .named("rose-drag"))
                    Color.clear.preference(key: RoseDropFrameKey.self, value: complete ? .null : CGRect(
                        x: frame.midX - width / 2 - 20, y: frame.midY - height / 2 - 16,
                        width: width + 40, height: height * 0.62 + 32))
                }
            }
            .task(id: complete) {
                guard complete else { reveal = 0; return }
                store.roseDropFrame = .null
                do { try await Task.sleep(for: .milliseconds(180)) } catch { return }
                withAnimation(.easeInOut(duration: store.prefersReducedMotion ? 0.12 : 0.55)) { reveal = 1 }
            }
            .onDisappear { store.draggedRosePetal = nil; store.roseDropFrame = .null }
    }
}

/// Full-stage fabric artwork, with the collectible on its own native interaction layer.
struct BlanketCloseupView: View {
    @Bindable var store: GameStore
    @GestureState private var pull: CGFloat = 0
    private var opened: Bool {
        store.roseProgress.revealed.contains(0) || store.roseProgress.found.contains(0) ||
            store.collected.contains(.rose)
    }
    private var petalAvailable: Bool {
        !store.roseProgress.found.contains(0) && !store.collected.contains(.rose)
    }

    var body: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let size = geometry.size
                let reveal: CGFloat = opened ? 1 : pull
                ZStack {
                    Image("memory-blanket-open").resizable().interpolation(.high)
                        .frame(width: size.width, height: size.height)
                        .accessibilityHidden(true)
                    if petalAvailable {
                        Button { store.takeRosePetal(0) } label: {
                            RosePetalArtwork(index: 0)
                                .frame(width: size.width * 0.105, height: size.height * 0.16)
                                .rotationEffect(.degrees(12))
                                .shadow(color: .black.opacity(0.3), radius: 2, y: 3)
                                .frame(minWidth: 48, minHeight: 48)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .position(x: size.width * 0.52, y: size.height * 0.49)
                        .opacity(reveal)
                        .allowsHitTesting(opened)
                        .accessibilityLabel("Red rose petal in the blanket")
                        .accessibilityHidden(!opened)
                    }
                    Image("memory-blanket-closed").resizable().interpolation(.high)
                        .frame(width: size.width, height: size.height)
                        .opacity(1 - reveal)
                        .allowsHitTesting(false).accessibilityHidden(true)
                    if !opened {
                        Color.clear
                            .frame(width: size.width * 0.56, height: max(48, size.height * 0.38))
                            .contentShape(Rectangle())
                            .onTapGesture { store.revealRosePetal(0) }
                            .gesture(DragGesture(minimumDistance: 6)
                                .updating($pull) { value, progress, _ in
                                    progress = min(1, max(0, -value.translation.height / max(1, size.height * 0.22)))
                                }
                                .onEnded { value in
                                    if -value.translation.height >= size.height * 0.12 {
                                        store.revealRosePetal(0)
                                    }
                                })
                            .position(x: size.width * 0.52, y: size.height * 0.42)
                            .accessibilityLabel("Blanket fold")
                            .accessibilityAddTraits(.isButton)
                            .accessibilityAction { store.revealRosePetal(0) }
                    }
                    VStack {
                        Spacer(minLength: 0)
                        SceneFeedback(store: store).padding(.horizontal, 24).padding(.bottom, 12)
                    }
                    if !store.sceneHint.isEmpty && store.sceneHintPresentation == .interaction {
                        Color.clear.contentShape(Rectangle())
                            .onTapGesture { store.dismissSceneHint() }
                            .accessibilityLabel("Dismiss memory")
                            .accessibilityAddTraits(.isButton)
                            .accessibilityAction(.escape) { store.dismissSceneHint() }
                    }
                }
                .frame(width: size.width, height: size.height)
            }
        }
        .gameBackAction(store.backFromMemory)
    }
}
