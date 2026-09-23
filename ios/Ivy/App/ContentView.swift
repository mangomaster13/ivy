import SwiftUI

/// Root scene: night letterboxes around the 320×160 yard (and hall after the lyric lock).
struct ContentView: View {
    /// Persistent gift state for this device.
    @State private var store = GameStore()
    @Environment(\.displayScale) private var displayScale
    /// Used to hide the bar and freeze idle nudges when the app is backgrounded.
    @Environment(\.scenePhase) private var scenePhase
    /// Strip walk/shake when Reduce Motion is on.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    #if DEBUG
    @State private var showingResetChoices = false
    #endif

    var body: some View {
        ZStack {
            Color("Night")
                .ignoresSafeArea()
            if store.isIntro {
                IntroView { store.dismissIntro() }
            } else {
                GeometryReader { geometry in
                    let contentHeight = max(0, geometry.size.height - GameLayout.footerHeight)
                    let stageSize = GameLayout.stageSize(
                        in: CGSize(width: max(0, geometry.size.width - 2 * GameLayout.navigationGutter),
                                   height: contentHeight),
                        displayScale: displayScale)
                    VStack(spacing: 0) {
                        gameContent
                            .frame(width: stageSize.width, height: stageSize.height)
                            .frame(width: geometry.size.width, height: contentHeight)
                            .overlayPreferenceValue(GameBackActionKey.self) { back in
                                if let back {
                                    VStack {
                                        HStack(spacing: 0) {
                                            SceneNavigationButton(kind: .back, label: "Back",
                                                                  action: back.perform)
                                                .frame(width: GameLayout.navigationGutter)
                                            Spacer(minLength: 0)
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.top, max(12, (contentHeight - stageSize.height) / 2 + 12))
                                }
                            }
                            .overlay {
                                if store.overlay == .none &&
                                    (worldMessage == nil || store.sceneHintPresentation == .interaction) {
                                    ExplorationNavigation(store: store)
                                }
                            }
                            .overlayPreferenceValue(GamePageNavigationKey.self) { navigation in
                                if let navigation {
                                    GamePageNavigationControls(navigation: navigation)
                                }
                            }
                            #if DEBUG
                            .overlay(alignment: .topTrailing) {
                                if ProcessInfo.processInfo.environment["IVY_REVIEW"] == nil {
                                    Button("RESET") { showingResetChoices = true }
                                        .font(IvyType.hand(11))
                                        .foregroundStyle(IvyType.cream.opacity(0.65))
                                        .frame(width: 48, height: 48)
                                        .accessibilityLabel("Choose a keepsake to reset before")
                                        .frame(width: GameLayout.navigationGutter)
                                        .padding(.top, max(12, (contentHeight - stageSize.height) / 2 + 12))
                                }
                            }
                            #endif
                        AdventureTray(store: store)
                            .frame(width: geometry.size.width, height: GameLayout.footerHeight)
                    }
                }
            }
        }
        .allowsHitTesting(store.collectingEgg == nil && store.replayingEgg == nil && !store.isHallTransitioning)
        .statusBarHidden(true)
        #if DEBUG
        .confirmationDialog("Reset before which keepsake?", isPresented: $showingResetChoices) {
            ForEach(EggId.allCases) { egg in
                Button("\(egg.slotIndex + 1). \(egg.rawValue.capitalized)", role: .destructive) {
                    store.reset(before: egg)
                }
            }
        } message: {
            Text("Progress from the selected keepsake onward will be reset.")
        }
        #endif
        .onPreferenceChange(RoseDropFrameKey.self) { store.roseDropFrame = $0 }
        .overlay {
            if let index = store.draggedRosePetal {
                GeometryReader { geometry in
                    let origin = geometry.frame(in: .named("rose-drag")).origin
                    RosePetalArtwork(index: index)
                        .frame(width: 58, height: 58)
                        .position(x: store.roseDragLocation.x - origin.x,
                                  y: store.roseDragLocation.y - origin.y)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
        .coordinateSpace(name: "rose-drag")
        .onChange(of: store.overlay) { _, _ in
            store.draggedRosePetal = nil
            if store.overlay != .memory(.bouquet) { store.roseDropFrame = .null }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.draggedRosePetal = nil }
        }
        .overlayPreferenceValue(EggSlotAnchors.self) { anchors in
            if let egg = store.collectingEgg ?? store.replayingEgg {
                GeometryReader { proxy in
                    let bounds = anchors[egg].map { proxy[$0] }
                    EggCollectionView(
                        egg: egg,
                        target: bounds.map { CGPoint(x: $0.midX, y: $0.midY) }
                            ?? CGPoint(x: proxy.size.width / 2, y: proxy.size.height - GameLayout.footerHeight / 2),
                        stageSize: proxy.size,
                        trayTop: bounds.map { $0.minY - 6 } ?? proxy.size.height - GameLayout.footerHeight,
                        isReplay: store.collectingEgg == nil,
                        onLanded: {
                            if store.collectingEgg == egg { store.finishCollection(egg) }
                            else { store.finishKeepsakeReplay(egg) }
                        }
                    )
                    .id(egg)
                }
            }
        }
        .onAppear {
            store.prefersReducedMotion = reduceMotion
            store.atmosphereActive = scenePhase == .active
        }
        .onChange(of: reduceMotion) { _, value in
            store.prefersReducedMotion = value
        }
        .onChange(of: scenePhase) { _, phase in
            store.atmosphereActive = phase == .active
            if phase != .active {
                store.persistNow()
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(120))
            store.considerDoorNudge()
        }
    }

    /// Every page receives only the content viewport, never the footer's height.
    private var gameContent: some View {
        activePage
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                Color("Night").opacity(store.worldDim)
                    .allowsHitTesting(store.isHallTransitioning)
            }
            .overlay {
                if let line = worldMessage {
                    ZStack(alignment: .bottom) {
                        Color.clear.contentShape(Rectangle())
                            .onTapGesture { dismissWorldMessage() }
                            .accessibilityHidden(true)
                        Group {
                            if store.overlay == .none && store.sceneHintPresentation == .puzzle {
                                PuzzleFeedbackText(text: line, tone: store.sceneHintTone)
                            } else {
                                DialogueBox(line: line, tone: store.overlay == .none ? store.sceneHintTone : .ordinary,
                                            onDismiss: dismissWorldMessage)
                            }
                        }
                        .padding(.horizontal, 24).padding(.bottom, 12)
                    }
                }
            }
    }

    @ViewBuilder
    private var activePage: some View {
        if store.overlay == .lyric {
            LyricLockView(store: store)
        } else if store.overlay == .plaque {
            MailboxLockView(store: store)
        } else if store.overlay == .vuori {
            HallKeepsakeView(store: store)
        } else if store.overlay == .vuoriMemory {
            VuoriMemoryView(store: store)
        } else if store.overlay == .prize {
            HallPrizeView(store: store)
        } else if store.overlay == .hotelLock {
            HotelLockView(store: store)
        } else if store.overlay == .rose {
            RoseKeepsakeView(store: store)
        } else if store.overlay == .gelato {
            GelatoKeepsakeView(store: store)
        } else if case .observation(let egg) = store.overlay {
            ObservationView(store: store, egg: egg)
        } else if case .memory(let panel) = store.overlay {
            MemoryCloseupView(store: store, panel: panel).id(panel)
        } else if case .adventure(let panel) = store.overlay {
            AdventurePanelView(store: store, panel: panel)
        } else if store.overlay == .envelope {
            RulesEnvelopeView(store: store)
        } else {
            playWorld
        }
    }

    private var worldMessage: String? {
        if case .dialogue(let line) = store.overlay { return line }
        return store.overlay == .none && !store.sceneHint.isEmpty ? store.sceneHint : nil
    }

    private func dismissWorldMessage() {
        store.dismissSceneHint()
        store.dismissDialogue()
    }

    /// Yard or hall plate with hotspots and spoken lines.
    private var playWorld: some View {
        ZStack {
            PixelCanvas(
                imageName: store.roomImageName,
                pixelArt: false,
                offsetX: 0,
                dim: 0
            ) { scale in
                roomHotspots(scale: scale)
            }
            .simultaneousGesture(DragGesture(minimumDistance: 45).onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) * 1.5 else { return }
                store.turnView(value.translation.width < 0 ? 1 : -1)
            })
            .onAppear {
                store.startAtmosphere()
            }
        }
    }

