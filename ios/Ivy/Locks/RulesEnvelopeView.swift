import SwiftUI

/// A real twelve-pose atlas: rolled paper opens from the center, with moving curled edges.
struct RulesEnvelopeView: View {
    @Bindable var store: GameStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frame = 0
    @State private var ready = false
    @State private var closing = false
    private var lastFrame: Int { GameCanvas.envelopeFrames - 1 }

    var body: some View {
        ZStack {
            Color("Night")
            PixelCanvas(imageName: store.yardImageName, pixelArt: false) { scale in
                ZStack {
                    Color("Night").opacity(0.8)
                    letter(scale: scale)
                }
                .frame(width: GameCanvas.width * scale, height: GameCanvas.height * scale)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: handleTap)
        .statusBarHidden(true)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(ready ? GameCopy.rulesEnvelope : "A letter for you")
        .accessibilityHint(ready ? "Tap to return to the yard" : "Tap to open the letter")
        .accessibilityAction { handleTap() }
        .task(id: "\(store.envelopePlayID)-\(reduceMotion)") {
            if store.envelopeDidUnroll || reduceMotion {
                finishOpening()
                return
            }
            do {
                for index in 0...lastFrame {
                    guard !ready else { return }
                    frame = index
                    try await Task.sleep(for: .milliseconds(index == 0 ? 450 : GameCanvas.envelopeFrameMilliseconds))
                }
                finishOpening()
            } catch { return }
        }
        .task(id: closing) {
            guard closing else { return }
            do {
                try await Task.sleep(for: .milliseconds(reduceMotion ? 100 : 220))
                if !reduceMotion {
                    for index in stride(from: lastFrame, through: 0, by: -1) {
                        frame = index
                        try await Task.sleep(for: .milliseconds(90))
                    }
                }
                store.dismissEnvelope()
            } catch { return }
        }
        .onDisappear { SpriteAtlas.release(.letterScroll) }
    }

    private func letter(scale: CGFloat) -> some View {
        ZStack {
            PixelSpriteFrame(sheet: .letterScroll, index: frame, scale: scale / 2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2 * scale) {
                IvyType.inscription(GameCopy.letterTitle)
                    .font(IvyType.script(11 * scale))
                    .frame(height: 14 * scale)
                    .padding(.bottom, 2 * scale)
                ForEach(GameCopy.letterStanzas, id: \.self) { stanza in
                    handwrittenLines(stanza, scale: scale)
                }
                handwrittenLines(GameCopy.letterSignature, scale: scale)
                    .padding(.top, 1 * scale)
            }
            .multilineTextAlignment(.leading)
            .foregroundStyle(IvyType.ink)
            .frame(width: 150 * scale, alignment: .leading)
            .offset(x: 4 * scale, y: -5 * scale)
            .opacity(ready && !closing ? 1 : 0)
            IvyType.inscription("AUG")
                .font(IvyType.script(7 * scale))
                .foregroundStyle(IvyType.ink.opacity(0.25))
                .rotationEffect(.degrees(-9))
                .offset(x: 77 * scale, y: -59 * scale)
                .opacity(ready && !closing ? 1 : 0)
            IvyType.inscription(GameCopy.letterClose)
                .font(IvyType.script(7 * scale))
                .foregroundStyle(IvyType.ink.opacity(0.65))
                .offset(y: 62 * scale)
                .opacity(ready && !closing ? 1 : 0)
        }
    }

    // Use explicit line rhythm so handwritten font metrics do not push this letter off the paper.
    private func handwrittenLines(_ text: String, scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(text.components(separatedBy: "\n"), id: \.self) { line in
                IvyType.inscription(line)
                    .font(IvyType.script(7.2 * scale))
                    .fixedSize()
                    .frame(height: 8 * scale)
            }
        }
    }

    private func handleTap() {
        guard !closing else { return }
        if ready {
            withAnimation(.easeOut(duration: reduceMotion ? 0.1 : 0.2)) { closing = true }
        } else { finishOpening() }
    }

    private func finishOpening() {
        frame = lastFrame
        withAnimation(.easeOut(duration: reduceMotion ? 0.1 : 0.4)) {
            ready = true
        }
        store.markEnvelopeUnrolled()
    }
}
