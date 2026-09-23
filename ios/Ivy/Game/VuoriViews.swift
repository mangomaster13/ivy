import SwiftUI

struct HallKeepsakeView: View {
    @Bindable var store: GameStore
    @State private var showingTag = false

    var body: some View {
        KeepsakeSheet(back: {
            if showingTag { showingTag = false }
            else { store.cancelOverlay() }
        }, surface: .scene(showingTag ? "vuori-tag-closeup" : "vuori-desk")) {
            if showingTag {
                Color.clear.accessibilityElement()
                    .accessibilityLabel("A stitched nine-point tag. Start at the top middle, then down, left, down, right.")
            } else {
                GeometryReader { geometry in
                    let gap: CGFloat = 10
                    let side = min(88, (geometry.size.height - 120) / 3,
                                   (geometry.size.width * 0.48 - gap * 2) / 3)
                    HStack(spacing: 24) {
                        GeometryReader { shirt in
                            Image("memory-shirt-final").resizable().interpolation(.high).scaledToFit()
                                .frame(width: shirt.size.width, height: shirt.size.height)
                            Button { showingTag = true } label: {
                                Image("vuori-tag-sprite").resizable().interpolation(.high).scaledToFit()
                                    .frame(width: 33, height: 42)
                                    .frame(width: 48, height: 48)
                            }
                            .buttonStyle(.plain)
                            .position(x: shirt.size.width * 0.5, y: shirt.size.height * 0.19)
                            .accessibilityLabel("Inspect the stitched shirt tag")
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        VStack(spacing: 8) {
                            VuoriLetterGrid(store: store, layout: VuoriGridLayout(side: side, gap: gap))
                            HStack(spacing: 14) {
                                PuzzleButton("erase", action: store.eraseVuoriConnection)
                                PuzzleButton("clear", action: store.clearVuoriConnection)
                            }
                            .disabled(store.vuoriDraft.isEmpty)
                            .opacity(store.vuoriDraft.isEmpty ? 0.5 : 1)
                            SceneFeedback(store: store, height: 28)
                        }
                        .frame(width: geometry.size.width * 0.48, height: geometry.size.height)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }
}

/// Shared hit geometry sweeps between touch samples so fast swipes cannot skip letters.
struct VuoriGridLayout {
    let side: CGFloat
    let gap: CGFloat
    var extent: CGFloat { side * 3 + gap * 2 }

    func rect(_ index: Int) -> CGRect {
        CGRect(x: CGFloat(index % 3) * (side + gap), y: CGFloat(index / 3) * (side + gap),
               width: side, height: side)
    }

    func center(_ index: Int) -> CGPoint {
        let bounds = rect(index)
        return CGPoint(x: bounds.midX, y: bounds.midY)
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
    private let amber = Color(red: 0.86, green: 0.58, blue: 0.19)

    var body: some View {
        ZStack(alignment: .topLeading) {
            Path { line in
                for (offset, index) in store.vuoriPath.enumerated() {
                    if offset == 0 { line.move(to: layout.center(index)) }
                    else { line.addLine(to: layout.center(index)) }
                }
            }
            .stroke(amber, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .accessibilityHidden(true)

            ForEach(VuoriPuzzle.letters.indices, id: \.self) { index in
                let order = store.vuoriPath.firstIndex(of: index)
                Text(String(VuoriPuzzle.letters[index]))
                    .font(IvyType.hand(min(34, layout.side * 0.5)))
                    .foregroundStyle(IvyType.ink)
                    .frame(width: layout.side, height: layout.side)
                    .background(HandcutKey().fill(IvyType.cream))
                    .overlay(HandcutKey().stroke(order == nil ? IvyType.ink.opacity(0.65) : amber,
                                                lineWidth: order == nil ? 1 : 2.5))
                    .position(layout.center(index))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(String(VuoriPuzzle.letters[index]).uppercased())
                    .accessibilityValue(order.map { "Selected, \($0 + 1) of \(store.vuoriPath.count)" } ?? "Not selected")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier("vuori-letter-\(index)")
                    .accessibilityAction {
                        store.connectVuoriLetter(index)
                    }
            }
        }
        .frame(width: layout.extent, height: layout.extent)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { trace(to: $0.location, start: $0.startLocation) }
            .onEnded {
                trace(to: $0.location, start: $0.startLocation)
                previousPoint = nil
                lastVisited = nil
                store.finishVuoriConnection()
            })
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Letter connections")
        .accessibilityAction(named: "Finish connection") { store.finishVuoriConnection() }
    }

    private func trace(to point: CGPoint, start: CGPoint) {
        if previousPoint == nil { store.beginVuoriConnection() }
        for index in layout.crossedIndices(from: previousPoint ?? start, to: point) where index != lastVisited {
            store.connectVuoriLetter(index)
            lastVisited = index
        }
        previousPoint = point
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
