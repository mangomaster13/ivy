import SwiftUI

/// Measured from the selected 1774×887 source plates; all transforms share this canvas.
enum FerrisLayout {
    static let ticket = CGRect(x: 72, y: 97, width: 8, height: 5)
    static let ticketCloseup = CGRect(x: 122, y: 62, width: 76, height: 71)
    static let gate = CGRect(x: 171, y: 89, width: 15, height: 32)
    static let door = CGRect(x: 247, y: 66, width: 24, height: 45)
    // Forecourt: postbox on pavement, open carriage at left, taxi on the road below the curb.
    static let postboxSlot = CGRect(x: 95, y: 94, width: 11, height: 5)
    static let exitCarriage = CGRect(x: 18, y: 53, width: 25, height: 41)
    static let taxi = CGRect(x: 194, y: 71, width: 121, height: 62)
    static let cabinPress = CGRect(x: 23, y: 98, width: 51, height: 28)
    static let pressPaper = CGRect(x: 89, y: 91, width: 135, height: 27)
    static let barCenters: [CGFloat] = [88, 114, 140, 165, 191, 217, 243]
    static let drumCenters: [CGFloat] = [111, 157, 204]
    // Fragment papers share the approved 320×160 cabinet canvas; staff ink stays inside each sheet.
    static let fragments = [CGRect(x: 110, y: 28, width: 49, height: 13),
                            CGRect(x: 172, y: 28, width: 50, height: 13),
                            CGRect(x: 108, y: 51, width: 51, height: 13),
                            CGRect(x: 173, y: 51, width: 51, height: 13)]
    static let promenadeSpots: [ExplorationSpot] = [
        .init("Ticket window", 34, 60, 73, 43, .memory(.ferris)),
        .init("Ticket reader", gate.minX, gate.minY, gate.width, gate.height, .memory(.ferrisGate)),
        .init("Board the wheel", door.minX, door.minY, door.width, door.height, .ferrisBoard)
    ]
    static let boothSpots: [ExplorationSpot] = [
        .init("Post the postcard", 84, 80, 29, 53, .ferrisPost),
        .init("Open carriage", exitCarriage.minX, exitCarriage.minY, exitCarriage.width, exitCarriage.height, .ferrisBoard),
        .init("Enter the red taxi", taxi.minX, taxi.minY, taxi.width, taxi.height, .ferrisTaxi)
    ]
    static let cabinSpots: [ExplorationSpot] = [
        .init("Postcard press", cabinPress.minX, cabinPress.minY, cabinPress.width, cabinPress.height, .memory(.ferrisCamera)),
        .init("Carriage door", 302, 84, 18, 28, .ferrisExit)
    ]
}

struct FerrisWorld: View {
    @Bindable var store: GameStore
    let scale: CGFloat
    var body: some View {
        ZStack(alignment: .topLeading) {
            if store.sceneView == 0, store.ferris.musicSolved && !store.ferris.ticketTaken {
                Image("ferris-navigation-ticket").resizable().scaledToFit()
                    .frame(width: FerrisLayout.ticket.width * scale, height: FerrisLayout.ticket.height * scale)
                    .position(x: FerrisLayout.ticket.midX * scale, y: FerrisLayout.ticket.midY * scale)
            }
            if store.sceneView == 2 {
                Color.clear.accessibilityElement()
                    .accessibilityLabel([
                        "Low view. The near warehouse roof fills the window; buildings behind it are hidden.",
                        "Middle view. A clock tower rises behind the warehouse, blocking the farther view.",
                        "High view. Beyond the warehouse and clock tower, a domed observatory is visible on the hill."
                    ][store.ferris.height])
                if store.ferris.cardRetrieved {
                    Image("ferris-cabin-empty-bed").resizable()
                        .frame(width: 220.0 / 1774 * 320 * scale, height: 75.0 / 887 * 160 * scale)
                        .position(x: 293.0 / 1774 * 320 * scale, y: 657.5 / 887 * 160 * scale)
                        .accessibilityHidden(true)
                }
            }
        }
        .allowsHitTesting(false)
        .preference(key: GamePageNavigationKey.self, value: store.canExplore && store.sceneView == 2 ? GamePageNavigation(
            canGoPrevious: store.ferris.height > 0, canGoNext: store.ferris.height < 2,
            previous: { store.changeFerrisHeight(-1) }, next: { store.changeFerrisHeight(1) }
        ) : nil)
    }
}

