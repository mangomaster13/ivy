import SwiftUI

/// 320×160 anchors measured against the approved 1774×887 rear-seat camera.
enum TaxiLayout {
    static let card = CGRect(x: 212, y: 110, width: 25, height: 19)
    static let map = CGRect(x: 229, y: 95, width: 36, height: 35)
    static let meter = CGRect(x: 145, y: 59, width: 37, height: 25)
    static let nodes: [CGPoint] = [
        CGPoint(x: 72, y: 79), CGPoint(x: 102, y: 69), CGPoint(x: 67, y: 109),
        CGPoint(x: 169, y: 54), CGPoint(x: 139, y: 83), CGPoint(x: 168, y: 109),
        CGPoint(x: 194, y: 81)
    ]
    static let nodeNames = ["A", "B", "C", "D", "E", "F", "G"]

    static func spots(progress: TaxiProgress) -> [ExplorationSpot] {
        var result: [ExplorationSpot] = []
        if !progress.cardTaken {
            result.append(.init("Folded route card", card.minX, card.minY, card.width, card.height, .memory(.taxiCard)))
        }
        result.append(.init("Route map", map.minX, map.minY, map.width, map.height, .memory(.taxi)))
        if progress.arrived {
            result.append(.init("Taxi meter receipt", meter.minX, meter.minY, meter.width, meter.height, .memory(.taxiReceipt)))
        }
        return result
    }
}

struct TaxiCloseupView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel

    var body: some View {
        Group {
            switch panel {
            case .taxiCard: card
            case .taxiReceipt: receipt
            default: routeBoard
            }
        }
        .gameBackAction(store.backFromMemory)
    }

    private var card: some View {
        ZStack {
            InspectionBackdrop(surface: .defocusedScene(store.roomImageName))
            Button(action: store.takeTaxiCard) {
                Image("later-taxi-route-card").resizable().interpolation(.high).scaledToFit()
                    .frame(maxWidth: 680, maxHeight: 290)
            }
            .buttonStyle(.plain)
            .disabled(store.taxi.cardTaken)
            .accessibilityLabel(store.taxi.cardTaken ? "Route card recorded in Notes" : "Take the route card and record it in Notes")
        }
    }

    private var routeBoard: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                ZStack(alignment: .topLeading) {
                    Image("later-taxi-map-background").resizable().interpolation(.high)
                        .accessibilityHidden(true)
                    Image("later-taxi-route-graph-overlay").resizable().interpolation(.high)
                        .accessibilityHidden(true)
                    Path { path in
                        let points = store.taxi.route.map { TaxiLayout.nodes[$0] }
                        guard let first = points.first else { return }
                        path.move(to: CGPoint(x: first.x * scale, y: first.y * scale))
                        for point in points.dropFirst() {
                            path.addLine(to: CGPoint(x: point.x * scale, y: point.y * scale))
                        }
                    }
                    .stroke(Color(red: 0.98, green: 0.56, blue: 0.25), style: StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round, lineJoin: .round))
                    .allowsHitTesting(false)
                    ForEach(TaxiLayout.nodes.indices, id: \.self) { node in
                        Button { store.extendTaxiRoute(to: node) } label: {
                            Circle().fill(.clear)
                                .frame(width: max(48, 18 * scale), height: max(48, 18 * scale))
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .position(x: TaxiLayout.nodes[node].x * scale, y: TaxiLayout.nodes[node].y * scale)
                        .accessibilityLabel("Route point \(TaxiLayout.nodeNames[node])")
                        .accessibilityHint("Connect from the current point along an arrow")
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { value in
                    touch(value.location, scale: scale)
                })
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if store.taxi.route.count > 1 && !store.taxi.arrived {
                PuzzleButton("Undo", width: PuzzleActionLayout.width, action: store.undoTaxiRoute)
                    .padding(.trailing, 8).padding(.bottom, 8)
            }
        }
    }

    private func touch(_ point: CGPoint, scale: CGFloat) {
        guard scale > 0 else { return }
        let position = CGPoint(x: point.x / scale, y: point.y / scale)
        guard let node = TaxiLayout.nodes.indices.min(by: {
            hypot(TaxiLayout.nodes[$0].x - position.x, TaxiLayout.nodes[$0].y - position.y)
                < hypot(TaxiLayout.nodes[$1].x - position.x, TaxiLayout.nodes[$1].y - position.y)
        }), hypot(TaxiLayout.nodes[node].x - position.x, TaxiLayout.nodes[node].y - position.y) < 12 else { return }
        store.extendTaxiRoute(to: node)
    }

    private var receipt: some View {
        ZStack {
            InspectionBackdrop(surface: .defocusedScene(store.roomImageName))
            Button(action: store.takeTaxiReceipt) {
                Image("later-taxi-receipt-stay").resizable().interpolation(.high).scaledToFit()
                    .frame(maxWidth: 450, maxHeight: 290)
            }
            .buttonStyle(.plain)
            .disabled(store.taxi.receiptTaken)
            .accessibilityLabel("Take the printed taxi receipt")
        }
    }
}
