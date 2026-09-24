import SwiftUI

/// Normalized geometry survives device size changes and save/load. Separate strokes never bridge.
struct RubbingProgress: Codable, Equatable {
    struct Point: Codable, Equatable { var x: Double; var y: Double }
    struct Stroke: Codable, Equatable { var points: [Point]; var radiusX: Double; var radiusY: Double }
    var strokes: [Stroke] = []
    mutating func begin(at point: CGPoint, size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        strokes.append(Stroke(points: [Self.normalize(point, size)], radiusX: 17 / size.width, radiusY: 17 / size.height))
    }
    mutating func append(_ point: CGPoint, size: CGSize) {
        guard !strokes.isEmpty, size.width > 0, size.height > 0 else { return }
        let p = Self.normalize(point, size), last = strokes.count - 1
        if let previous = strokes[last].points.last,
           hypot((p.x - previous.x) * size.width, (p.y - previous.y) * size.height) < 2 { return }
        strokes[last].points.append(p)
    }
    private static func normalize(_ p: CGPoint, _ s: CGSize) -> Point {
        Point(x: min(1, max(0, p.x / s.width)), y: min(1, max(0, p.y / s.height)))
    }
    func covers(_ p: Point) -> Bool {
        for stroke in strokes where stroke.radiusX > 0 && stroke.radiusY > 0 {
            let points = stroke.points
            for i in points.indices {
                let a = points[i], b = points[max(0, i - 1)]
                let ax = (a.x - p.x) / stroke.radiusX, ay = (a.y - p.y) / stroke.radiusY
                let bx = (b.x - p.x) / stroke.radiusX, by = (b.y - p.y) / stroke.radiusY
                let dx = bx - ax, dy = by - ay, length = dx * dx + dy * dy
                let t = length == 0 ? 0 : min(1, max(0, -(ax * dx + ay * dy) / length))
                if hypot(ax + t * dx, ay + t * dy) <= 1 { return true }
            }
        }
        return false
    }
    /// Each clue region must be readable; rubbing the same spot never advances other regions.
    var complete: Bool { isComplete(vertical: false) }
    func isComplete(vertical: Bool) -> Bool {
        (0..<4).allSatisfy { region in
            var cleared = 0
            for row in 0..<5 { for column in 0..<5 {
                let p = Point(x: vertical ? 0.38 + Double(column) * 0.06 : (Double(region) + 0.2 + Double(column) * 0.15) / 4,
                              y: vertical ? 0.16 + Double(region) * 0.18 + Double(row) * 0.03 : 0.28 + Double(row) * 0.11)
                if covers(p) { cleared += 1 }
            } }
            return cleared >= 20
        }
    }
}

enum RubbingMaterial { case graphite, condensation, rain }

