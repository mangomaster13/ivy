import SwiftUI

/// Interactive object bounds in the illustrated 320×160 hall.
enum HallLayout {
    static let garment = CGRect(x: 94, y: 43, width: 40, height: 40)
    static let machine = CGRect(x: 244, y: 57, width: 54, height: 52)
}

struct HallAtmosphere: View {
    @Bindable var store: GameStore
    let scale: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.18, paused: reduceMotion || phase != .active)) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            ZStack(alignment: .topLeading) {
                Image("memory-shirt-final").resizable().interpolation(.high)
                    .frame(width: HallLayout.garment.width * scale, height: HallLayout.garment.height * scale)
                    .rotationEffect(.degrees(reduceMotion ? 0 : sin(t * 0.7) * 1.5), anchor: .top)
                    .position(x: HallLayout.garment.midX * scale, y: HallLayout.garment.midY * scale)
                // Small warm flicker inside the painted fireplace, never a flashing full-screen light.
                Ellipse().fill(Color.orange.opacity(0.06 + (sin(t * 2.4) + 1) * 0.025))
                    .frame(width: 42 * scale, height: 24 * scale)
                    .position(x: 190 * scale, y: 89 * scale)
                if store.lotteryReady {
                    RoundedRectangle(cornerRadius: scale)
                        .fill(IvyType.cream.opacity(0.86))
                        .frame(width: 16 * scale, height: 7 * scale)
                        .position(x: 262 * scale, y: 71 * scale)
                    Text(store.lotteryDrawn ? "♡" : "13")
                        .font(IvyType.hand(6 * scale))
                        .foregroundStyle(IvyType.ink)
                        .position(x: 262 * scale, y: 71 * scale)
                    ForEach(0..<3) { index in
                        Circle().fill(IvyType.cream.opacity(reduceMotion ? 0.8 : 0.65 + sin(t + Double(index)) * 0.2))
                            .frame(width: 1.5 * scale, height: 1.5 * scale)
                            .position(x: CGFloat(255 + index * 7) * scale, y: 63 * scale)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct HallPrizeView: View {
    @Bindable var store: GameStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frame = 0
    var body: some View {
        GeometryReader { proxy in
            let scale = min((proxy.size.width - 48) / 448, (proxy.size.height - 24) / 300)
            ZStack {
                Color("Night")
                PixelSpriteFrame(sheet: .letterScroll, index: frame, scale: scale)
                if frame == GameCanvas.envelopeFrames - 1 {
                    VStack(spacing: 10 * scale) {
                        IvyType.inscription("one more day, with you")
                            .font(IvyType.script(22 * scale))
                        IvyType.inscription("a day for just the two of us.\nno plans to keep, no hurry home.\ni'll take care of the little things.")
                            .font(IvyType.script(16 * scale)).multilineTextAlignment(.center)
                    }
                    .foregroundStyle(IvyType.ink).padding(24).transition(.opacity)
                }
            }.frame(width: proxy.size.width, height: proxy.size.height)
        }
        .gameBackAction(store.cancelOverlay)
        .task {
            if reduceMotion { frame = GameCanvas.envelopeFrames - 1; return }
            do {
                for next in 0..<GameCanvas.envelopeFrames {
                    frame = next
                    try await Task.sleep(for: .milliseconds(180))
                }
            } catch { return }
        }
    }
}
