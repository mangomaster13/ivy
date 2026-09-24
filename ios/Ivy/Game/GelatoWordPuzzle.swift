import SwiftUI

/// Optional on MemoryProgress so every earlier save remains decodable.
struct GelatoWordProgress: Codable {
    static let words = ["MINT", "EGG", "RAIN", "STEAM", "JAR", "TANGERINE", "NUTS"]
    static let answer = [4, 2, 6, 3, 0, 5, 1]
    static let markedLetters = ["I", "E", "A", "M", "J", "N", "S"]
    var order: [Int] = []
    var chainSolved = false
    var flavorDraft = ""
    var flavorSolved = false

    static func normalized(_ value: String) -> String {
        String(value.lowercased().filter { "abcdefghijklmnopqrstuvwxyz".contains($0) }.prefix(24))
    }

    mutating func sanitize() {
        var seen = Set<Int>()
        order = order.filter { Self.words.indices.contains($0) && seen.insert($0).inserted }
        flavorDraft = Self.normalized(flavorDraft)
        if flavorSolved { chainSolved = true }
        if chainSolved { order = Self.answer }
    }
}

extension GameStore {
    var gelatoWords: GelatoWordProgress {
        get { memories.gelatoWords ?? GelatoWordProgress() }
        set { memories.gelatoWords = newValue }
    }

    private var canChangeGelatoWords: Bool {
        room == .gelato && overlay == .memory(.menu) && !isIntro &&
            !isHallTransitioning && collectingEgg == nil && !collected.contains(.gelato)
    }

    func selectGelatoWord(_ index: Int) {
        guard canChangeGelatoWords, !gelatoWords.chainSolved,
              GelatoWordProgress.words.indices.contains(index) else { return }
        if let position = gelatoWords.order.firstIndex(of: index) {
            gelatoWords.order = Array(gelatoWords.order.prefix(position))
        } else {
            gelatoWords.order.append(index)
        }
        dismissSceneHint(); persistNow()
    }

    func submitGelatoChain() {
        guard canChangeGelatoWords, !gelatoWords.chainSolved else { return }
        guard gelatoWords.order.count == GelatoWordProgress.words.count else { return }
        guard gelatoWords.order == GelatoWordProgress.answer else {
            showWrongAnswer()
            return
        }
        gelatoWords.chainSolved = true
        dismissSceneHint(); IvyHaptics.success(); persistNow()
    }

    func setGelatoFlavorDraft(_ value: String) {
        guard canChangeGelatoWords, gelatoWords.chainSolved, !gelatoWords.flavorSolved else { return }
        gelatoWords.flavorDraft = GelatoWordProgress.normalized(value)
        dismissSceneHint(); persistNow()
    }

    func submitGelatoFlavor() {
        guard canChangeGelatoWords, gelatoWords.chainSolved, !gelatoWords.flavorSolved else { return }
        guard GelatoWordProgress.normalized(gelatoWords.flavorDraft) == "jasmine" else {
            showWrongAnswer()
            return
        }
        gelatoWords.flavorSolved = true
        memories.flavor = 2
        dismissSceneHint(); IvyHaptics.success(); persistNow()
    }

    func migrateGelatoWords() {
        if memories.gelatoWords == nil {
            var progress = GelatoWordProgress()
            // Old solved menus retain tasting access. A completed water puzzle retains
            // the equivalent first stage, but never grants a missing collectible.
            progress.flavorSolved = memories.menuSolved || collected.contains(.gelato)
            progress.chainSolved = progress.flavorSolved || gelatoWater.tagRevealed
            progress.sanitize()
            gelatoWords = progress
        }
        if collected.contains(.gelato) {
            gelatoWords.flavorSolved = true
            gelatoWords.chainSolved = true
        }
        gelatoWords.sanitize()
    }
}

/// One placement table owns the approved 1774 × 887 menu and its hit regions.
enum GelatoWordArtwork {
    static let centers: [CGPoint] = [
        .init(x: 0.23, y: 0.365), .init(x: 0.43, y: 0.365), .init(x: 0.63, y: 0.365),
        .init(x: 0.31, y: 0.55), .init(x: 0.58, y: 0.55),
        .init(x: 0.30, y: 0.74), .init(x: 0.635, y: 0.74)
    ]
    static let widths: [CGFloat] = [0.18, 0.14, 0.16, 0.22, 0.14, 0.38, 0.16]
    // On the service view's vertical timber backing, clear of the lamps and cabinet.
    static let orderRect = CGRect(x: 50, y: 38, width: 31, height: 20)
}

struct GelatoWordMenuView: View {
    @Bindable var store: GameStore
    @FocusState private var enteringFlavor: Bool