/// The same note geometry is used by target, experimentation and recorded draft.
/// Changing a note never colours or locks a correct prefix.
struct FerrisStaff: View {
    let notes: [Int]
    let slots: Int
    var body: some View {
        Canvas { context, size in
            let ink = GraphicsContext.Shading.color(IvyType.ink)
            for line in 0..<5 {
                let y = size.height * (0.7 - Double(line) * 0.15)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: ink, lineWidth: max(0.6, size.height * 0.013))
            }
            let step = size.width / CGFloat(max(1, slots))
            let width = min(step * 0.44, size.height * 0.17)
            for (index, note) in notes.enumerated() {
                let x = step * (CGFloat(index) + 0.5)
                let y = size.height * (0.7 - Double(note) * 0.075)
                context.fill(Path(ellipseIn: CGRect(x: x - width / 2, y: y - width * 0.34,
                                                    width: width, height: width * 0.68)), with: ink)
                var stem = Path()
                stem.move(to: CGPoint(x: x + width / 2, y: y))
                stem.addLine(to: CGPoint(x: x + width / 2, y: y - size.height * 0.22))
                context.stroke(stem, with: ink, lineWidth: max(0.7, size.height * 0.025))
            }
        }.accessibilityElement(children: .ignore)
            .accessibilityLabel(notes.isEmpty ? "Empty staff" : notes.map { FerrisProgress.noteNames[$0] }.joined(separator: "; "))
    }
}

