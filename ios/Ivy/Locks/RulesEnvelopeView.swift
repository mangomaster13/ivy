import SwiftUI

struct RulesEnvelopeView: View {
    @Bindable var store: GameStore

    var body: some View {
        LetterOpeningView(
            imageName: "letter-first-paper",
            reading: GameCopy.rulesEnvelope,
            onOpened: { store.markEnvelopeUnrolled() },
            onClose: { store.dismissEnvelope() }
        )
        .statusBarHidden(true)
    }
}

/// Both letters wait for a tap, unfurl once per visit, and dismiss immediately after reading.
struct LetterOpeningView: View {
    let imageName: String
    let reading: String
    let onOpened: () -> Void
    let onClose: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var opening = false
    @State private var ready = false
    @State private var progress: CGFloat = 0

    var body: some View {
        Group {
            if opening {
                PixelCanvas(imageName: "letter-desk", pixelArt: false) { scale in
                    // 1774×887 source paper x=387...1395, y=55...808.
                    // The texture keeps its size; only the exposed band and curl positions move.
                    let centerY: CGFloat = 77.84
                    let halfHeight: CGFloat = 67.92 * progress
                    ZStack(alignment: .topLeading) {
                        Image(imageName).resizable().interpolation(.high)
                            .frame(width: 320 * scale, height: 160 * scale)
                            .mask(alignment: .topLeading) {
                                Rectangle()
                                    .frame(width: 320 * scale, height: 2 * halfHeight * scale)
                                    .position(x: 160 * scale, y: centerY * scale)
                            }
                        if !ready {
                            Image("letter-curl").resizable().interpolation(.high)
                                .frame(width: 182 * scale, height: (6 + 8 * (1 - progress)) * scale)
                                .position(x: 161 * scale, y: (centerY - halfHeight) * scale)
                            Image("letter-curl").resizable().interpolation(.high)
                                .frame(width: 182 * scale, height: (6 + 8 * (1 - progress)) * scale)
                                .scaleEffect(x: 1, y: -1)
                                .position(x: 161 * scale, y: (centerY + halfHeight) * scale)
                        }
                    }
                    .accessibilityHidden(true)
                }
            } else {
                PixelCanvas(imageName: "letter-sealed", pixelArt: false) { _ in }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: handleTap)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(ready ? reading : "A letter for you")
        .accessibilityHint(ready ? "Tap to close the letter" : "Tap to unroll the letter")
        .accessibilityAction { handleTap() }
        .task(id: opening) {
            guard opening else { return }
            if reduceMotion {
                progress = 1
            } else {
                withAnimation(.easeInOut(duration: 1.2)) { progress = 1 }
                do { try await Task.sleep(for: .milliseconds(1200)) }
                catch { return }
            }
            ready = true
            onOpened()
        }
    }

    private func handleTap() {
        if ready { onClose() }
        else if !opening { opening = true }
    }
}