    /// Hotspots share the canvas scale so a 1px edge lines up with the art.
    @ViewBuilder
    private func roomHotspots(scale: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            if store.room == .yard, store.sceneView == 0 {
                YardAtmosphere(
                    vineStage: store.yardVineStage,
                    swayFrame: store.ivySwayFrame,
                    cloudOffset: store.cloudOffset,
                    scale: scale
                )
            }
            if store.room == .hall, store.sceneView == 0 {
                HallAtmosphere(store: store, scale: scale)
            }
            if store.sceneView == 0 { WonderlandAtmosphere(store: store, scale: scale) }
            FoodAndFragranceWorld(store: store, scale: scale)
            canvasTapLayer(scale: scale)
            ForEach(store.explorationSpots) { spot in
                HotspotMarker(rect: spot.rect, scale: scale, label: spot.id, action: { store.inspect(spot) })
            }
            ForEach(store.memoryHotspots) { spot in
                HotspotMarker(rect: spot.rect, scale: scale, label: spot.object.label,
                              action: { store.tapMemory(spot.object) })
            }
            RoseWorldPetals(store: store, scale: scale)
            if store.room == .hall, store.sceneView == 0 {
                HotspotMarker(rect: HallLayout.garment, scale: scale, label: "Clothing on the hanger", action: store.tapVuori)
                HotspotMarker(rect: HallLayout.machine, scale: scale,
                              label: store.lotteryReady ? "Open your keepsake prize" : "A sleeping raffle machine", action: store.tapLottery)
            }
            if store.room == .yard, store.sceneView == 0 {
                HotspotMarker(
                    rect: RoomHotspots.yardIvy,
                    scale: scale,
                    label: "Ivy on the wall",
                    action: { store.tapYardIvy() }
                )
                HotspotMarker(
                    rect: RoomHotspots.yardIvyRight,
                    scale: scale,
                    label: "Ivy on the far wall",
                    action: { store.tapYardIvy() }
                )
                HotspotMarker(
                    rect: RoomHotspots.yardMailbox,
                    scale: scale,
                    glow: store.mailboxOpened ? 0 : store.doorGlow,
                    label: "Mailbox",
                    action: { store.tapYardMailbox() }
                )
                HotspotMarker(
                    rect: RoomHotspots.yardDoor,
                    scale: scale,
                    glow: store.mailboxOpened ? store.doorGlow : 0,
                    label: "Front door",
                    action: { store.tapYardDoor() }
                )
            } else if store.sceneView == 0 {
                ForEach(RoomGraph.hotspots(in: store.room)) { spot in
                    HotspotMarker(
                        rect: spot.rect,
                        scale: scale,
                        label: spot.label,
                        action: { store.tapDiegetic(spot.edge) }
                    )
                }
            }
        }
    }

    /// One full-canvas tap; furniture is hit-tested in game space so Buttons cannot swallow the plate.
    private func canvasTapLayer(scale: CGFloat) -> some View {
        Color.clear
            .frame(width: GameCanvas.width * scale, height: GameCanvas.height * scale)
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { event in
                    handleCanvasTap(at: event.location, scale: scale)
                }
            )
            .accessibilityHidden(true)
    }

    /// Door and mailbox win over ivy; everything else is a miss line.
    private func handleCanvasTap(at location: CGPoint, scale: CGFloat) {
        if case .dialogue = store.overlay {
            store.dismissDialogue()
            return
        }
        // The bouquet lies on the pillow: its action wins over the pillow's ambient reply.
        if store.room == .bedroom, store.sceneView == 0,
           RoomHotspots.hitRect(WonderlandLayout.rose, scale: scale).contains(location) {
            store.tapMemory(.rose)
            return
        }
        if let spot = store.explorationSpots.first(where: { RoomHotspots.hitRect($0.rect, scale: scale).contains(location) }) {
            store.inspect(spot)
            return
        }
        if store.sceneView != 0 { store.tapMiss(); return }
        switch store.room {
        case .yard:
            if RoomHotspots.hitRect(RoomHotspots.yardDoor, scale: scale).contains(location) {
                store.tapYardDoor()
            } else if RoomHotspots.hitRect(RoomHotspots.yardMailbox, scale: scale).contains(location) {
                store.tapYardMailbox()
            } else if RoomHotspots.hitRect(RoomHotspots.yardIvy, scale: scale).contains(location)
                || RoomHotspots.hitRect(RoomHotspots.yardIvyRight, scale: scale).contains(location)
            {
                store.tapYardIvy()
            } else {
                let point = CGPoint(x: location.x / scale, y: location.y / scale)
                store.tapYardMiss(gamePoint: point)
            }
        default:
            if store.room == .hall, RoomHotspots.hitRect(HallLayout.garment, scale: scale).contains(location) {
                store.tapVuori()
                return
            }
            if store.room == .hall, RoomHotspots.hitRect(HallLayout.machine, scale: scale).contains(location) {
                store.tapLottery()
                return
            }
            if let spot = store.memoryHotspots.first(where: {
                RoomHotspots.hitRect($0.rect, scale: scale).contains(location)
            }) {
                store.tapMemory(spot.object)
                return
            }
            if let spot = RoomGraph.hotspots(in: store.room).first(where: {
                RoomHotspots.hitRect($0.rect, scale: scale).contains(location)
            }) {
                store.tapDiegetic(spot.edge)
            } else {
                store.tapMiss()
            }
        }
    }
}

extension Animation {
    /// Keeps a short fade when Reduce Motion is on.
    static func ivy(_ animation: Animation, reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.1) : animation
    }
}

#Preview {
    ContentView()
}
