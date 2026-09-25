import SwiftUI

/// Authored sealed and open letter scenes share the root content viewport.
struct RulesEnvelopeView: View {
    @Bindable var store: GameStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var ready = false
    @State private var closing = false

    var body: some View {
        ZStack {
            PixelCanvas(imageName: "letter-sealed", pixelArt: false) { _ in }
            PixelCanvas(imageName: "letter-first", pixelArt: false) { _ in }
                .opacity(ready && !closing ? 1 : 0)
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
                try await Task.sleep(for: .milliseconds(650))
                finishOpening()
            } catch { return }
        }
        .task(id: closing) {
            guard closing else { return }
            do {
                try await Task.sleep(for: .milliseconds(reduceMotion ? 100 : 220))
                store.dismissEnvelope()
            } catch { return }
        }
    }

    private func handleTap() {
        guard !closing else { return }
        if ready {
            withAnimation(.easeOut(duration: reduceMotion ? 0.1 : 0.2)) { closing = true }
        } else { finishOpening() }
    }

    private func finishOpening() {
        withAnimation(.easeOut(duration: reduceMotion ? 0.1 : 0.4)) {
            ready = true
        }
        store.markEnvelopeUnrolled()
    }
}
