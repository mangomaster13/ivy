import SwiftUI

/// Authored booth canvas: 320 × 160. The ticket rests on the right-hand table.
enum CinemaLayout {
    static let ticket = CGRect(x: 268, y: 124, width: 24, height: 12)
    static let spots: [ExplorationSpot] = [
        .init("Film case on the shelf", 137, 26, 39, 16, .memory(.cinemaCase)),
        .init("Projector", 83, 29, 78, 90, .memory(.cinemaProjector)),
        .init("Projection screen", 251, 14, 64, 82, .memory(.cinema)),
        .init("Ticket stub", ticket.minX, ticket.minY, ticket.width, ticket.height, .memory(.cinemaTicket))
    ]
    static let diagram = CGRect(x: 178, y: 35, width: 300, height: 200)
    static func seatCenter(_ seat: Int) -> CGPoint {
        CGPoint(x: diagram.minX + diagram.width * ((384 + CGFloat(seat % 5) * 208) / 1536),
                y: diagram.minY + diagram.height * ((274 + CGFloat(seat / 5) * 209) / 1024))
    }
}

struct CinemaWorld: View {
    @Bindable var store: GameStore
    let scale: CGFloat
    var body: some View {
        ZStack(alignment: .topLeading) {
            CinemaProjection(progress: store.cinema)
                .frame(width: 64 * scale, height: 32 * scale)
                .position(x: 286 * scale, y: 58 * scale)
            Image("later-cinema-ticket-clue").resizable().scaledToFit()
                .frame(width: CinemaLayout.ticket.width * scale, height: CinemaLayout.ticket.height * scale)
                .position(x: CinemaLayout.ticket.midX * scale, y: CinemaLayout.ticket.midY * scale)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// All three layers partition the same source ink; there is no pre-solve heart asset.
struct CinemaInkLayer: View {
    let index: Int
    var body: some View {
        Image("cinema-three-ink").resizable().interpolation(.high)
            .mask {
                Canvas { context, size in
                    var cells = Path()
                    for row in 0..<8 {
                        for column in 0..<12 where (column * 7 + row * 11 + column * row % 5) % 3 == index {
                            cells.addRect(CGRect(x: CGFloat(column) * size.width / 12,
                                                 y: CGFloat(row) * size.height / 8,
                                                 width: size.width / 12, height: size.height / 8))
                        }
                    }
                    context.fill(cells, with: .color(.white))
                }
            }
    }
}

struct CinemaFilmArtwork: View {
    let index: Int
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("cinema-film-blank").resizable().interpolation(.high)
                CinemaInkLayer(index: index)
                    .aspectRatio(1.5, contentMode: .fit)
                    .frame(width: geometry.size.width * 0.84, height: geometry.size.height * 0.62)
            }
        }.aspectRatio(2, contentMode: .fit)
    }
}

struct CinemaFilmStack: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<3) { index in
                    CinemaFilmArtwork(index: index)
                        .frame(width: geometry.size.width * 0.82)
                        .rotationEffect(.degrees(Double(index - 1) * 5))
                        .offset(x: CGFloat(index - 1) * geometry.size.width * 0.04,
                                y: CGFloat(index - 1) * geometry.size.height * 0.10)
                }
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }.aspectRatio(1.7, contentMode: .fit)
    }
}

