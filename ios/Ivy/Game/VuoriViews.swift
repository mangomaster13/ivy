import SwiftUI

struct HallKeepsakeView: View {
    @Bindable var store: GameStore

    var body: some View {
        KeepsakeSheet(back: store.cancelOverlay, surface: .scene("vuori-desk")) {
            GeometryReader { geometry in
                let side = min(310, geometry.size.width * 0.46, geometry.size.height - 4)
                HStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Image("memory-shirt-final").resizable().interpolation(.high).scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .accessibilityLabel("Vuori shirt")
                        SceneFeedback(store: store, height: 28)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    VuoriLetterGrid(store: store, layout: VuoriGridLayout(side: side))
                    .frame(width: geometry.size.width * 0.48, height: geometry.size.height)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

/// Hit nodes share the letter-cloth sprite's 1268×1241 reference canvas.
struct VuoriGridLayout {
    let side: CGFloat
    var height: CGFloat { side * 1241 / 1268 }
    private let columns: [CGFloat] = [0.272, 0.505, 0.744]
    private let rows: [CGFloat] = [0.254, 0.471, 0.699]

    func rect(_ index: Int) -> CGRect {
        let point = center(index)
        let target = max(48, side * 0.18)
        return CGRect(x: point.x - target / 2, y: point.y - target / 2,
                      width: target, height: target)
    }

    func center(_ index: Int) -> CGPoint {
        CGPoint(x: side * columns[index % 3], y: height * rows[index / 3])
    }

    func crossedIndices(from start: CGPoint, to end: CGPoint) -> [Int] {
        (0..<9).compactMap { index -> (Int, CGFloat)? in
            let bounds = rect(index)
            var entry: CGFloat = 0
            var exit: CGFloat = 1
            for (origin, delta, low, high) in [
                (start.x, end.x - start.x, bounds.minX, bounds.maxX),
                (start.y, end.y - start.y, bounds.minY, bounds.maxY)
            ] {
                if abs(delta) < 0.0001 {
                    if origin < low || origin > high { return nil }
                } else {
                    let a = (low - origin) / delta, b = (high - origin) / delta
                    entry = max(entry, min(a, b))
                    exit = min(exit, max(a, b))
                    if entry > exit { return nil }
                }
            }
            return (index, entry)
        }.sorted { $0.1 < $1.1 }.map(\.0)
    }
}

private struct VuoriLetterGrid: View {
    @Bindable var store: GameStore
    let layout: VuoriGridLayout
    @State private var previousPoint: CGPoint?
    @State private var lastVisited: Int?
    @State private var dragPoint: CGPoint?
    private let amber = Color(red: 0.86, green: 0.58, blue: 0.19)

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("vuori-letter-cloth").resizable().interpolation(.high)
                .frame(width: layout.side, height: layout.height)
                .accessibilityHidden(true)
            ForEach(0..<max(0, store.vuoriPath.count - 1), id: \.self) { offset in
                if let start = point(for: store.vuoriPath[offset]),
                   let end = point(for: store.vuoriPath[offset + 1]) {
                    thread(from: start, to: end, endInset: layout.side * 0.09)
                }
            }
            if let dragPoint, let last = store.vuoriPath.last, let start = point(for: last) {
                thread(from: start, to: dragPoint, endInset: 0)
            }

            ForEach(VuoriPuzzle.displayIndices.indices, id: \.self) { position in
                let index = VuoriPuzzle.displayIndices[position]
                let order = store.vuoriPath.firstIndex(of: index)
                Circle()
                    .stroke(order == nil ? .clear : amber, lineWidth: 2.5)
                    .frame(width: layout.rect(position).width, height: layout.rect(position).height)
                    .contentShape(Circle())
                    .position(layout.center(position))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(String(VuoriPuzzle.letters[index]).uppercased())
                    .accessibilityValue(order.map { "Selected, \($0 + 1) of \(store.vuoriPath.count)" } ?? "Not selected")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("vuori-letter-\(position)")
                    .accessibilityAction {
                        store.connectVuoriLetter(index)
                    }
            }
        }
        .frame(width: layout.side, height: layout.height)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { trace(to: $0.location, start: $0.startLocation) }
            .onEnded {
                trace(to: $0.location, start: $0.startLocation)
                previousPoint = nil
                lastVisited = nil
                dragPoint = nil
                store.finishVuoriConnection()
            })
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Letter connections")
        .accessibilityAction(named: "Finish connection") { store.finishVuoriConnection() }
    }

    private func trace(to point: CGPoint, start: CGPoint) {
        if previousPoint == nil { store.beginVuoriConnection() }
        for position in layout.crossedIndices(from: previousPoint ?? start, to: point) where position != lastVisited {
            store.connectVuoriLetter(VuoriPuzzle.displayIndices[position])
            lastVisited = position
        }
        previousPoint = point
        dragPoint = CGPoint(x: min(max(point.x, 0), layout.side),
                            y: min(max(point.y, 0), layout.height))
    }

    private func point(for index: Int) -> CGPoint? {
        VuoriPuzzle.displayIndices.firstIndex(of: index).map(layout.center)
    }

    private func thread(from start: CGPoint, to end: CGPoint, endInset: CGFloat) -> some View {
        let dx = end.x - start.x, dy = end.y - start.y
        let distance = (dx * dx + dy * dy).squareRoot()
        let startInset = layout.side * 0.09
        let length = max(0, distance - startInset - endInset)
        let position = distance > 0 ? (startInset + length / 2) / distance : 0
        return Image("vuori-thread").resizable().interpolation(.high)
            .frame(width: length, height: 7)
            .rotationEffect(.radians(atan2(Double(dy), Double(dx))))
            .position(x: start.x + dx * position, y: start.y + dy * position)
            .accessibilityHidden(true)
    }
}

/// A repeatable, finite fabric lift and warm light sweep, separate from collecting an egg.
struct VuoriMemoryView: View {
    @Bindable var store: GameStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var replay = 0
    @State private var lift: CGFloat = 0
    @State private var light: CGFloat = -1
    @State private var revealed = false