/// Draws only the removable material; the physical object underneath belongs to the scene.
struct RubbingSurface<Content: View>: View {
    @Binding var progress: RubbingProgress
    let material: RubbingMaterial
    let revealed: Bool
    let canRub: Bool
    let toolImage: String
    let label: String
    let save: () -> Void
    let completion: () -> Void
    @ViewBuilder let content: Content
    @State private var contact: CGPoint?
    @State private var active = false
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                content.frame(maxWidth: .infinity, maxHeight: .infinity)
                    .mask {
                        if revealed && progress.strokes.isEmpty { Color.white }
                        else { strokeMask }
                    }
                if !revealed || !progress.strokes.isEmpty {
                    coating.mask {
                        Canvas { context, size in
                            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
                            context.blendMode = .destinationOut
                            for stroke in progress.strokes {
                                guard let first = stroke.points.first else { continue }
                                // Render in normalized space so a saved stroke and its coverage stay identical.
                                var layer = context
                                layer.scaleBy(x: size.width * stroke.radiusX, y: size.height * stroke.radiusY)
                                var path = Path()
                                path.move(to: CGPoint(x: first.x / stroke.radiusX, y: first.y / stroke.radiusY))
                                for p in stroke.points.dropFirst() {
                                    path.addLine(to: CGPoint(x: p.x / stroke.radiusX, y: p.y / stroke.radiusY))
                                }
                                if stroke.points.count == 1 {
                                    layer.fill(Path(ellipseIn: CGRect(x: first.x / stroke.radiusX - 1, y: first.y / stroke.radiusY - 1, width: 2, height: 2)), with: .color(.white))
                                } else {
                                    layer.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                }
                            }
                        }.blur(radius: material == .graphite ? 0.6 : 3)
                    }
                }
                if let contact, canRub, !revealed {
                    Image(toolImage).resizable().scaledToFit().frame(width: 44, height: 34)
                        .rotationEffect(.degrees(-18)).position(x: contact.x + 12, y: contact.y - 10)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }.clipped().contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    guard canRub, !revealed else { return }
                    if !active { progress.begin(at: value.startLocation, size: geometry.size); active = true }
                    progress.append(value.location, size: geometry.size)
                    contact = value.location
                }.onEnded { _ in
                    guard active else { return }
                    active = false; contact = nil; save()
                    if progress.isComplete(vertical: material == .condensation) { completion() }
                })
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label)
                .accessibilityAction(named: "Reveal with selected tool") {
                    if canRub && !revealed { completion() }
                }
                .onDisappear { if active { save() } }
        }
    }
    private var strokeMask: some View {
        Canvas { context, size in
            for stroke in progress.strokes {
                guard let first = stroke.points.first else { continue }
                var layer = context
                layer.scaleBy(x: size.width * stroke.radiusX, y: size.height * stroke.radiusY)
                var path = Path()
                path.move(to: CGPoint(x: first.x / stroke.radiusX, y: first.y / stroke.radiusY))
                for p in stroke.points.dropFirst() {
                    path.addLine(to: CGPoint(x: p.x / stroke.radiusX, y: p.y / stroke.radiusY))
                }
                layer.fill(Path(ellipseIn: CGRect(x: first.x / stroke.radiusX - 1, y: first.y / stroke.radiusY - 1, width: 2, height: 2)), with: .color(.white))
                layer.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }.blur(radius: 0.6)
    }
    private var coating: some View {
        Canvas { context, size in
            if material == .graphite {
                var seed: UInt64 = 817
                func grain() -> CGFloat {
                    seed = seed &* 6364136223846793005 &+ 1442695040888963407
                    return CGFloat((seed >> 32) & 0xFFFF) / 65535
                }
                for _ in 0..<4200 {
                    let x = grain() * size.width, y = grain() * size.height
                    let length = 3 + grain() * 16
                    var p = Path(); p.move(to: CGPoint(x: x, y: y))
                    p.addQuadCurve(to: CGPoint(x: x + length, y: y - length * (0.25 + grain() * 0.65)),
                                  control: CGPoint(x: x + length * 0.45, y: y - grain() * 6))
                    context.stroke(p, with: .color(Color(red: 0.19, green: 0.20, blue: 0.18).opacity(0.15 + Double(grain()) * 0.45)),
                                   style: StrokeStyle(lineWidth: 0.3 + grain() * 0.65, lineCap: .round))
                }
            } else {
                drawMoisture(in: &context, size: size)
            }
        }
        .mask {
            // Fade the material's perimeter; clue visibility is controlled independently above.
            RoundedRectangle(cornerRadius: material == .graphite ? 18 : 24)
                .padding(3).blur(radius: material == .graphite ? 5 : 9)
        }
    }

    /// Transparent local deposits preserve the scene's reflection/paper instead of tinting a slab.
    /// Seeded geometry stays still as the gesture redraws the surface.
    private func drawMoisture(in context: inout GraphicsContext, size: CGSize) {
        let glass = material == .condensation
        var seed: UInt64 = glass ? 6193 : 8170
        func random() -> CGFloat {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return CGFloat((seed >> 32) & 0xFFFF) / 65535
        }
        let bounds = Path(CGRect(origin: .zero, size: size))
        // Fog scatters warm ambient light. Wet paper instead darkens locally as fibres absorb water.
        let deposit = glass ? Color(red: 0.92, green: 0.91, blue: 0.85)
                            : Color(red: 0.30, green: 0.27, blue: 0.18)
        for _ in 0..<(glass ? 24 : 15) {
            let x = random(), y = random()
            let center = CGPoint(x: x * size.width, y: y * size.height)
            let edge = max(abs(x - 0.5), abs(y - 0.5)) * 2
            let opacity = glass ? 0.035 + Double(edge) * 0.055 : 0.035
            let radius = min(size.width, size.height) * (0.18 + random() * 0.30)
            context.fill(bounds, with: .radialGradient(
                Gradient(colors: [deposit.opacity(opacity), deposit.opacity(opacity * 0.5), .clear]),
                center: center, startRadius: 0, endRadius: radius))
        }
        // Tiny non-uniform beads: a shaded body and one light edge, never outlined circles.
        for _ in 0..<(glass ? 460 : 85) {
            let x = random() * size.width, y = random() * size.height
            let radius = 0.25 + random() * (glass ? 0.65 : 0.95)
            let drop = CGRect(x: x, y: y, width: radius * 1.5, height: radius * (1.5 + random()))
            context.fill(Path(ellipseIn: drop), with: .color(.black.opacity(glass ? 0.07 : 0.045)))
            let glint = CGRect(x: x, y: y, width: radius, height: radius * 0.5)
            context.fill(Path(ellipseIn: glint), with: .color(IvyType.cream.opacity(0.10 + Double(random()) * 0.18)))
        }
        // Sparse capillary trails, softly lit and irregular rather than a uniform rain pattern.
        for _ in 0..<(glass ? 7 : 4) {
            let x = random() * size.width, y = random() * size.height
            let length = 4 + random() * (glass ? 19 : 10)
            var trail = Path()
            trail.move(to: CGPoint(x: x, y: y))
            trail.addQuadCurve(to: CGPoint(x: x + 1, y: y + length),
                               control: CGPoint(x: x - 1.5, y: y + length * 0.6))
            context.stroke(trail, with: .color(IvyType.cream.opacity(glass ? 0.12 : 0.09)),
                           style: StrokeStyle(lineWidth: 0.65, lineCap: .round))
        }
    }
}