struct FerrisCloseupView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel

    var body: some View {
        Group {
            switch panel {
            case .ferrisTicket: ticket
            case .ferrisGate: gate
            case .ferrisCamera: press
            case .ferrisScoreGuide: scoreGuide
            default: music
            }
        }
        .overlay {
            if !store.sceneHint.isEmpty {
                ZStack(alignment: .bottom) {
                    Color.clear.contentShape(Rectangle()).onTapGesture { store.dismissSceneHint() }
                        .accessibilityHidden(true)
                    DialogueBox(line: store.sceneHint, tone: store.sceneHintTone, onDismiss: store.dismissSceneHint)
                        .padding(.horizontal, 24).padding(.bottom, 12)
                }
            }
        }
        .gameBackAction(store.backFromMemory)
        .onDisappear { store.persistNow() }
    }

    private var music: some View {
        SceneDetailStage(bounds: CGRect(x: 77, y: 22, width: 210, height: 105)) {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image("ferris-fragment-cabinet").resizable().accessibilityHidden(true)
                ForEach(0..<4, id: \.self) { index in
                    let rect = FerrisLayout.fragments[index]
                    FerrisStaff(notes: FerrisProgress.fragments[index], slots: 3)
                        .frame(width: rect.width * scale, height: rect.height * scale)
                        .position(x: rect.midX * scale, y: rect.midY * scale)
                }
                // Exploration and recording share the physical paper strip; neither compares with the answer.
                FerrisStaff(notes: store.ferris.recording ? store.ferris.notes : store.ferris.lastNote.map { [$0] } ?? [],
                            slots: store.ferris.recording ? 9 : 1)
                    .frame(width: 97 * scale, height: 6 * scale)
                    .position(x: 155 * scale, y: 75.5 * scale)
                    .accessibilityLabel(store.ferris.recording ? "Recorded phrase: " + store.ferris.notes.map { FerrisProgress.noteNames[$0] }.joined(separator: "; ") : store.ferris.lastNote.map { "Played note: " + FerrisProgress.noteNames[$0] } ?? "Empty staff")
                Image(store.ferris.recording ? "ferris-record-on" : "ferris-record-off")
                    .resizable().scaledToFit().frame(width: 18 * scale, height: 6 * scale)
                    .position(x: 214 * scale, y: 75.5 * scale).accessibilityHidden(true)
                Image("ferris-join-plaque").resizable().scaledToFit()
                    .frame(width: 12 * scale, height: 17 * scale)
                    .position(x: 91.5 * scale, y: 51 * scale).accessibilityHidden(true)
                target(CGRect(x: 84, y: 41, width: 16, height: 20), scale: scale,
                       label: "Inspect the musical joining instructions") { store.openMemory(.ferrisScoreGuide) }
                if !store.ferris.musicSolved {
                    ForEach(0..<7, id: \.self) { note in
                        target(CGRect(x: FerrisLayout.barCenters[note] - 8, y: 91, width: 16, height: 29),
                               scale: scale, label: "Strike bar \(note + 1): \(FerrisProgress.noteNames[note])") { store.strikeFerrisNote(note) }
                    }
                    target(CGRect(x: 228, y: 70, width: 15, height: 13), scale: scale,
                           label: store.ferris.recording ? "Stop recording, keep phrase" : "Record notes") { store.toggleFerrisRecording() }
                    target(CGRect(x: 261, y: 69, width: 18, height: 37), scale: scale,
                           label: "Pull handle to play the entire phrase", action: store.submitFerrisMusic)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if !store.ferris.musicSolved && !store.ferris.notes.isEmpty {
                PuzzleButton("Undo", width: 72, action: store.undoFerrisNote)
                    .padding(8)
            }
        }
    }

    private var ticket: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image(store.ferris.musicSolved && !store.ferris.ticketTaken ? "ferris-ticket-ready" : "ferris-ticket-empty")
                    .resizable().accessibilityHidden(true)
                if store.ferris.musicSolved && !store.ferris.ticketTaken {
                    target(FerrisLayout.ticketCloseup, scale: scale, label: "Take the ride ticket", action: store.takeFerrisTicket)
                }
            }
        }
    }

    private var gate: some View {
        SceneDetailStage(bounds: CGRect(x: 160, y: 57, width: 120, height: 67)) {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image("ferris-ticket-booth")
                    .resizable().accessibilityHidden(true)
                if store.ferris.ticketUsed {
                    target(FerrisLayout.door, scale: scale, label: "Enter the carriage", action: store.enterFerrisCabin)
                } else {
                    target(FerrisLayout.gate, scale: scale, label: "Use ticket in reader", accepting: [.ferrisTicket], action: store.useFerrisTicket)
                }
            }
        }
    }

    private var scoreGuide: some View {
        SceneDetailStage(bounds: CGRect(x: 91, y: 23, width: 140, height: 70)) {
            Image("ferris-join-guide").resizable()
                .accessibilityLabel(FerrisProgress.joinRule)
        }
    }

    private var press: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image(store.ferris.cardRetrieved ? "ferris-press-empty" : "ferris-press")
                    .resizable().accessibilityHidden(true)
                ForEach(0..<3, id: \.self) { slot in
                    Image("ferris-stamp-\(store.ferris.stamps[slot])").resizable().scaledToFit()
                        .frame(width: 24 * scale, height: 25 * scale)
                        .position(x: FerrisLayout.drumCenters[slot] * scale, y: 68 * scale)
                        .accessibilityHidden(true)
                    if !store.ferris.stamped {
                        target(CGRect(x: FerrisLayout.drumCenters[slot] - 15, y: 54, width: 30, height: 28),
                               scale: scale, label: "Stamp \(slot + 1): \(FerrisProgress.landmarks[store.ferris.stamps[slot]]). Turn drum") { store.turnFerrisStamp(slot) }
                            .accessibilityAction(named: "Turn backwards") { store.turnFerrisStamp(slot, by: -1) }
                    }
                }
                if !store.ferris.cardRetrieved {
                    Image(store.ferris.stamped ? "ferris-stamped-lettering" : "ferris-near-far-lettering")
                        .resizable().scaledToFit()
                        .frame(width: 116 * scale, height: 21 * scale)
                        .position(x: 157 * scale, y: 105 * scale)
                        .accessibilityLabel(store.ferris.stamped ? "Three impressions, ready to post" : "Near to far")
                    if store.ferris.stamped {
                        target(FerrisLayout.pressPaper, scale: scale, label: "Take the stamped postcard", action: store.retrieveFerrisPostcard)
                    } else {
                        target(CGRect(x: 263, y: 30, width: 24, height: 35), scale: scale,
                               label: "Press all three stamps", action: store.pressFerrisPostcard)
                    }
                }
            }
        }
    }

    private func target(_ rect: CGRect, scale: CGFloat, label: String, accepting: [AdventureTool] = [],
                        action: @escaping () -> Void) -> some View {
        Button(action: action) { Color.clear.contentShape(Rectangle()) }
            .buttonStyle(.plain)
            .frame(width: max(48, rect.width * scale), height: max(48, rect.height * scale))
            .inventoryToolDrop(store: store, accepting: accepting) { _ in action() }
            .position(x: rect.midX * scale, y: rect.midY * scale)
            .accessibilityLabel(label)
    }
}
