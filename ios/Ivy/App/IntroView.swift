import SwiftUI
import UIKit

/// Full-screen first run: one vine writes the tap line, then a tap cuts to the yard.
struct IntroView: View {
    /// Leave the card for the first playable room.
    var onEnter: () -> Void
    /// Freeze on the finished sentence and skip the blink.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// 0 is bare night; 1...`GameCanvas.introFrames` crop `intro-spread-sheet`.
    @State private var ivyFrame = 0
    /// Ping-pong 0...3 on `intro-star-sheet`. Starts on a mid-bright night.
    @State private var starFrame = 1
    /// True once the sentence has formed (or was skipped there).
    @State private var showPrompt = false
    /// Pulse the living sentence until tap.
    @State private var tapBlink = true
    /// Guards a double-tap through into the yard.
    @State private var didEnter = false

    var body: some View {
        ZStack {
            Color("Night")
                .ignoresSafeArea()
            PixelCanvas(imageName: "intro-spread-base", canvasSize: GameCanvas.introSize) { scale in
                let size = CGSize(
                    width: GameCanvas.introSize.width * scale,
                    height: GameCanvas.introSize.height * scale
                )
                ZStack(alignment: .topLeading) {
                    PixelSpriteFrame(sheet: .introStars, index: starFrame, scale: scale)
                        .allowsHitTesting(false)
                    if ivyFrame > 0 {
                        PixelSpriteFrame(sheet: .introSpread, index: ivyFrame - 1, scale: scale)
                            .opacity(showPrompt && !tapBlink ? 0.72 : 1)
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: size.width, height: size.height)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: handleTap)
        .statusBarHidden(true)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(GameCopy.introTitle)
        .accessibilityHint(showPrompt ? GameCopy.introEnter : "Skip to the start prompt")
        .task {
            await runIntro()
        }
        .task {
            await twinkleStars()
        }
        .task(id: showPrompt) {
            await blinkTapLine()
        }
    }

    /// One vine writes the line, then holds until tap.
    private func runIntro() async {
        warmPlates()
        if reduceMotion {
            skipToPrompt()
            return
        }
        for frame in 1...GameCanvas.introFrames {
            if didEnter || showPrompt { return }
            ivyFrame = frame
            try? await Task.sleep(for: .milliseconds(GameCanvas.introFrameMilliseconds))
        }
        showPrompt = true
    }

    /// Decode intro beats and the first room so cuts are frames, not hitches.
    private func warmPlates() {
        SpriteAtlas.warm(
            "intro-spread-base",
            SpriteSheet.introSpread.imageName,
            SpriteSheet.introStars.imageName,
            "story-yard-base",
            "story-cloud",
            SpriteSheet.storyVine.imageName
        )
    }

    /// Hold on the finished vine sentence.
    private func skipToPrompt() {
        ivyFrame = GameCanvas.introFrames
        showPrompt = true
        tapBlink = true
    }

    /// Yard-wind language: ping-pong nearest-neighbor, freeze on Reduce Motion.
    private func twinkleStars() async {
        if reduceMotion {
            starFrame = 1
            return
        }
        var direction = 1
        while !didEnter {
            try? await Task.sleep(for: .milliseconds(GameCanvas.introStarFrameMilliseconds))
            if didEnter { return }
            starFrame += direction
            if starFrame >= GameCanvas.introStarFrames - 1 {
                starFrame = GameCanvas.introStarFrames - 1
                direction = -1
            } else if starFrame <= 0 {
                starFrame = 0
                direction = 1
            }
        }
    }

    /// First tap lands on the prompt; the next tap opens the yard.
    private func handleTap() {
        if didEnter { return }
        if !showPrompt {
            skipToPrompt()
            return
        }
        enter()
    }

    /// The sentence pulses until Reduce Motion or the yard cut.
    private func blinkTapLine() async {
        guard showPrompt, !reduceMotion else {
            tapBlink = true
            return
        }
        while !didEnter {
            try? await Task.sleep(for: .milliseconds(700))
            if didEnter { return }
            tapBlink.toggle()
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
