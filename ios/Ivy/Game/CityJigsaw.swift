import SwiftUI

/// Every slot accepts every piece; only the complete arrangement is evaluated.
struct CityJigsawView: View {
    @Bindable var store: GameStore
    @State private var selected: Int?
    @State private var dragging: Int?
    @State private var dragPoint: CGPoint = .zero
    private var trayOrder: [Int] { store.memories.cityLooseOrder ?? [7, 2, 5, 0, 8, 3, 6, 1, 4] }
    private var slots: [Int?] { store.memories.cityBoard ?? Array(repeating: nil, count: 9) }
    private var motion: Animation? { store.prefersReducedMotion ? nil : .easeInOut(duration: 0.3) }

    var body: some View {
        if store.memories.citySolved {
            ElementMemoryView(store: store, image: EggId.city.memoryImage, title: EggId.city.memoryTitle,
                              line: EggId.city.memoryLine, back: store.backFromMemory,
                              startsDefocused: true)
                .transition(.opacity)
        } else {
            FittedSceneStage(aspectRatio: 2) {
                ZStack {
                    Color("Night")
                    InspectionBackdrop(surface: .scene("city-puzzle-overhead"))
                    GeometryReader { geometry in
                        let layout = CityGridLayout(size: geometry.size)
                        ZStack(alignment: .topLeading) {
                            ZStack(alignment: .topLeading) {
                                Color.clear
                                ForEach(0..<9) { slot in
                                    Rectangle().stroke(IvyType.ink.opacity(0.35), lineWidth: 0.6)
                                        .frame(width: layout.cell, height: layout.cell)
                                        .contentShape(Rectangle())
                                        .position(layout.localCenter(slot))
                                        .onTapGesture { if let selected { place(selected, at: slot) } }
                                        .accessibilityLabel("Photo position \(slot + 1)")
                                        .accessibilityAddTraits(.isButton)
                                        .accessibilityAction { if let selected { place(selected, at: slot) } }
                                    if let piece = slots[slot] {
                                        tile(piece, edge: layout.cell, origin: layout.boardCenter(slot), layout: layout)
                                            .opacity(dragging == piece ? 0 : 1)
                                            .position(layout.localCenter(slot))
                                    }
                                }
                            }
                            .frame(width: layout.board.width, height: layout.board.height)
                            .clipShape(RoundedRectangle(cornerRadius: layout.cell * 0.025))
                            .position(x: layout.board.midX, y: layout.board.midY)
                            ForEach(Array(trayOrder.enumerated()), id: \.element) { index, piece in
                                if !slots.contains(where: { $0 == piece }) {
                                    tile(piece, edge: layout.trayEdge, origin: layout.trayCenter(index), layout: layout)
                                        .rotationEffect(.degrees(layout.trayAngle(index)))
                                        .shadow(color: .black.opacity(0.45), radius: layout.cell * 0.018,
                                                x: layout.cell * 0.014, y: layout.cell * 0.025)
                                        .zIndex(selected == piece ? 10 : Double(index + 1))
                                        .opacity(dragging == piece ? 0 : 1)
                                        .position(layout.trayCenter(index))
                                }
                            }
                            if let dragging {
                                CityGridPiece(piece: dragging, edge: layout.cell)
                                    .shadow(color: .black.opacity(0.4), radius: layout.cell * 0.04, y: layout.cell * 0.06)
                                    .position(dragPoint).allowsHitTesting(false).zIndex(20)
                            }
                        }
                        .coordinateSpace(name: "city-grid")
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
                .gameBackAction(store.backFromMemory)
            }
        }
    }

    private func tile(_ piece: Int, edge: CGFloat, origin: CGPoint, layout: CityGridLayout) -> some View {
        CityGridPiece(piece: piece, edge: edge, selected: selected == piece)
            .frame(width: max(48, edge), height: max(48, edge))
            .contentShape(Rectangle())
            .onTapGesture {
                if let selected, selected != piece, let slot = slots.firstIndex(where: { $0 == piece }) {
                    place(selected, at: slot)
                } else { selected = selected == piece ? nil : piece }
            }
            .gesture(DragGesture(minimumDistance: 7, coordinateSpace: .named("city-grid"))
                .onChanged { value in
                    dragging = piece
                    dragPoint = CGPoint(x: origin.x + value.translation.width, y: origin.y + value.translation.height)
                }
                .onEnded { value in
                    let end = CGPoint(x: origin.x + value.translation.width, y: origin.y + value.translation.height)
                    if let target = layout.slot(at: end) { place(piece, at: target) }
                    else if let position = layout.looseSlot(at: end) {
                        store.moveCityLoosePiece(piece, to: position); selected = nil
                    }
                    dragging = nil
                })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Photo piece \(piece + 1)")
            .accessibilityValue(selected == piece ? "Selected" : "")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { selected = piece }
            .accessibilityActions {
                ForEach(0..<9) { slot in
                    Button("Move to position \(slot + 1)") { place(piece, at: slot) }
                }
                Button("Return to loose pieces") { store.returnCityPiece(piece) }
            }
    }

    private func place(_ piece: Int, at target: Int) {
        withAnimation(motion) { store.placeCityPiece(piece, at: target); selected = nil }
    }
}

private struct CityGridLayout {
    let size: CGSize
    // Approved overhead canvas: 1774×887. Table supports every rotated tile.
    // Revised painted recess is approximately (202, 126), 618×608.
    // Center a square working area with an 18-unit inset; the hand-painted
    // side edges add only ~5 units. Drawing and drops share this transform.
    private var scale: CGFloat { size.width / 1774 }
    var board: CGRect {
        CGRect(x: 207 * scale, y: 126 * scale, width: 608 * scale, height: 608 * scale)
            .insetBy(dx: 18 * scale, dy: 18 * scale)
    }
    var cell: CGFloat { board.width / 3 }
    var trayEdge: CGFloat { cell }
    func localCenter(_ slot: Int) -> CGPoint {
        CGPoint(x: (CGFloat(slot % 3) + 0.5) * cell, y: (CGFloat(slot / 3) + 0.5) * cell)
    }
    func boardCenter(_ slot: Int) -> CGPoint {
        let p = localCenter(slot)
        return CGPoint(x: board.minX + p.x, y: board.minY + p.y)
    }
    func trayCenter(_ slot: Int) -> CGPoint {
        let centers: [CGPoint] = [
            CGPoint(x: 1410, y: 205), CGPoint(x: 1080, y: 415), CGPoint(x: 1100, y: 655),
            CGPoint(x: 1550, y: 585), CGPoint(x: 1495, y: 380), CGPoint(x: 1150, y: 265),
            CGPoint(x: 1280, y: 600), CGPoint(x: 1440, y: 685), CGPoint(x: 1270, y: 425)
        ]
        return CGPoint(x: centers[slot].x * scale, y: centers[slot].y * scale)
    }
    func trayAngle(_ slot: Int) -> Double {
        [18, 14, -18, 16, -21, -24, 18, -16, 14][slot]
    }
    func slot(at point: CGPoint) -> Int? {
        guard board.contains(point) else { return nil }
        return min(2, Int((point.y - board.minY) / cell)) * 3 + min(2, Int((point.x - board.minX) / cell))
    }
    func looseSlot(at point: CGPoint) -> Int? {
        let centers = (0..<9).map(trayCenter)
        guard let nearest = centers.enumerated().min(by: {
            hypot($0.element.x - point.x, $0.element.y - point.y) <
            hypot($1.element.x - point.x, $1.element.y - point.y)
        }), hypot(nearest.element.x - point.x, nearest.element.y - point.y) < max(48, trayEdge) else { return nil }
        return nearest.offset
    }
}

private struct CityGridPiece: View {
    let piece: Int
    let edge: CGFloat
    var selected = false

    var body: some View {
        let outline = RoundedRectangle(cornerRadius: edge * 0.035, style: .continuous)
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(IvyType.ink))
            context.clip(to: Path(CGRect(origin: .zero, size: size)))
            context.draw(Image(EggId.city.iconName), in: CGRect(
                x: -CGFloat(piece % 3) * size.width, y: -CGFloat(piece / 3) * size.height,
                width: size.width * 3, height: size.height * 3))
        }
        .frame(width: edge, height: edge)
        .clipShape(outline)
        .background {
            outline.fill(IvyType.ink)
                .offset(y: edge * 0.012)
        }
        .overlay {
            outline.strokeBorder(IvyType.cream.opacity(selected ? 0.8 : 0.45),
                                 lineWidth: max(0.75, edge * 0.012))
        }
    }
}
