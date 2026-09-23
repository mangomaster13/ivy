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
                    InspectionBackdrop(surface: .scene("city-window-closeup"))
                    GeometryReader { geometry in
                        let layout = CityGridLayout(size: geometry.size)
                        ZStack(alignment: .topLeading) {
                            ZStack(alignment: .topLeading) {
                                Color.clear
                                ForEach(0..<9) { slot in
                                    Rectangle().stroke(IvyType.cream.opacity(0.09), lineWidth: 0.6)
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
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .position(x: layout.board.midX, y: layout.board.midY)
                            ForEach(Array(trayOrder.enumerated()), id: \.element) { index, piece in
                                if !slots.contains(where: { $0 == piece }) {
                                    tile(piece, edge: layout.trayEdge, origin: layout.trayCenter(index), layout: layout)
                                        .opacity(dragging == piece ? 0 : 1)
                                        .position(layout.trayCenter(index))
                                }
                            }
                            if let dragging {
                                CityGridPiece(piece: dragging, edge: layout.cell)
                                    .position(dragPoint).allowsHitTesting(false)
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
        CityGridPiece(piece: piece, edge: edge)
            .overlay(Rectangle().stroke(selected == piece ? IvyType.cream.opacity(0.7) : .clear, lineWidth: 1))
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
    // Source artwork is 1774×887; the painted tray opening and sill share this fit.
    private var scale: CGFloat { size.width / 1774 }
    var board: CGRect {
        CGRect(x: 470 * scale, y: 416 * scale, width: 288 * scale, height: 288 * scale)
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
            CGPoint(x: 1010, y: 452), CGPoint(x: 1220, y: 460), CGPoint(x: 1460, y: 455),
            CGPoint(x: 980, y: 590), CGPoint(x: 1200, y: 570), CGPoint(x: 1410, y: 595),
            CGPoint(x: 1050, y: 735), CGPoint(x: 1260, y: 720), CGPoint(x: 1500, y: 725)
        ]
        return CGPoint(x: centers[slot].x * scale, y: centers[slot].y * scale)
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
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(IvyType.ink))
            context.clip(to: Path(CGRect(origin: .zero, size: size)))
            context.draw(Image(EggId.city.iconName), in: CGRect(
                x: -CGFloat(piece % 3) * size.width, y: -CGFloat(piece / 3) * size.height,
                width: size.width * 3, height: size.height * 3))
        }
        .frame(width: edge, height: edge)
    }
}
