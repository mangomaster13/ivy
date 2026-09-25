import SwiftUI

/// Measured from the selected 1774×887 source plates; all transforms share this canvas.
enum FerrisLayout {
    static let cabinet = CGRect(x: 77, y: 23, width: 183, height: 98)
    static let ticket = CGRect(x: 148, y: 147, width: 23, height: 10)
    static let gate = CGRect(x: 132, y: 94, width: 18, height: 20)
    static let door = CGRect(x: 226, y: 43, width: 35, height: 77)
    static let postboxSlot = CGRect(x: 122, y: 91, width: 20, height: 10)
    static let exitCarriage = CGRect(x: 210, y: 38, width: 52, height: 73)
    static let cardOnSeat = CGRect(x: 252, y: 122, width: 27, height: 18)
    static let cabinPress = CGRect(x: 23, y: 98, width: 51, height: 28)
    static let pressPaper = CGRect(x: 89, y: 91, width: 135, height: 27)
    static let barCenters: [CGFloat] = [96, 120, 144, 166, 188, 211, 233]
    static let drumCenters: [CGFloat] = [111, 157, 204]
    static let promenadeSpots: [ExplorationSpot] = [
        .init("Glockenspiel and sheet music", 78, 23, 184, 101, .memory(.ferris)),
        .init("Ticket slot", 145, 142, 34, 18, .memory(.ferrisTicket))
    ]
    static let boardingSpots: [ExplorationSpot] = [
        .init("Board the wheel", 226, 43, 35, 77, .memory(.ferrisGate)),
        .init("Ticket reader", 132, 94, 18, 20, .memory(.ferrisGate))
    ]
    static let boothSpots: [ExplorationSpot] = [
        .init("Postbox", 122, 85, 24, 27, .memory(.ferrisPostbox)),
        .init("Open carriage", 210, 38, 52, 73, .memory(.ferrisGate))
    ]
}

struct FerrisWorld: View {
    @Bindable var store: GameStore
    let scale: CGFloat
    var body: some View {
        ZStack(alignment: .topLeading) {
            if store.sceneView == 0 {
                FerrisStaff(notes: FerrisProgress.melody, slots: 9)
                    .frame(width: 116 * scale, height: 20 * scale)
                    .position(x: 158 * scale, y: 37 * scale)
                if store.ferris.musicSolved && !store.ferris.ticketTaken {
                    Image("ferris-ride-ticket").resizable().scaledToFit()
                        .frame(width: FerrisLayout.ticket.width * scale, height: FerrisLayout.ticket.height * scale)
                        .position(x: FerrisLayout.ticket.midX * scale, y: FerrisLayout.ticket.midY * scale)
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
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
            case .ferrisCabin: cabin
            case .ferrisCamera: press
            case .ferrisPostbox: postbox
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
        SceneDetailStage(bounds: CGRect(x: 78, y: 22, width: 200, height: 100)) {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image("ferris-music-cabinet").resizable().accessibilityHidden(true)
                FerrisStaff(notes: FerrisProgress.melody, slots: 9)
                    .frame(width: 116 * scale, height: 20 * scale)
                    .position(x: 158 * scale, y: 37 * scale)
                FerrisStaff(notes: store.ferris.notes, slots: 9)
                    .frame(width: 116 * scale, height: 20 * scale)
                    .position(x: 158 * scale, y: 55 * scale)
                    .accessibilityLabel("Recorded phrase: " + (store.ferris.notes.isEmpty ? "empty" : store.ferris.notes.map { FerrisProgress.noteNames[$0] }.joined(separator: "; ")))
                if let note = store.ferris.lastNote {
                    FerrisStaff(notes: [note], slots: 1)
                        .frame(width: 28 * scale, height: 9 * scale)
                        .position(x: 155 * scale, y: 73 * scale)
                }
                Image(store.ferris.recording ? "ferris-record-on" : "ferris-record-off")
                    .resizable().scaledToFit().frame(width: 24 * scale, height: 9 * scale)
                    .position(x: 199 * scale, y: 73 * scale).accessibilityHidden(true)
                if !store.ferris.musicSolved {
                    ForEach(0..<7, id: \.self) { note in
                        target(CGRect(x: FerrisLayout.barCenters[note] - 8, y: 87, width: 16, height: 30),
                               scale: scale, label: "Strike bar \(note + 1)") { store.strikeFerrisNote(note) }
                    }
                    target(CGRect(x: 229, y: 65, width: 12, height: 16), scale: scale,
                           label: store.ferris.recording ? "Stop recording, keep phrase" : "Record notes") { store.toggleFerrisRecording() }
                    target(CGRect(x: 254, y: 53, width: 17, height: 37), scale: scale,
                           label: "Pull handle to play the entire phrase", action: store.submitFerrisMusic)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if !store.ferris.musicSolved {
                PuzzleButton("Undo", width: 72, action: store.undoFerrisNote)
                    .disabled(store.ferris.notes.isEmpty).padding(8)
            }
        }
    }

    private var ticket: some View {
        SceneDetailStage(bounds: CGRect(x: 136, y: 136, width: 48, height: 24)) {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image("ferris-music-cabinet").resizable().accessibilityHidden(true)
                FerrisWorld(store: store, scale: scale)
                if !store.ferris.ticketTaken {
                    target(FerrisLayout.ticket, scale: scale, label: "Take the ride ticket", action: store.takeFerrisTicket)
                }
            }
        }
    }

    private var gate: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image(store.ferris.ticketUsed ? "ferris-boarding-open" : "ferris-boarding-closed")
                    .resizable().accessibilityHidden(true)
                if store.ferris.ticketUsed {
                    target(FerrisLayout.door, scale: scale, label: "Enter the carriage", action: store.enterFerrisCabin)
                } else {
                    target(FerrisLayout.gate, scale: scale, label: "Use ticket in reader", accepting: [.ferrisTicket], action: store.useFerrisTicket)
                }
            }
        }
    }

