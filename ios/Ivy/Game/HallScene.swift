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
    @State private var letterOpen = false

    var body: some View {
        Group {
            if letterOpen { letterContent }
            else { machineContent }
        }
        .gameBackAction {
            if letterOpen { letterOpen = false }
            else { store.cancelOverlay() }
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
                    .position(x: 164 * scale, y: 68 * scale)
                    .accessibilityHidden(true)
            }
            if !store.lotteryDrawn {
                Button(action: pullLever) {
                    Color.clear.frame(width: 50 * scale, height: 82 * scale)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .position(x: 245 * scale, y: 57 * scale)
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
                .position(x: 162 * scale, y: 99 * scale)
                .accessibilityLabel("Open the letter from the machine")
            }
        }
        .id(machineImageName)
        .transition(.opacity)
    }

    private func pullLever() {
        guard store.pullLottery() else { return }
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
        letterOpen = true
    }

    private var letterContent: some View {
        LetterOpeningView(
            imageName: "letter-finale-paper",
            reading: "One day, then forever. I’ve loved these days with you. I want all the ordinary ones ahead. One day, then another—until we call it forever. Love always leads me home—to you.",
            onOpened: {},
            onClose: { letterOpen = false }
        )
    }
}
