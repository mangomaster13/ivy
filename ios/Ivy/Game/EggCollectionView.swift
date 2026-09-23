import SwiftUI

/// Inventory supplies real slot bounds, so the flight works on every iPhone width.
struct EggSlotAnchors: PreferenceKey {
    static var defaultValue: [EggId: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [EggId: Anchor<CGRect>], nextValue: () -> [EggId: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

/// Only foreground art: the current scene stays visible at its original brightness.
struct EggCollectionView: View {
    let egg: EggId
    let target: CGPoint
    let stageSize: CGSize
    let trayTop: CGFloat
    var isReplay = false
    let onLanded: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed: CGFloat = 0
    @State private var flight: CGFloat = 0

    private var origin: CGPoint { CGPoint(x: stageSize.width / 2, y: trayTop * 0.46) }
    private var effectSize: CGFloat { min(220, max(0, trayTop - 24)) }
    private var objectSize: CGFloat { effectSize * 0.57 }
    private var decorationsOpacity: Double { Double(revealed * (1 - flight)) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image("keepsake-tap-sprigs")
                .resizable().interpolation(.high).scaledToFit()
                .frame(width: effectSize, height: effectSize)
                .scaleEffect(reduceMotion ? 1 : 0.88 + 0.12 * revealed)
                .opacity(decorationsOpacity)
                .position(origin)

            ForEach(0..<5) { index in
                KeepsakeSparkle()
                    .fill(Color(red: 1, green: 0.79, blue: 0.39))
                    .overlay {
                        KeepsakeSparkle().stroke(IvyType.cream, lineWidth: 0.65)
                    }
                    .frame(width: index.isMultiple(of: 2) ? 7 : 5,
                           height: index.isMultiple(of: 2) ? 11 : 8)
                    .scaleEffect(reduceMotion ? 1 : 0.45 + 0.55 * revealed)
                    .opacity(decorationsOpacity)
                    .position(sparklePosition(index))
            }

            MemoryObjectArtwork(image: egg.iconName)
                .frame(width: objectSize + (36 - objectSize) * flight,
                       height: objectSize + (36 - objectSize) * flight)
                .scaleEffect(reduceMotion ? 1 : 0.9 + 0.1 * revealed)
                .rotationEffect(.degrees(reduceMotion ? 0 : Double((1 - revealed) * -6)))
                .opacity(Double(revealed))
                .modifier(CollectionArc(from: origin, to: target, progress: flight))
        }
        .frame(width: stageSize.width, height: stageSize.height)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isReplay ? "Keepsake" : "Collected") \(egg.rawValue)")
        .task {
            do {
                withAnimation(.easeOut(duration: reduceMotion ? 0.12 : 0.32)) { revealed = 1 }
                try await Task.sleep(for: .milliseconds(isReplay ? 850 : 1150))
                if reduceMotion || isReplay {
                    withAnimation(.easeOut(duration: 0.18)) { revealed = 0 }
                    try await Task.sleep(for: .milliseconds(200))
                } else {
                    withAnimation(.easeInOut(duration: 0.8)) { flight = 1 }
                    try await Task.sleep(for: .milliseconds(820))
                }
                try Task.checkCancellation()
                onLanded()
            } catch { return }
        }
    }

    private func sparklePosition(_ index: Int) -> CGPoint {
        let positions: [CGPoint] = [
            CGPoint(x: -0.03, y: -0.39), CGPoint(x: -0.39, y: -0.12),
            CGPoint(x: 0.38, y: -0.02), CGPoint(x: -0.33, y: 0.32),
            CGPoint(x: 0.31, y: 0.39)
        ]
        let spread: CGFloat = reduceMotion ? 1 : 0.85 + 0.15 * revealed
        return CGPoint(x: origin.x + positions[index].x * effectSize * spread,
                       y: origin.y + positions[index].y * effectSize * spread)
    }
}

/// Tiny native sparkles remain crisp without adding a luminous background surface.
struct KeepsakeSparkle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let points: [CGPoint] = [
            CGPoint(x: 0.5, y: 0), CGPoint(x: 0.63, y: 0.37),
            CGPoint(x: 1, y: 0.5), CGPoint(x: 0.63, y: 0.63),
            CGPoint(x: 0.5, y: 1), CGPoint(x: 0.37, y: 0.63),
            CGPoint(x: 0, y: 0.5), CGPoint(x: 0.37, y: 0.37)
        ]
        path.addLines(points.map { CGPoint(x: rect.minX + $0.x * rect.width,
                                          y: rect.minY + $0.y * rect.height) })
        path.closeSubpath()
        return path
    }
}

private struct CollectionArc: AnimatableModifier {
    let from: CGPoint
    let to: CGPoint
    nonisolated var progress: CGFloat
    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    func body(content: Content) -> some View {
        content.position(
            x: from.x + (to.x - from.x) * progress,
            y: from.y + (to.y - from.y) * progress - sin(.pi * progress) * 40
        )
    }
}