extension GameStore {
    func rubbingBinding(_ clue: AdventureClue) -> Binding<RubbingProgress> {
        Binding(get: { self.exploration.rubbing?[clue.rawValue] ?? RubbingProgress() },
                set: { value in
                    if self.exploration.rubbing == nil { self.exploration.rubbing = [:] }
                    self.exploration.rubbing?[clue.rawValue] = value
                })
    }
}

struct MirrorRubbingCloseup: View {
    @Bindable var store: GameStore
    var body: some View {
        GeometryReader { geometry in
            // Cover content, transforming the glass and rubbing surface together.
            let width = max(geometry.size.width, geometry.size.height * 2.17)
            let height = width / 2.17
            ZStack {
                ZStack {
                    Image("closeup-mirror-clear").resizable().interpolation(.high)
                    RubbingSurface(progress: store.rubbingBinding(.mirror), material: .condensation,
                                   revealed: store.exploration.clues.contains(.mirror), canRub: store.selectedTool == .cloth,
                                   toolImage: AdventureTool.cloth.imageName, label: store.exploration.clues.contains(.mirror) ? store.clueText(.mirror) : "Misted mirror",
                                   save: store.persistNow, completion: store.wipeMirror) {
                        VStack(spacing: 10) {
                            ForEach([2, 0, 3, 1], id: \.self) { index in
                                HStack(spacing: 14) {
                                    Image(systemName: ["moon", "leaf", "star", "drop"][index]).font(.system(size: 20))
                                    Text(String(store.exploration.hotelCode[index])).font(IvyType.hand(27))
                                }
                            }
                        }.foregroundStyle(IvyType.cream)
                    }.frame(width: width * 0.285, height: height * 0.69)
                        .clipShape(Ellipse()).position(x: width * 0.5, y: height * 0.48)
                }.frame(width: width, height: height)
                VStack {
                    Spacer()
                    SceneFeedback(store: store, height: 44)
                }.frame(width: geometry.size.width - 24, height: geometry.size.height - 24)
            }.frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .gameBackAction(store.cancelOverlay)
    }
}

/// The ticket/menu paper is a native physical surface, never a screenshot or scene inset.
struct PuzzlePaper: View {
    var body: some View {
        Canvas { context, size in
            let bounds = CGRect(origin: .zero, size: size)
            context.fill(Path(roundedRect: bounds, cornerRadius: 7), with: .color(Color(red: 0.72, green: 0.73, blue: 0.59)))
            for i in 0..<4500 {
                let x = CGFloat((i * 137) % 4999) / 4999 * size.width
                let y = CGFloat((i * 283) % 4993) / 4993 * size.height
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 0.7, height: 0.5)),
                             with: .color(IvyType.ink.opacity(0.10 + Double(i % 3) * 0.03)))
            }
            context.stroke(Path(roundedRect: bounds.insetBy(dx: 7, dy: 7), cornerRadius: 4),
                           with: .color(Color(red: 0.40, green: 0.36, blue: 0.20).opacity(0.55)), lineWidth: 0.7)
        }.clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

struct TicketRubbingView: View {
    @Bindable var store: GameStore
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width, h = geometry.size.height
            ZStack(alignment: .topLeading) {
                Image("ticket-paper").resizable().interpolation(.high).frame(width: w, height: h)
                Text("Hangzhou → Hong Kong")
                    .font(.custom("Georgia-Italic", size: min(27, w * 0.055)))
                    .foregroundStyle(Color(red: 0.35, green: 0.27, blue: 0.12))
                    .frame(width: w * 0.72, height: h * 0.18)
                    .position(x: w * 0.43, y: h * 0.31)
                IvyType.inscription("our first journey")
                    .font(IvyType.script(min(25, w * 0.048)))
                    .foregroundStyle(Color(red: 0.35, green: 0.27, blue: 0.12))
                    .frame(width: w * 0.66, height: h * 0.16)
                    .position(x: w * 0.43, y: h * 0.46)
                RubbingSurface(progress: store.rubbingBinding(.travelOrder), material: .graphite,
                               revealed: store.exploration.clues.contains(.travelOrder), canRub: store.selectedTool == .eraser,
                               toolImage: AdventureTool.eraser.imageName, label: "Graphite-marked ticket",
                               save: store.persistNow, completion: store.traceTicket) {
                    TravelOrderSymbols(symbolSize: min(33, w * 0.068))
                }.frame(width: w * 0.73, height: h * 0.35)
                    .position(x: w * 0.43, y: h * 0.70)
            }
        }.aspectRatio(2.2, contentMode: .fit)
    }
}

/// Keep the discovered notebook clue identical to the marks on the ticket.
struct TravelOrderSymbols: View {
    var symbolSize: CGFloat

    var body: some View {
        HStack(spacing: 10) {
            ForEach(["moon.fill", "leaf.fill", "star.fill", "drop.fill"], id: \.self) { symbol in
                Image(systemName: symbol)
                    .font(.system(size: symbolSize))
                    .frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(Color(red: 0.45, green: 0.33, blue: 0.12))
        .padding(.horizontal, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Moon, leaf, star, drop")
    }
}
