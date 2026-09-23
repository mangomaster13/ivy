import SwiftUI

/// Meaning and presentation are independent: an interaction can also be unsuccessful.
enum IvyMessageTone: Equatable {
    case ordinary, success, wrong
}

enum IvyMessagePresentation: Equatable {
    case puzzle, interaction
}

struct IvySprig: View {
    var tone: IvyMessageTone = .ordinary
    var body: some View {
        Image("ui-ivy-sprig")
            .resizable().interpolation(.high).scaledToFit()
            .hueRotation(.degrees(tone == .wrong ? -65 : 0))
            .saturation(tone == .wrong ? 1.45 : 1)
            .brightness(tone == .success ? 0.18 : (tone == .wrong ? 0.08 : 0))
            .accessibilityHidden(true)
    }
}

/// Intrinsic-width interaction dialogue. Only the background is translucent.
struct IvyMessage: View {
    let text: String
    var tone: IvyMessageTone = .ordinary

    var body: some View {
        ViewThatFits(in: .horizontal) {
            label(singleLine: true)
            label(singleLine: false)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private func label(singleLine: Bool) -> some View {
        HStack(spacing: 9) {
            IvySprig(tone: tone).frame(width: 30, height: 20)
            Text(text).font(IvyType.hand(21)).foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: singleLine, vertical: true)
        }
    }
}

/// Quiet level subtitles; mistakes use the game's warm ochre warning accent.
struct PuzzleFeedbackText: View {
    let text: String
    var tone: IvyMessageTone = .ordinary
    private var isWarning: Bool { tone == .wrong && !text.isEmpty }
    private let warning = Color(red: 0.96, green: 0.73, blue: 0.36)

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if isWarning {
                Text("!").font(IvyType.hand(24))
                    .accessibilityHidden(true)
            }
            Text(text).font(IvyType.hand(20))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(isWarning ? warning : .white)
        .shadow(color: .black.opacity(0.95), radius: 2, y: 1)
        .offset(y: isWarning ? -10 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityValue(isWarning ? "Try again" : "")
        .accessibilityHidden(text.isEmpty)
    }
}

/// A reserved bottom slot prevents feedback from moving the puzzle controls.
struct SceneFeedback: View {
    let store: GameStore
    var height: CGFloat = 52
    private var perfumeArtwork: String? {
        guard store.room == .perfume else { return nil }
        switch store.sceneHint {
        case "Something feels out of place.": return "ll4-feedback-mixture"
        case "We've bottled this one already.": return "ll4-feedback-duplicate"
        default: return nil
        }
    }
    var body: some View {
        ZStack {
            if !store.sceneHint.isEmpty {
                if let perfumeArtwork {
                    Image(perfumeArtwork).resizable().scaledToFit()
                        .frame(maxWidth: 350).frame(height: min(30, height))
                        .shadow(color: .black.opacity(0.9), radius: 2, y: 1)
                        .accessibilityLabel(store.sceneHint)
                } else if store.sceneHintPresentation == .interaction {
                    IvyMessage(text: store.sceneHint, tone: store.sceneHintTone)
                        .accessibilityAction(.escape) { store.dismissSceneHint() }
                } else {
                    PuzzleFeedbackText(text: store.sceneHint, tone: store.sceneHintTone)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .accessibilityHidden(store.sceneHint.isEmpty)
    }
}