    private var cabin: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image(store.ferrisCabinImage).resizable()
                    .accessibilityLabel([
                        "Low view. The near warehouse roof fills the window; buildings behind it are hidden.",
                        "Middle view. A clock tower rises behind the warehouse. Its stone face blocks the view farther back.",
                        "High view. Beyond the warehouse and clock tower, a domed observatory is visible on the wooded hill."
                    ][store.ferris.height])
                if !store.ferris.postcardPlaced || store.ferris.cardRetrieved {
                    Image("ferris-cabin-empty-bed").resizable()
                        .frame(width: 220.0 / 1774 * 320 * scale, height: 75.0 / 887 * 160 * scale)
                        .position(x: 293.0 / 1774 * 320 * scale, y: 657.5 / 887 * 160 * scale)
                        .accessibilityHidden(true)
                }
                if !store.ferris.postcardTaken {
                    Image("ferris-postcard").resizable().scaledToFit()
                        .frame(width: 27 * scale, height: 18 * scale)
                        .rotation3DEffect(.degrees(48), axis: (x: 1, y: 0, z: 0))
                        .rotationEffect(.degrees(-5))
                        .position(x: FerrisLayout.cardOnSeat.midX * scale, y: FerrisLayout.cardOnSeat.midY * scale)
                        .accessibilityHidden(true)
                    target(FerrisLayout.cardOnSeat, scale: scale, label: "Take the postcard", action: store.takeFerrisPostcard)
                }
                target(FerrisLayout.cabinPress, scale: scale, label: "Postcard press", accepting: [.ferrisPostcard], action: store.placeFerrisPostcard)
                target(CGRect(x: 302, y: 84, width: 18, height: 28), scale: scale,
                       label: "Return to the platform") { store.openMemory(.ferrisPostbox) }
            }
        }
        .preference(key: GamePageNavigationKey.self, value: GamePageNavigation(
            canGoPrevious: store.ferris.height > 0, canGoNext: store.ferris.height < 2,
            previous: { store.changeFerrisHeight(-1) }, next: { store.changeFerrisHeight(1) }
        ))
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

    private var postbox: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image("ferris-postbox").resizable().accessibilityHidden(true)
                target(FerrisLayout.postboxSlot, scale: scale,
                       label: store.ferris.posted ? "Remember the posted card" : "Post the stamped postcard",
                       accepting: [.ferrisPostcard], action: store.postFerrisPostcard)
                target(CGRect(x: 278, y: 125, width: 40, height: 30), scale: scale,
                       label: "Walk to the taxi queue", action: store.leaveFerrisPlatform)
                target(FerrisLayout.exitCarriage, scale: scale, label: "Return to the carriage") {
                    store.openMemory(.ferrisCabin)
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