struct CinemaProjection: View {
    let progress: CinemaProgress
    var body: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width / 591
            let scaleY = geometry.size.height / 296
            let rect = CinemaLayout.diagram
            if progress.filmInserted {
                ZStack(alignment: .topLeading) {
                    ForEach(0..<3) { index in
                        let layer = progress.layers[index]
                        CinemaInkLayer(index: index)
                            .frame(width: rect.width * scaleX, height: rect.height * scaleY)
                            .scaleEffect(x: layer.flipped ? -1 : 1, y: 1)
                            .position(x: (rect.midX + layer.x) * scaleX,
                                      y: (rect.midY + layer.y) * scaleY)
                    }
                    if progress.projectionReady {
                        let left = CinemaLayout.seatCenter(12)
                        let right = CinemaLayout.seatCenter(13)
                        Image("cinema-heart-reveal").resizable().scaledToFit()
                            .frame(width: 30 * scaleX, height: 30 * scaleY)
                            .position(x: (left.x + right.x) / 2 * scaleX, y: left.y * scaleY)
                    }
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct CinemaCloseupView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel
    @State private var dragOrigin: CGPoint?
    @State private var choosingSeats = false
    @State private var seatRow: Int?

    var body: some View {
        ZStack {
            switch panel {
            case .cinemaCase: filmCase
            case .cinemaTicket:
                InspectionBackdrop(surface: .scene("later-cinema-projector-background"))
                Image("later-cinema-ticket-clue").resizable().scaledToFit().padding(32)
                    .accessibilityLabel(store.clueText(.cinemaTicket))
            case .cinemaProjector: projector
            default: screen
            }
        }
        .gameBackAction {
            if seatRow != nil { seatRow = nil }
            else if choosingSeats { choosingSeats = false }
            else { store.backFromMemory() }
        }
        .onDisappear { dragOrigin = nil; store.persistNow() }
    }

    private var filmCase: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let opened = store.cinema.caseOpened
                let image = opened ? (store.cinema.filmTaken ? "later-cinema-film-case-empty" : "cinema-three-case-full")
                    : "later-cinema-projection-booth-background"
                Image(image).resizable().scaledToFit().accessibilityHidden(true)
                let rect = opened ? CGRect(x: 92, y: 62, width: 163, height: 44)
                    : CGRect(x: 137, y: 26, width: 39, height: 16)
                objectTarget(rect, in: geometry.size, label: opened ? "Take the three transparent films" : "Open the film case") {
                    if opened { store.takeCinemaFilm() } else { store.openCinemaCase() }
                }.disabled(opened && store.cinema.filmTaken)
            }
        }
    }

    private var projector: some View {
        ZStack {
            FittedSceneStage {
                GeometryReader { geometry in
                    Image("later-cinema-projector-background").resizable().scaledToFit()
                    let slot = CGRect(x: 142, y: 60, width: 18, height: 46)
                    if store.cinema.filmInserted {
                        CinemaFilmStack()
                            .rotationEffect(.degrees(90))
                            .frame(width: 43 * geometry.size.width / 320, height: 18 * geometry.size.height / 160)
                            .position(x: slot.midX * geometry.size.width / 320, y: slot.midY * geometry.size.height / 160)
                            .allowsHitTesting(false)
                    }
                    objectTarget(slot, in: geometry.size, label: store.cinema.filmInserted ? "Remove the three films from projector" : "Insert selected films") {
                        if store.cinema.filmInserted { store.removeCinemaFilm() }
                        else { store.insertCinemaFilm() }
                    }
                    .inventoryToolDrop(store: store, accepting: store.cinema.filmInserted ? [] : [.cinemaFilm]) { _ in
                        store.insertCinemaFilm()
                    }
                }
            }
            if store.cinema.filmInserted {
                PuzzleActionRail {
                    PuzzleButton("Screen", width: PuzzleActionLayout.width) { store.openMemory(.cinema) }
                }
            }
        }
    }

    private var screen: some View {
        GeometryReader { geometry in
            let mainWidth = max(1, geometry.size.width - PuzzleActionLayout.width - PuzzleActionLayout.inset - PuzzleActionLayout.spacing)
            // Inspect the full screen, then a physical row: five 48 pt seat targets
            // require 240 pt of interaction width (364 pt including rail and margins).
            let area = CGRect(x: 8, y: 8, width: mainWidth - 16, height: geometry.size.height - 48)
            let active = store.cinema.layers[store.cinema.selectedFilm]
            let source = screenBounds
            let zoom = seatRow == nil ? min(area.width / source.width, area.height / source.height)
                : area.width / source.width
            let origin = CGPoint(x: area.midX - source.midX * zoom, y: area.midY - source.midY * zoom)
            ZStack(alignment: .topLeading) {
                InspectionBackdrop(surface: .scene("later-cinema-screen-background"))
                ZStack(alignment: .topLeading) {
                    Image("later-cinema-screen-background").resizable()
                        .frame(width: 591 * zoom, height: 296 * zoom)
                    CinemaProjection(progress: store.cinema)
                        .frame(width: 591 * zoom, height: 296 * zoom)
                    ForEach(store.cinema.projectionReady ? store.cinema.seats.sorted() : [], id: \.self) { seat in
                        let point = CinemaLayout.seatCenter(seat)
                        Ellipse().stroke(IvyType.cream, lineWidth: 2)
                            .frame(width: 26 * zoom, height: 29 * zoom)
                            .position(x: point.x * zoom, y: point.y * zoom)
                            .allowsHitTesting(false)
                    }
                }
                .offset(x: origin.x - area.minX, y: origin.y - area.minY)
                .frame(width: area.width, height: area.height, alignment: .topLeading)
                .clipped() // Physical screen camera; controls remain outside this crop.
                .position(x: area.midX, y: area.midY)

                if choosingSeats {
                    seatTargets(area: area, zoom: zoom, origin: origin)
                } else {
                    Color.clear.contentShape(Rectangle())
                        .frame(width: area.width, height: area.height)
                        .gesture(DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                if dragOrigin == nil { dragOrigin = CGPoint(x: active.x, y: active.y) }
                                guard let start = dragOrigin else { return }
                                store.moveCinemaFilm(x: start.x + value.translation.width / zoom,
                                                     y: start.y + value.translation.height / zoom)
                            }
                            .onEnded { _ in dragOrigin = nil; store.persistNow() })
                        .position(x: area.midX, y: area.midY)
                        .accessibilityElement().accessibilityLabel("Projected film " + String(store.cinema.selectedFilm + 1))
                        .accessibilityValue(store.cinema.projectionReady ? "Complete seating plan; a heart joins C3 and C4" : "Horizontal offset \(Int(active.x)), vertical offset \(Int(active.y)); \(active.flipped ? "back" : "front") facing")
                        .accessibilityAction(named: "Move left") { store.moveCinemaFilm(x: active.x - 2, y: active.y) }
                        .accessibilityAction(named: "Move right") { store.moveCinemaFilm(x: active.x + 2, y: active.y) }
                        .accessibilityAction(named: "Move up") { store.moveCinemaFilm(x: active.x, y: active.y - 2) }
                        .accessibilityAction(named: "Move down") { store.moveCinemaFilm(x: active.x, y: active.y + 2) }
                }
                PuzzleActionRail {
                    if store.cinema.solved {
                        PuzzleButton("Remember", width: PuzzleActionLayout.width) { store.replayKeepsake(.cinema) }
                    } else if choosingSeats {
                        PuzzleButton("Film", width: PuzzleActionLayout.width) { choosingSeats = false; seatRow = nil }
                        PuzzleButton("Enter", width: PuzzleActionLayout.width, action: store.submitCinemaSeats)
                    } else if store.cinema.projectionReady {
                        PuzzleButton("Seats", width: PuzzleActionLayout.width) { choosingSeats = true }
                            .disabled(!store.cinema.filmInserted)
                    } else {
                        PuzzleButton("Film " + ["A", "B", "C"][store.cinema.selectedFilm], width: PuzzleActionLayout.width) {
                            dragOrigin = nil
                            store.selectCinemaFilm((store.cinema.selectedFilm + 1) % 3)
                        }.disabled(!store.cinema.filmInserted)
                            .accessibilityHint("Choose the next film layer")
                        PuzzleButton("Flip", width: PuzzleActionLayout.width) {
                            dragOrigin = nil
                            store.flipCinemaFilm()
                        }.disabled(!store.cinema.filmInserted)
                        PuzzleButton("Project", width: PuzzleActionLayout.width, action: store.submitCinemaProjection)
                            .disabled(!store.cinema.filmInserted)
                    }
                }
                VStack { Spacer(minLength: 0); SceneFeedback(store: store, height: 32) }
                    .allowsHitTesting(false)
                    .frame(width: mainWidth, height: geometry.size.height)
            }
        }
    }

    private var screenBounds: CGRect {
        if let row = seatRow {
            let first = CinemaLayout.seatCenter(row * 5)
            return CGRect(x: first.x - 20.3125, y: first.y - 20.41015625, width: 203.125, height: 40.8203125)
        }
        return CinemaLayout.diagram.insetBy(dx: -4, dy: -4)
    }

    @ViewBuilder private func seatTargets(area: CGRect, zoom: CGFloat, origin: CGPoint) -> some View {
        if let row = seatRow {
            ForEach(0..<5) { column in
                let seat = row * 5 + column
                Button { store.selectCinemaSeat(seat) } label: {
                    Color.clear.contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .frame(width: area.width / 5, height: 64)
                    .position(x: area.minX + area.width * (CGFloat(column) + 0.5) / 5, y: area.midY)
                    .accessibilityLabel("Seat \(String(UnicodeScalar(65 + row)!))\(column + 1)")
                    .accessibilityAddTraits(store.cinema.seats.contains(seat) ? [.isSelected] : [])
            }
        } else {
            Color.clear.contentShape(Rectangle())
                .frame(width: area.width, height: area.height)
                .gesture(SpatialTapGesture().onEnded { value in
                    let y = (value.location.y + area.minY - origin.y) / zoom
                    seatRow = min(3, max(0, Int(((y - CinemaLayout.seatCenter(0).y) / 40.8203125).rounded())))
                })
                .position(x: area.midX, y: area.midY)
                .accessibilityElement().accessibilityLabel("Inspect a projected row")
                .accessibilityAction(named: "Row A") { seatRow = 0 }
                .accessibilityAction(named: "Row B") { seatRow = 1 }
                .accessibilityAction(named: "Row C") { seatRow = 2 }
                .accessibilityAction(named: "Row D") { seatRow = 3 }
        }
    }

    private func objectTarget(_ rect: CGRect, in size: CGSize, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Color.clear.contentShape(Rectangle()) }
            .buttonStyle(.plain)
            .frame(width: max(48, rect.width * size.width / 320), height: max(48, rect.height * size.height / 160))
            .position(x: rect.midX * size.width / 320, y: rect.midY * size.height / 160)
            .accessibilityLabel(label)
    }
}
