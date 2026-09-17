import SwiftUI
import UIKit

/// Title card: ivy climbs the cottage, then the yard is waiting.
struct IntroView: View {
    /// Leave the card for the first playable room.
    var onEnter: () -> Void
    /// Freeze the climb on the last frame.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 0 is the bare house; 1...4 overlay `intro-ivy-*`.
    @State private var ivyFrame = 0
    /// Guards double-enter from the timer and the button.
    @State private var didEnter = false

    var body: some View {
        GeometryReader { geo in
            let chrome: CGFloat = 92
            let scale = min(
                geo.size.width * 0.4 / 160,
                max(120, geo.size.height - chrome) / 240
            )
            ZStack {
                Color("Night")
                    .ignoresSafeArea()
                VStack(spacing: 14) {
                    Spacer(minLength: 0)
                    house(scale: scale)
                    Image("intro-title")
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 75 * 4, height: 5 * 4)
                        .accessibilityLabel(GameCopy.introTitle)
                    enterButton
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 12)
            }
        }
        .statusBarHidden(true)
        .task {
            await runIntro()
        }
    }

    /// Cottage at nearest-neighbor scale, ivy frames stacked 1:1.
    private func house(scale: CGFloat) -> some View {
        ZStack {
            Image("intro-house")
                .interpolation(.none)
                .resizable()
            if ivyFrame > 0 {
                Image("intro-ivy-\(ivyFrame)")
                    .interpolation(.none)
                    .resizable()
            }
        }
        .frame(width: 160 * scale, height: 240 * scale)
        .accessibilityHidden(true)
    }

    /// 44pt hit around the pixel ENTER plate. Available the whole 2s.
    private var enterButton: some View {
        Button(action: enter) {
            Image("ui-enter")
                .interpolation(.none)
                .resizable()
                .frame(width: 35 * 3, height: 13 * 3)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(PixelPressStyle(scale: 3))
        .accessibilityLabel(GameCopy.introEnter)
        .accessibilityHint("Opens the yard")
    }

    /// Climb in 1s, hold 1s; Reduce Motion keeps the last frame for the full 2s.
    private func runIntro() async {
        warmYardPlates()
        if reduceMotion {
            ivyFrame = 4
            try? await Task.sleep(for: .seconds(2))
        } else {
            for frame in 1...4 {
                try? await Task.sleep(for: .milliseconds(250))
                if didEnter { return }
                ivyFrame = frame
            }
            try? await Task.sleep(for: .seconds(1))
        }
        if !didEnter {
            enter()
        }
    }

    /// Decode the first room while the card is up so the cut is a frame, not a hitch.
    private func warmYardPlates() {
        for name in ["yard-base", "yard-cloud", "sky-lyric", "ivy-left-0-0", "ivy-right-0-0"] {
            _ = UIImage(named: name)
        }
    }

    /// One-shot dismiss.
    private func enter() {
        guard !didEnter else { return }
        didEnter = true
        IvyHaptics.light()
        onEnter()
    }
}

#Preview {
    IntroView(onEnter: {})
}
