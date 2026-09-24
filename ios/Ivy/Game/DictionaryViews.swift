import SwiftUI

/// Slots are anchored to the painted counter (320 × 160), including sprite alpha margins.
enum DictionaryLayout {
    static let book = CGRect(x: 128, y: 91, width: 82, height: 41)
    static let song = CGRect(x: 79, y: 95, width: 51, height: 34)
    static let pen = CGRect(x: 213, y: 87, width: 29, height: 20)
    // Inside the right page, clear of the spine, page edges and the pen tray.
    static let writing = CGRect(x: 0.49, y: 0.29, width: 0.31, height: 0.30)

    static func spots(penAvailable: Bool) -> [ExplorationSpot] {
        var slots: [(String, CGRect, ExplorationAction)] = [
            ("Dictionary", book, .memory(.dictionary)),
            ("Song card", song, .memory(.dictionarySong))
        ]
        if penAvailable { slots.append(("Fountain pen on its stand", pen, .dictionaryPen)) }
        return slots.map { ExplorationSpot($0.0, $0.1.minX, $0.1.minY, $0.1.width, $0.1.height, $0.2) }
    }
}

struct DictionaryWorld: View {
    @Bindable var store: GameStore
    let scale: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            object("later-dictionary-closed-book", rect: DictionaryLayout.book)
            object("later-dictionary-song-card", rect: DictionaryLayout.song)
            if !store.memories.picked.contains(.fountainPen) || store.dictionary.solved {
                object("later-dictionary-fountain-pen", rect: DictionaryLayout.pen)
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }

    private func object(_ name: String, rect: CGRect) -> some View {
        Image(name).resizable().interpolation(.high).scaledToFit()
            .frame(width: rect.width * scale, height: rect.height * scale)
            .position(x: rect.midX * scale, y: rect.midY * scale)
    }
}

