import SwiftUI

/// A single composition is shared by the bed, closeup and celebration.
struct PlushRose: View {
    let complete: Bool
    var body: some View {
        RoseFlower(petals: complete ? Set(0..<3) : [])
    }
}

struct WonderlandAtmosphere: View {
    @Bindable var store: GameStore
    let scale: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: reduceMotion || phase != .active)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .topLeading) {
                if store.room == .corridor {
                    HStack(spacing: 1.3 * scale) {
                        ForEach(0..<4) { i in
                            Text(String(store.corridorDigits[i])).font(IvyType.hand(4.7 * scale)).foregroundStyle(IvyType.ink)
                        }
                    }.position(x: 206.5 * scale, y: 60 * scale)
                    if store.corridorUnlocked && !store.collected.contains(.keycard) {
                        MemoryObjectArtwork(image: "sheraton-keycard")
                            .frame(width: 7 * scale, height: 10 * scale)
                            .rotationEffect(.degrees(-65))
                            .position(x: 219.5 * scale, y: 81.5 * scale)
                    }
                }
                if store.room == .bedroom {
                    Image("rose-lying").resizable().interpolation(.high).scaledToFit()
                        .frame(width: WonderlandLayout.rose.width * scale,
                               height: WonderlandLayout.rose.height * scale)
                        .shadow(color: .black.opacity(0.3), radius: 0.8 * scale, x: 0, y: 1.2 * scale)
                        .position(x: WonderlandLayout.rose.midX * scale, y: WonderlandLayout.rose.midY * scale)
                }
                if store.room == .bedroom || store.room == .corridor {
                    Canvas { context, _ in
                        for i in 0..<12 {
                            let x = Double(126 + (i * 11) % 36)
                            let y = Double(72 + (i * 7) % 11)
                            let opacity = reduceMotion ? 0.18 : 0.10 + (sin(t * 0.8 + Double(i)) + 1) * 0.08
                            context.fill(Path(CGRect(x: x * scale, y: y * scale, width: 2 * scale, height: 0.5 * scale)), with: .color(IvyType.cream.opacity(opacity)))
                        }
                    }.frame(width: 320 * scale, height: 160 * scale)
                }
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Shared material, margins and dismissal affordance for close-ups.
enum InspectionSurface {
    case puzzle
    case scene(String)
    case defocusedScene(String)

    var imageName: String {
        switch self {
        case .puzzle: "story-lock-panel"
        case .scene(let name), .defocusedScene(let name): name
        }
    }
}

/// Complete artwork stays inside content; only the root paints beyond safe areas.
struct InspectionBackdrop: View {
    let surface: InspectionSurface
    var focusProgress: CGFloat = 1
    private var isDefocused: Bool {
        if case .defocusedScene = surface { return true }
        return false
    }

    var body: some View {
        GeometryReader { geometry in
            Image(surface.imageName).resizable().interpolation(.high).scaledToFit()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .blur(radius: isDefocused ? geometry.size.width * 0.012 * focusProgress : 0)
                .overlay { if isDefocused { Color.black.opacity(0.14 * Double(focusProgress)) } }
                .clipped()
        }
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}

/// Physical closeups share one fitted coordinate space for art and interactions.
/// Empty space belongs to the game's Night background, not a decorative frame.
struct FittedSceneStage<Content: View>: View {
    var aspectRatio: CGFloat = 2
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { geometry in
            let width = min(geometry.size.width, geometry.size.height * aspectRatio)
            content
                .frame(width: width, height: width / aspectRatio)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

/// A camera crop of a physical scene, with artwork and hit targets transformed together.
/// Bounds use the existing 320 × 160 scene coordinates; Back stays in the root gutter.
struct SceneDetailStage<Content: View>: View {
    let bounds: CGRect
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { geometry in
            // Widen the camera, not the artwork. Keep the requested detail visible
            // while the surrounding scene fills the root-owned viewport.
            let camera = SceneDetailCamera.rect(containing: bounds, viewport: geometry.size)
            let scale = geometry.size.width / camera.width
            content
                .frame(width: 320 * scale, height: 160 * scale)
                .offset(x: -camera.minX * scale, y: -camera.minY * scale)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .clipped()
        }
    }
}

enum SceneDetailCamera {
    static func rect(containing bounds: CGRect, viewport: CGSize) -> CGRect {
        guard viewport.width > 0, viewport.height > 0 else { return bounds }
        let aspect = viewport.width / max(1, viewport.height)
        let width = max(bounds.width, bounds.height * aspect)
        let height = width / aspect
        return CGRect(x: min(max(0, bounds.midX - width / 2), 320 - width),
                      y: min(max(0, bounds.midY - height / 2), 160 - height),
                      width: width, height: height)
    }
}

struct KeepsakeSheet<Content: View>: View {
    let back: () -> Void
    let surface: InspectionSurface
    var focusProgress: CGFloat = 1
    @ViewBuilder let content: Content

    var body: some View {
        switch surface {
        case .puzzle:
            FittedSceneStage { sheet }
        case .scene(let image), .defocusedScene(let image):
            let size = SceneArtwork.image(named: image).size
            FittedSceneStage(aspectRatio: max(1, size.width) / max(1, size.height)) {
                sheet
            }
        }
    }

    private var sheet: some View {
        ZStack {
            Color("Night")
            InspectionBackdrop(surface: surface, focusProgress: focusProgress)
            content.frame(maxWidth: 1000, maxHeight: .infinity)
                .padding(.horizontal, 24).padding(.vertical, 12)
        }
        .gameBackAction(back)
    }
}

/// Native hand-cut controls shared by pads and scene navigation.
struct PuzzleButton: View {
    let title: String
    let width: CGFloat?
    let action: () -> Void
    init(_ title: String, width: CGFloat? = nil, action: @escaping () -> Void) {
        self.title = title
        self.width = width
        self.action = action
    }
    var body: some View {
        Button(action: action) {
            Text(title).font(IvyType.hand(21)).foregroundStyle(IvyType.ink)
                .lineLimit(1).minimumScaleFactor(0.72)
                .padding(.horizontal, 10).frame(minWidth: 48, minHeight: 48)
                .frame(width: width)
                .background(HandcutKey().fill(IvyType.cream))
                .overlay(HandcutKey().stroke(IvyType.ink.opacity(0.65), lineWidth: 1))
        }.buttonStyle(StoryPressStyle(scale: 1))
    }
}

struct HotelLockView: View {
    @Bindable var store: GameStore
    private let brass = Color(red: 0.62, green: 0.49, blue: 0.29)
    private let darkBrass = Color(red: 0.29, green: 0.27, blue: 0.18)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("Night")
                InspectionBackdrop(surface: .puzzle)

                VStack(spacing: 0) {
                    HStack(spacing: 32) {
                        VStack(spacing: 18) {
                            ornament
                            IvyType.inscription("a room we\nstill remember")
                                .font(IvyType.script(28))
                                .foregroundStyle(IvyType.cream)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            ornament
                        }
                        .frame(width: 176)

                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                ForEach(0..<4) { index in
                                    wheel(index)
                                }
                            }
                            .padding(8)
                            .background {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(brass)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(IvyType.ink, lineWidth: 2)
                                    }
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(IvyType.cream.opacity(0.35), lineWidth: 1)
                                            .padding(4)
                                    }
                                    .shadow(color: IvyType.ink.opacity(0.55), radius: 0, x: 0, y: 3)
                            }
                            PuzzleButton("enter", width: 112, action: store.submitHotelCode)
                        }
                        .frame(width: 264)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    SceneFeedback(store: store, height: 32)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

            }
        }
        .gameBackAction(store.cancelOverlay)
    }

    private var ornament: some View {
        HStack(spacing: 8) {
            Rectangle().frame(width: 32, height: 1)
            Rectangle().frame(width: 5, height: 5).rotationEffect(.degrees(45))
            Rectangle().frame(width: 32, height: 1)
        }
        .foregroundStyle(brass)
        .accessibilityHidden(true)
    }

    private func wheel(_ index: Int) -> some View {
        VStack(spacing: 0) {
            wheelArrow(index, delta: 1)
            Text(String(store.corridorDigits[index]))
                .font(IvyType.hand(36))
                .foregroundStyle(IvyType.ink)
                .frame(width: 56, height: 48)
                .background {
                    Rectangle().fill(IvyType.cream)
                        .overlay(alignment: .top) {
                            Rectangle().fill(darkBrass.opacity(0.25)).frame(height: 3)
                        }
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(.white.opacity(0.35)).frame(height: 2)
                        }
                }
                .overlay(alignment: .leading) {
                    VStack(spacing: 5) {
                        ForEach(0..<3) { _ in
                            Rectangle().fill(darkBrass.opacity(0.45)).frame(width: 3, height: 1)
                        }
                    }.padding(.leading, 3)
                }
                .contentTransition(.numericText())
                .gesture(DragGesture(minimumDistance: 12).onEnded { value in
                    store.turnHotelWheel(index, by: value.translation.height < 0 ? 1 : -1)
                })
            wheelArrow(index, delta: -1)
        }
        .background(RoundedRectangle(cornerRadius: 7).fill(darkBrass))
        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(IvyType.ink.opacity(0.8), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Digit \(index + 1)")
        .accessibilityValue(String(store.corridorDigits[index]))
        .accessibilityAdjustableAction { direction in
            store.turnHotelWheel(index, by: direction == .increment ? 1 : -1)
        }
    }

    private func wheelArrow(_ index: Int, delta: Int) -> some View {
        Button { store.turnHotelWheel(index, by: delta) } label: {
            Image(systemName: delta > 0 ? "chevron.up" : "chevron.down")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(IvyType.cream)
                .frame(width: 56, height: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(StoryPressStyle(scale: 1))
        .accessibilityLabel("\(delta > 0 ? "Increase" : "Decrease") digit \(index + 1)")
    }
}

// Legacy overlay and debug-review entry share the current puzzle.
struct RoseKeepsakeView: View {
    @Bindable var store: GameStore
    var body: some View {
        MemoryCloseupView(store: store, panel: .bouquet)
            .onAppear { store.overlay = .memory(.bouquet) }
    }
}

struct ObservationView: View {
    @Bindable var store: GameStore
    let egg: EggId
    var body: some View {
        ElementMemoryView(store: store, image: egg.memoryImage, title: egg.memoryTitle,
                          line: egg.memoryLine, back: store.cancelOverlay)
    }
}

/// Legacy overlay entry points open the same four-flavour tasting scene.
struct GelatoKeepsakeView: View {
    @Bindable var store: GameStore
    var body: some View {
        GelatoCloseupView(store: store, panel: .tasting)
            .onAppear { store.openMemory(.tasting) }
    }
}

/// Semantic navigation uses separate silhouettes rather than interchangeable chevrons.
struct SceneNavigationButton: View {
    enum Kind {
        case back
        case scene(previous: Bool)
        case page(previous: Bool)
    }

    let kind: Kind
    let label: String
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            NavigationArtwork(kind: kind)
                .frame(width: 48, height: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(StoryPressStyle(scale: 1))
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(label)
    }
}

/// Exact sprites extracted from the approved ivory storybook navigation board.
private struct NavigationArtwork: View {
    let kind: SceneNavigationButton.Kind

    private var imageName: String {
        switch kind {
        case .back: "ui-storybook-back"
        case .page: "ui-storybook-page"
        case .scene: "ui-storybook-scene"
        }
    }

    private var artworkSize: CGSize {
        switch kind {
        case .back: CGSize(width: 24, height: 16)
        case .page: CGSize(width: 12, height: 20)
        case .scene: CGSize(width: 16, height: 20)
        }
    }

    private var isPrevious: Bool {
        switch kind {
        case .back: false
        case .page(let previous), .scene(let previous): previous
        }
    }

    var body: some View {
        Image(imageName)
            .renderingMode(.original)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: artworkSize.width, height: artworkSize.height)
            .scaleEffect(x: isPrevious ? -1 : 1, y: 1)
            .accessibilityHidden(true)
    }
}
