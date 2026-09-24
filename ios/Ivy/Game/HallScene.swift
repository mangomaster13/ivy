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
    @Environment(\.scenePhase) private var scenePhase
    @State private var revealFrame = 0
    @State private var activeEgg: EggId?
    @State private var revealTask: Task<Void, Never>?
    @State private var justPulled = false
    @State private var letterOpen = false
    @State private var letterFrame = 0
    @State private var unrollLetter = false

    var body: some View {
        Group {
            if letterOpen { letterContent }
            else { machineContent }
        }
        .gameBackAction {
            if letterOpen { letterOpen = false }
            else { store.cancelOverlay() }
        }
        .task(id: letterOpen) {
            guard letterOpen, unrollLetter else { return }
            do {
                for next in 0..<GameCanvas.envelopeFrames {
                    letterFrame = next
                    try await Task.sleep(for: .milliseconds(180))
                }
            } catch { return }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active, store.lotteryDrawn {
                revealTask?.cancel()
                activeEgg = nil
                revealFrame = 4
            }
        }
        .onDisappear { revealTask?.cancel() }
    }

    private var machineImageName: String {
        if !store.lotteryDrawn { return "lottery-machine-idle" }
        switch revealFrame {
        case 1: "lottery-machine-lever"
        case 2: "lottery-machine-envelope-half"
        case 3: "lottery-machine-envelope-full"
        default: "lottery-machine-heart"
        }
    }

    private var machineContent: some View {
        PixelCanvas(imageName: machineImageName, pixelArt: false) { scale in
            if let activeEgg {
                Image("lottery-token-\(activeEgg.rawValue)")
                    .resizable().interpolation(.high)
                    .frame(width: 33 * scale, height: 25 * scale)
                    .position(x: 173 * scale, y: 61 * scale)
                    .accessibilityHidden(true)
            }
            if !store.lotteryDrawn {
                Button(action: pullLever) {
                    Color.clear.frame(width: 50 * scale, height: 82 * scale)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: 262 * scale, y: 60 * scale)
                .accessibilityLabel("Pull the keepsake machine lever")
                .accessibilityHint("Tap or drag the lever down")
                .simultaneousGesture(
                    DragGesture(minimumDistance: 12)
                        .onEnded { if $0.translation.height > 24 * scale { pullLever() } }
                )
            }
            if store.lotteryDrawn, revealFrame == 0 || revealFrame >= 3 {
                Button(action: openLetter) {
                    Color.clear.frame(width: 68 * scale, height: 46 * scale)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: 167 * scale, y: 94 * scale)
                .accessibilityLabel("Open the letter from the machine")
            }
        }
        .id(machineImageName)
        .transition(.opacity)
    }

    private func pullLever() {
        guard store.pullLottery() else { return }
        justPulled = true
        revealFrame = 1
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.18)) { revealFrame = 4 }
            return
        }
        revealTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(400))
                for egg in EggId.allCases {
                    activeEgg = egg
                    try await Task.sleep(for: .milliseconds(290))
                }
                activeEgg = nil
                revealFrame = 2
                try await Task.sleep(for: .milliseconds(250))
                revealFrame = 3
                try await Task.sleep(for: .milliseconds(250))
                revealFrame = 4
            } catch { return }
        }
    }

    private func openLetter() {
        unrollLetter = justPulled && !reduceMotion
        letterFrame = unrollLetter ? 0 : GameCanvas.envelopeFrames - 1
        justPulled = false
        letterOpen = true
    }

    private var letterContent: some View {
        GeometryReader { proxy in
            let scale = min((proxy.size.width - 48) / 448, (proxy.size.height - 24) / 300)
            ZStack {
                Color("Night")
                PixelSpriteFrame(sheet: .letterScroll, index: letterFrame, scale: scale)
                if letterFrame == GameCanvas.envelopeFrames - 1 {
                    VStack(spacing: 10 * scale) {
                        IvyType.inscription("one more day, with you")
                            .font(IvyType.script(22 * scale))
                        IvyType.inscription("a day for just the two of us.\nno plans to keep, no hurry home.\ni'll take care of the little things.")
                            .font(IvyType.script(16 * scale)).multilineTextAlignment(.center)
                        IvyType.inscription("Love always leads me home—to you.")
                            .font(IvyType.script(16 * scale))
                    }
                    .foregroundStyle(IvyType.ink).padding(24).transition(.opacity)
                }
            }.frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