struct DictionaryCloseupView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel
    @State private var writingCloseup = false
    @State private var drawingStroke = false
    @State private var submitting = false
    @State private var submission: Task<Void, Never>?

    var body: some View {
        Group {
            if panel == .dictionarySong {
                Image("later-dictionary-song-card").resizable().interpolation(.high).scaledToFit()
                    .padding(16)
                    .accessibilityLabel(store.clueText(.dictionaryLyric))
            } else {
                // 48 pt controls + 32 pt feedback remain outside the fitted book. No second footer budget.
                VStack(spacing: 4) {
                    book
                    HStack(spacing: 16) {
                        if store.dictionary.solved {
                            PuzzleButton("Remember") { store.replayKeepsake(.dictionary) }
                        } else if !writingCloseup {
                            PuzzleButton("Write", action: openWritingSurface)
                        } else {
                            PuzzleButton("Undo", action: store.undoDictionaryStroke)
                                .disabled(!store.canWriteDictionary || store.dictionary.strokes.isEmpty || submitting)
                            PuzzleButton("Enter") {
                                submitting = true
                                submission = Task { @MainActor in
                                    await store.submitDictionary()
                                    submitting = false
                                }
                            }.disabled(!store.canWriteDictionary || store.dictionary.strokes.isEmpty || submitting)
                        }
                    }.frame(height: 48)
                    SceneFeedback(store: store, height: 32).frame(height: 32)
                }
            }
        }
        .gameBackAction {
            if writingCloseup {
                writingCloseup = false
                drawingStroke = false
                submission?.cancel()
                submitting = false
                store.persistNow()
            } else { store.backFromMemory() }
        }
        .onDisappear {
            drawingStroke = false
            submission?.cancel()
            submission = nil
            submitting = false
            store.persistNow()
        }
        .onChange(of: store.selectedTool) { _, _ in drawingStroke = false }
    }

    private func openWritingSurface() {
        guard store.dictionary.solved || store.requireInteractionTool(.fountainPen, missing: "The page is waiting for ink.") else { return }
        writingCloseup = true
    }

    private var book: some View {
        // This is a camera crop, not a resized writing surface: artwork and saved ink use one transform.
        let crop = writingCloseup ? CGRect(x: 0.47, y: 0.24, width: 0.36, height: 0.40)
                                 : CGRect(x: 0, y: 0, width: 1, height: 1)
        return FittedSceneStage(aspectRatio: (16.0 / 9.0) * crop.width / crop.height) {
            GeometryReader { geometry in
                let size = CGSize(width: geometry.size.width / crop.width, height: geometry.size.height / crop.height)
                let rect = DictionaryLayout.writing
                ZStack(alignment: .topLeading) {
                    Image("later-dictionary-open-book-background").resizable().interpolation(.high)
                        .frame(width: size.width, height: size.height).accessibilityHidden(true)
                    Image("later-dictionary-page-entries-overlay").resizable().interpolation(.high)
                        .frame(width: size.width, height: size.height)
                        .allowsHitTesting(false)
                        .accessibilityLabel(store.clueText(.dictionaryEntries))
                        .accessibilityHidden(writingCloseup)
                    if !store.memories.picked.contains(.fountainPen) || store.dictionary.solved {
                        Image("later-dictionary-fountain-pen").resizable().scaledToFit()
                            .frame(width: size.width * 0.13, height: size.width * 0.13 / 1.5)
                            .rotationEffect(.degrees(45))
                            .position(x: size.width * 0.917, y: size.height * 0.63)
                            .allowsHitTesting(false).accessibilityHidden(true)
                    }
                    ink
                        .frame(width: size.width * rect.width, height: size.height * rect.height)
                        .allowsHitTesting(writingCloseup)
                        .position(x: size.width * rect.midX, y: size.height * rect.midY)
                    if !writingCloseup {
                        Button(action: openWritingSurface) {
                            Color.clear.contentShape(Rectangle())
                        }.buttonStyle(.plain)
                            .frame(width: max(48, size.width * rect.width), height: max(48, size.height * rect.height))
                            .position(x: size.width * rect.midX, y: size.height * rect.midY)
                            .accessibilityLabel("Look closer at the dictionary entry")
                    }
                }
                .frame(width: size.width, height: size.height, alignment: .topLeading)
                .offset(x: -crop.minX * size.width, y: -crop.minY * size.height)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .clipped()
            }
        }
    }

    private var ink: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for stroke in store.dictionary.strokes {
                    guard let first = stroke.first else { continue }
                    var path = Path()
                    path.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
                    for point in stroke.dropFirst() {
                        path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
                    }
                    context.stroke(path, with: .color(IvyType.ink),
                                   style: StrokeStyle(lineWidth: max(1, size.width * 0.007), lineCap: .round, lineJoin: .round))
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !submitting, store.canWriteDictionary else { return }
                    let size = geometry.size
                    guard size.width > 0, size.height > 0,
                          CGRect(origin: .zero, size: size).contains(value.location) else {
                        drawingStroke = false
                        return
                    }
                    store.addDictionaryPoint(DictionaryInkPoint(x: value.location.x / size.width,
                                                                y: value.location.y / size.height),
                                             startingStroke: !drawingStroke)
                    drawingStroke = true
                }
                .onEnded { _ in
                    drawingStroke = false
                    store.persistNow()
                    if !store.dictionary.solved && !store.canWriteDictionary {
                        store.showSceneHint("The page is waiting for ink.", presentation: .interaction)
                    }
                })
            .inventoryToolDrop(store: store, accepting: store.dictionary.solved ? [] : [.fountainPen])
            .accessibilityElement()
            .accessibilityLabel(store.dictionary.solved ? "Your handwritten dictionary entry" : "Blank dictionary entry")
            .accessibilityHint("Write the missing word on the right page. Undo removes the last stroke.")
            .accessibilityAddTraits(.allowsDirectInteraction)
        }
    }
}
