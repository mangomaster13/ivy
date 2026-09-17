import SwiftUI

/// Root scene: night letterboxes around the 320×160 yard (and hall after the lyric lock).
struct ContentView: View {
    /// Persistent gift state for this device.
    @State private var store = GameStore()
    /// Used to hide the bar and freeze idle nudges when the app is backgrounded.
    @Environment(\.scenePhase) private var scenePhase
    /// Strip walk/shake when Reduce Motion is on.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color("Night")
                .ignoresSafeArea()
            PixelCanvas(
                imageName: store.room.imageName,
                offsetX: reduceMotion ? 0 : store.worldOffsetX,
                dim: store.worldDim
            ) { scale in
                roomHotspots(scale: scale)
            }
            if case .dialogue(let line) = store.overlay {
                VStack {
                    Spacer()
                    DialogueBox(line: line, onDismiss: { store.dismissDialogue() })
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            if store.isEntering {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Keep the keyboard; blank taps must not dismiss input.
                    }
            }
        }
        .statusBarHidden(true)
        .safeAreaInset(edge: .bottom, spacing: 4) {
            if store.isEntering {
                InputChallengeView(store: store)
            } else {
                InventoryBar(store: store)
            }
        }
        .onAppear {
            store.prefersReducedMotion = reduceMotion
        }
        .onChange(of: reduceMotion) { _, value in
            store.prefersReducedMotion = value
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                store.persistNow()
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(120))
            store.considerDoorNudge()
        }
    }

    /// Hotspots share the canvas scale so a 1px edge lines up with the art.
    @ViewBuilder
    private func roomHotspots(scale: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            if store.room == .yard {
                YardAtmosphere(
                    vineStage: store.yardVineStage,
                    swayFrame: store.ivySwayFrame,
                    cloudOffset: store.cloudOffset,
                    scale: scale
                )
            }
            missLayer(scale: scale)
            switch store.room {
            case .yard:
                HotspotButton(
                    rect: RoomHotspots.yardIvy,
                    scale: scale,
                    label: "Ivy on the wall"
                ) {
                    guard !store.isEntering else { return }
                    store.tapYardIvy()
                }
                HotspotButton(
                    rect: RoomHotspots.yardIvyRight,
                    scale: scale,
                    label: "Ivy on the far wall"
                ) {
                    guard !store.isEntering else { return }
                    store.tapYardIvy()
                }
                HotspotButton(
                    rect: RoomHotspots.yardMailbox,
                    scale: scale,
                    label: "Mailbox"
                ) {
                    guard !store.isEntering else { return }
                    store.tapYardMailbox()
                }
                HotspotButton(
                    rect: RoomHotspots.yardDoor,
                    scale: scale,
                    glow: store.doorGlow,
                    label: "Front door"
                ) {
                    guard !store.isEntering else { return }
                    store.tapYardDoor()
                }
            case .hall:
                HotspotButton(
                    rect: RoomHotspots.hallExit,
                    scale: scale,
                    label: "Door to the yard"
                ) {
                    guard !store.isEntering else { return }
                    store.tapHallExit()
                }
            }
        }
        .allowsHitTesting(!store.isEntering)
    }

    /// Taps that miss furniture still get a spoken line.
    private func missLayer(scale: CGFloat) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { event in
                    guard !store.isEntering else { return }
                    if case .dialogue = store.overlay {
                        store.dismissDialogue()
                        return
                    }
                    let point = CGPoint(x: event.location.x / scale, y: event.location.y / scale)
                    switch store.room {
                    case .yard:
                        store.tapYardMiss(gamePoint: point)
                    case .hall:
                        store.tapHallRest()
                    }
                }
            )
            .accessibilityHidden(true)
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
