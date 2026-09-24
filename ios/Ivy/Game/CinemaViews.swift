import SwiftUI

/// Authored booth canvas: 320 × 160. Ticket footprint sits on the projector tabletop.
enum CinemaLayout {
    static let ticket = CGRect(x: 163, y: 106, width: 20, height: 10)
    static let spots: [ExplorationSpot] = [
        .init("Film case on the shelf", 137, 26, 39, 16, .memory(.cinemaCase)),
        .init("Projector", 83, 29, 78, 90, .memory(.cinemaProjector)),
        .init("Projection screen", 251, 14, 64, 82, .memory(.cinema)),
        .init("Ticket stub", ticket.minX, ticket.minY, ticket.width, ticket.height, .memory(.cinemaTicket))
    ]
    // Entire diagram plus the permitted ±55 / ±35 displacement stays on the cloth
    // (x150...538, y27...237) of the 591 × 296 screen background.
    static let diagram = CGRect(x: 226, y: 64, width: 204, height: 136)
    static let seatSpacing = CGSize(width: diagram.width * 208 / 1536,
                                    height: diagram.height * 209 / 1024)
    static func seatCenter(_ seat: Int, offset: CGPoint = .zero) -> CGPoint {
        CGPoint(x: offset.x + diagram.minX + diagram.width * ((384 + CGFloat(seat % 5) * 208) / 1536),
                y: offset.y + diagram.minY + diagram.height * ((274 + CGFloat(seat / 5) * 209) / 1024))
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
                .rotation3DEffect(.degrees(52), axis: (x: 1, y: 0, z: 0))
                .rotationEffect(.degrees(-12))
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
                        let left = CinemaLayout.seatCenter(12, offset: progress.projectionOffset)
                        let right = CinemaLayout.seatCenter(13, offset: progress.projectionOffset)
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
        FittedSceneStage {
            GeometryReader { geometry in
                Image(store.cinema.filmInserted ? "cinema-projector-loaded" : "later-cinema-projector-background")
                    .resizable().scaledToFit().accessibilityHidden(true)
                let slot = CGRect(x: 142, y: 60, width: 18, height: 46)
                objectTarget(slot, in: geometry.size, label: store.cinema.filmInserted ? "Inspect projected films" : "Insert selected films") {
                    if store.cinema.filmInserted { store.openMemory(.cinema) }
                    else { store.insertCinemaFilm() }
                }
                .inventoryToolDrop(store: store, accepting: store.cinema.filmInserted ? [] : [.cinemaFilm]) { _ in
                    store.insertCinemaFilm()
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
            let zoom = seatRow == nil ? min(geometry.size.width / source.width, geometry.size.height / source.height)
                : area.width / source.width
            let cameraCenter = seatRow == nil
                ? CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                : CGPoint(x: area.midX, y: area.midY)
            let origin = CGPoint(x: cameraCenter.x - source.midX * zoom, y: cameraCenter.y - source.midY * zoom)
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    Image("later-cinema-screen-background").resizable()
                        .frame(width: 591 * zoom, height: 296 * zoom)
                    CinemaProjection(progress: store.cinema)
                        .frame(width: 591 * zoom, height: 296 * zoom)
                    ForEach(store.cinema.projectionReady ? store.cinema.seats.sorted() : [], id: \.self) { seat in
                        let point = CinemaLayout.seatCenter(seat, offset: store.cinema.projectionOffset)
                        Ellipse().stroke(IvyType.cream, lineWidth: 2)
                            .frame(width: 26 * zoom, height: 29 * zoom)
                            .position(x: point.x * zoom, y: point.y * zoom)
                            .allowsHitTesting(false)
                    }
                }
                .offset(x: origin.x, y: origin.y)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .clipped() // One scene camera shared by the cloth, ink and seat targets.

                if store.cinema.solved {
                    Button { store.replayKeepsake(.cinema) } label: {
                        Color.clear.contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: area.width, height: area.height)
                    .position(x: area.midX, y: area.midY)
                    .accessibilityLabel("Remember the cinema")
                } else if store.cinema.projectionReady {
                    seatTargets(area: area, zoom: zoom, origin: origin)
                } else if !store.cinema.projectionReady {
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
                        EmptyView()
                    } else if store.cinema.projectionReady {
                        PuzzleButton("Enter", width: PuzzleActionLayout.width, action: store.submitCinemaSeats)
                            .disabled(store.cinema.seats.count != 2)
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
            let first = CinemaLayout.seatCenter(row * 5, offset: store.cinema.projectionOffset)
            return CGRect(x: first.x - CinemaLayout.seatSpacing.width / 2,
                          y: first.y - CinemaLayout.seatSpacing.height / 2,
                          width: CinemaLayout.seatSpacing.width * 5,
                          height: CinemaLayout.seatSpacing.height)
        }
        return CGRect(x: 0, y: 0, width: 591, height: 296)
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
                    let first = CinemaLayout.seatCenter(0, offset: store.cinema.projectionOffset)
                    let x = (value.location.x + area.minX - origin.x) / zoom
                    let row = Int(((y - first.y) / CinemaLayout.seatSpacing.height).rounded())
                    guard (0..<4).contains(row),
                          x >= first.x - CinemaLayout.seatSpacing.width / 2,
                          x <= first.x + CinemaLayout.seatSpacing.width * 4.5 else { return }
                    seatRow = row
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