    var body: some View {
        KeepsakeSheet(back: store.dismissVuoriMemory, surface: .scene("vuori-desk")) {
            GeometryReader { geometry in
                let size = min(geometry.size.height - 28, geometry.size.width * 0.65)
                Button {
                    IvyHaptics.soft()
                    replay += 1
                } label: {
                    shirt
                        .overlay {
                            if !reduceMotion {
                                LinearGradient(colors: [.clear, IvyType.cream.opacity(0.26), .clear],
                                               startPoint: .leading, endPoint: .trailing)
                                    .frame(width: size * 0.32, height: size * 1.5)
                                    .rotationEffect(.degrees(-22))
                                    .offset(x: light * size)
                                    .frame(width: size, height: size)
                                    .mask(shirt)
                                    .allowsHitTesting(false)
                            }
                        }
                        .frame(width: size, height: size)
                        .shadow(color: .black.opacity(0.22 + lift * 0.1), radius: 3 + lift * 5, y: 3 + lift * 7)
                        .scaleEffect(1 + lift * 0.025)
                        .rotationEffect(.degrees(Double(lift) * -1.5))
                        .offset(y: -lift * 7)
                        .opacity(revealed ? 1 : 0)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Vuori shirt")
                .accessibilityHint("Replay this keepsake's movement")
                .accessibilityIdentifier("vuori-memory-shirt")
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .task(id: replay) { await animateMemory() }
        .onChange(of: reduceMotion) { _, _ in replay += 1 }
    }

    private var shirt: some View {
        Image("memory-shirt-final").resizable().interpolation(.high).scaledToFit()
    }

    @MainActor private func animateMemory() async {
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            lift = 0; light = -1
            if reduceMotion { revealed = false }
        }
        withAnimation(.easeOut(duration: 0.2)) { revealed = true }
        guard !reduceMotion else { return }
        do {
            withAnimation(.easeInOut(duration: 0.45)) { lift = 1 }
            try await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeInOut(duration: 1.0)) { light = 1 }
            try await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeInOut(duration: 0.65)) { lift = 0 }
        } catch { return }
    }
}