    private var imageName: String {
        store.gelatoWords.chainSolved ? "gelato-words-marked" : "gelato-words-unmarked"
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let actionPoint = PuzzleActionLayout.center(in: geometry.size)
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    InspectionBackdrop(surface: .scene(imageName))
                    if !enteringFlavor {
                        ForEach(GelatoWordProgress.words.indices, id: \.self) { index in
                            word(index, width: width, height: height)
                        }
                    }
                }
                .frame(width: width, height: height)
                if !enteringFlavor {
                    PuzzleActionRail {
                        if !store.gelatoWords.chainSolved {
                            PuzzleButton("Enter", width: PuzzleActionLayout.width, action: store.submitGelatoChain)
                                .disabled(store.gelatoWords.order.count != 7)
                        }
                    }
                    SceneFeedback(store: store, height: 30)
                        .frame(width: geometry.size.width - 24, height: 30)
                        .position(x: geometry.size.width / 2, y: geometry.size.height - 15)
                }
                // Keep the same TextField identity while keyboard focus changes layout.
                if store.gelatoWords.chainSolved && !store.gelatoWords.flavorSolved {
                    flavorInput
                        .frame(width: enteringFlavor ? min(300, geometry.size.width - 32) : 92)
                        .position(enteringFlavor ? CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2) : actionPoint)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .gameBackAction(store.backFromMemory)
        .preference(key: GameTextInputFocusKey.self, value: enteringFlavor)
    }

    private func word(_ index: Int, width: CGFloat, height: CGFloat) -> some View {
        let point = GelatoWordArtwork.centers[index]
        let position = store.gelatoWords.order.firstIndex(of: index)
        // Word hit regions keep 48 pt targets on the complete scene.
        // Ordinals describe selection only; no per-word validity is rendered.
        return Button { store.selectGelatoWord(index) } label: {
            Color.clear
                .frame(width: max(48, width * GelatoWordArtwork.widths[index]), height: 48)
                .contentShape(Rectangle())
                .overlay(alignment: .topLeading) {
                    if let position {
                        Text(String(position + 1))
                            .font(IvyType.hand(16)).foregroundStyle(IvyType.ink)
                            .padding(.horizontal, 3)
                            .background(IvyType.cream.opacity(0.95), in: Circle())
                            .offset(y: -9)
                    }
                }
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!store.gelatoWords.chainSolved)
        .accessibilityLabel(GelatoWordProgress.words[index])
        .accessibilityValue((position.map { "Position \($0 + 1). " } ?? "Not selected. ") +
            (store.gelatoWords.chainSolved ? "Leaf under " + GelatoWordProgress.markedLetters[index] : ""))
        .position(x: point.x * width, y: point.y * height)
    }

    // Same native input styling as the current shared keyboard work, kept local
    // so this feature's checkpoint does not commit other scenes' unfinished conversion.
    private var flavorInput: some View {
        TextField("", text: Binding(get: { store.gelatoWords.flavorDraft },
                                    set: store.setGelatoFlavorDraft), prompt: Text("…"))
            .textFieldStyle(.plain)
            .font(IvyType.script(18)).foregroundStyle(IvyType.cream)
            .multilineTextAlignment(.center)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            .keyboardType(.asciiCapable).submitLabel(.done)
            .focused($enteringFlavor)
            .onSubmit { enteringFlavor = false; store.submitGelatoFlavor() }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background {
                GeometryReader { geometry in
                    Image("ivy-input-v2").resizable().interpolation(.high)
                        .frame(width: geometry.size.width * 228 / 220, height: 76)
                        .position(x: geometry.size.width / 2, y: 26)
                }
            }
            .accessibilityLabel("Flavour")
    }
}

struct GelatoClueView: View {
    let store: GameStore
    let panel: MemoryPanel
    var body: some View {
        GeometryReader { geometry in
            if panel == .gelatoNote {
                // The paper lies between y=0.17 and 0.83. A 2:1 camera removes
                // only the outer timber above/below it, keeping the entire note.
                Image("gelato-word-note").resizable().interpolation(.high).scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else {
                ZStack {
                    // Bare counter, left of the saucer; the order is a transparent paper sprite.
                    SceneDetailStage(bounds: CGRect(x: 70, y: 110, width: 64, height: 32)) {
                        InspectionBackdrop(surface: .scene(store.gelatoServingImageName))
                    }
                    Image("gelato-word-order").resizable().interpolation(.high).scaledToFit()
                        .padding(16)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(store.clueText(panel == .gelatoNote ? .gelatoLeaves : .gelatoOrder))
        .gameBackAction(store.backFromMemory)
    }
}

/// Notes records the inscription on the paper, never a miniature scene screenshot.
struct GelatoPaperExcerpt: View {
    let image: String
    let sourceSize: CGSize
    let bounds: CGRect
    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / bounds.width
            Image(image).resizable().interpolation(.high)
                .frame(width: sourceSize.width * scale, height: sourceSize.height * scale)
                .offset(x: -bounds.minX * scale, y: -bounds.minY * scale)
        }
        .aspectRatio(bounds.width / bounds.height, contentMode: .fit)
        .clipped()
    }
}

/// Trace the approved order paper's silhouette to exclude its presentation backdrop.
struct GelatoOrderPaper: View {
    var body: some View {
        Image("gelato-word-order").resizable().interpolation(.high)
            .mask {
                GeometryReader { geometry in
                    Path { path in
                        let points: [CGPoint] = [
                            .init(x: 0.071, y: 0.17), .init(x: 0.34, y: 0.181),
                            .init(x: 0.68, y: 0.18), .init(x: 0.938, y: 0.181),
                            .init(x: 0.955, y: 0.21), .init(x: 0.971, y: 0.792),
                            .init(x: 0.95, y: 0.822), .init(x: 0.90, y: 0.81),
                            .init(x: 0.75, y: 0.826), .init(x: 0.60, y: 0.817),
                            .init(x: 0.46, y: 0.819), .init(x: 0.32, y: 0.813),
                            .init(x: 0.19, y: 0.816), .init(x: 0.11, y: 0.80),
                            .init(x: 0.04, y: 0.781), .init(x: 0.065, y: 0.20)
                        ]
                        path.addLines(points.map { CGPoint(x: $0.x * geometry.size.width, y: $0.y * geometry.size.height) })
                        path.closeSubpath()
                    }
                }
            }
    }
}
