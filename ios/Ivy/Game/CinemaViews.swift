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
    static func seatCenter(_ seat: Int) -> CGPoint {
        CGPoint(x: CGFloat(233 + (seat % 5) * 52), y: CGFloat(82 + (seat / 5) * 37))
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

/// Masks reuse the approved ink, rather than swapping to an answer image at alignment.
/// Labels stay fixed; right chair halves and the right half-heart travel with the film.
struct CinemaProjection: View {
    let progress: CinemaProgress
    var body: some View {
        ZStack {
            Image("later-cinema-screen-base-overlay").resizable()
            Image("later-cinema-screen-aligned-overlay").resizable()
                .mask { projectionMask(moving: false) }
            if progress.filmInserted {
                GeometryReader { geometry in
                    Image("later-cinema-screen-aligned-overlay").resizable()
                        .mask { projectionMask(moving: true) }
                        .scaleEffect(x: progress.flipped ? -1 : 1, y: 1,
                                     anchor: UnitPoint(x: 337.0 / 591, y: 0.5))
                        .offset(x: progress.x / 591 * geometry.size.width,
                                y: progress.y / 296 * geometry.size.height)
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }

    private func projectionMask(moving: Bool) -> some View {
        Canvas { context, size in
            var path = Path()
            if moving {
                for seat in 0..<20 {
                    let point = CinemaLayout.seatCenter(seat)
                    path.addRect(CGRect(x: point.x / 591 * size.width,
                                        y: (point.y - 13) / 296 * size.height,
                                        width: 14 / 591 * size.width, height: 25 / 296 * size.height))
                }
            }
            path.addRect(CGRect(x: (moving ? 363.0 : 342.0) / 591 * size.width,
                                y: 137 / 296 * size.height,
                                width: 21 / 591 * size.width, height: 43 / 296 * size.height))
            context.fill(path, with: .color(.white))
        }
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
                let image = opened ? (store.cinema.filmTaken ? "later-cinema-film-case-empty" : "later-cinema-film-case-full")
                    : "later-cinema-projection-booth-background"
                Image(image).resizable().scaledToFit().accessibilityHidden(true)
                let rect = opened ? CGRect(x: 92, y: 62, width: 163, height: 44)
                    : CGRect(x: 137, y: 26, width: 39, height: 16)
                objectTarget(rect, in: geometry.size, label: opened ? "Take the transparent film" : "Open the film case") {
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
                        Image("later-cinema-acetate-film").resizable().scaledToFit()
                            .rotationEffect(.degrees(90))
                            .frame(width: 43 * geometry.size.width / 320, height: 18 * geometry.size.height / 160)
                            .position(x: slot.midX * geometry.size.width / 320, y: slot.midY * geometry.size.height / 160)
                            .allowsHitTesting(false)
                    }
                    objectTarget(slot, in: geometry.size, label: store.cinema.filmInserted ? "Remove film from projector" : "Insert selected film") {
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
            let mainWidth = max(1, geometry.size.width - 108)
            // Inspect the full screen, then a physical row: five 48 pt seat targets
            // require 240 pt of interaction width (364 pt including rail and margins).
            let area = CGRect(x: 8, y: 8, width: mainWidth - 16, height: geometry.size.height - 16)
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
                    ForEach(store.cinema.seats.sorted(), id: \.self) { seat in
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
                                if dragOrigin == nil { dragOrigin = CGPoint(x: store.cinema.x, y: store.cinema.y) }
                                guard let start = dragOrigin else { return }
                                store.moveCinemaFilm(x: start.x + value.translation.width / zoom,
                                                     y: start.y + value.translation.height / zoom)
                            }
                            .onEnded { _ in dragOrigin = nil; store.persistNow() })
                        .position(x: area.midX, y: area.midY)
                        .accessibilityElement().accessibilityLabel("Projected film")
                        .accessibilityValue("Horizontal offset \(Int(store.cinema.x)), vertical offset \(Int(store.cinema.y)); \(store.cinema.flipped ? "back" : "front") facing")
                        .accessibilityAction(named: "Move left") { store.moveCinemaFilm(x: store.cinema.x - 2, y: store.cinema.y) }
                        .accessibilityAction(named: "Move right") { store.moveCinemaFilm(x: store.cinema.x + 2, y: store.cinema.y) }
                        .accessibilityAction(named: "Move up") { store.moveCinemaFilm(x: store.cinema.x, y: store.cinema.y - 2) }
                        .accessibilityAction(named: "Move down") { store.moveCinemaFilm(x: store.cinema.x, y: store.cinema.y + 2) }
                }
                PuzzleActionRail {
                    if store.cinema.solved {
                        PuzzleButton("Remember", width: PuzzleActionLayout.width) { store.replayKeepsake(.cinema) }
                    } else if choosingSeats {
                        PuzzleButton("Film", width: PuzzleActionLayout.width) { choosingSeats = false; seatRow = nil }
                        PuzzleButton("Enter", width: PuzzleActionLayout.width, action: store.submitCinemaSeats)
                    } else {
                        PuzzleButton("Flip", width: PuzzleActionLayout.width, action: store.flipCinemaFilm)
                            .disabled(!store.cinema.filmInserted)
                        PuzzleButton("Seats", width: PuzzleActionLayout.width) { choosingSeats = true }
                            .disabled(!store.cinema.filmInserted)
                    }
                }
                VStack { Spacer(minLength: 0); SceneFeedback(store: store, height: 32) }
                    .allowsHitTesting(false)
                    .frame(width: mainWidth)
            }
        }
    }

    private var screenBounds: CGRect {
        if let row = seatRow {
            return CGRect(x: 207, y: CGFloat(82 + row * 37) - 18.5, width: 260, height: 37)
        }
        return CGRect(x: 185, y: 40, width: 287, height: 177)
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
                    seatRow = min(3, max(0, Int(((y - 82) / 37).rounded())))
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
