// xcode: set sdk=iOS

import SwiftUI

/// Press style: 1 game-pixel bright edge, no ripple, no scale bounce on the room.
struct PixelPressStyle: ButtonStyle {
    /// Canvas nearest-neighbor scale; stroke width tracks one game pixel.
    var scale: CGFloat = 2

    /// Wraps the hotspot label with a press-only white edge.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                Rectangle()
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.9 : 0), lineWidth: max(1, scale / 3))
            }
            .contentShape(Rectangle())
    }
}

/// Invisible hit target in 320×160 space, at least 44pt on device.
struct HotspotButton: View {
    /// Rectangle in game pixels.
    let rect: CGRect
    /// Shared canvas scale.
    let scale: CGFloat
    /// Optional idle glow (door nudge).
    var glow: Double = 0
    /// VoiceOver name.
    let label: String
    /// Fire on tap.
    let action: () -> Void

    var body: some View {
        let drawW = rect.width * scale
        let drawH = rect.height * scale
        let hitW = max(44, drawW)
        let hitH = max(44, drawH)
        Button(action: action) {
            Rectangle()
                .fill(Color.clear)
                .overlay {
                    Rectangle()
                        .stroke(Color.white.opacity(glow * 0.85), lineWidth: max(1, scale / 3))
                }
        }
        .buttonStyle(PixelPressStyle(scale: scale))
        .frame(width: hitW, height: hitH)
        .position(
            x: rect.midX * scale,
            y: rect.midY * scale
        )
        .accessibilityLabel(label)
    }
}

/// Stone plaque with ivy at the corners. Tap anywhere on it to dismiss.
struct DialogueBox: View {
    /// Spoken line.
    let line: String
    /// Dismiss handler.
    let onDismiss: () -> Void

    /// Protects the ivy clumps when the plaque stretches to the line length.
    private static let cap = EdgeInsets(top: 16, leading: 22, bottom: 16, trailing: 20)

    var body: some View {
        Button(action: onDismiss) {
            Text(line)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color(red: 58 / 255, green: 52 / 255, blue: 48 / 255))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                .padding(.leading, 28)
                .padding(.trailing, 24)
                .padding(.vertical, 14)
                .background {
                    Image("ui-dialogue")
                        .interpolation(.none)
                        .resizable(capInsets: Self.cap, resizingMode: .stretch)
                }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: 440)
        .accessibilityLabel(line)
        .accessibilityHint("Dismiss")
    }
}

/// Keyboard-adjacent field + confirm. Cancel sits on the left at 44pt.
struct InputChallengeView: View {
    /// Shared game store.
    @Bindable var store: GameStore
    /// Keeps the caret in the field; blank taps on the room must not steal it.
    @FocusState private var fieldFocused: Bool
    /// Reduce-motion skips the 2pt shake on the field.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(GameCopy.cancel) {
                store.cancelOverlay()
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(red: 0.82, green: 0.74, blue: 0.62))
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel(GameCopy.cancel)

            VStack(alignment: .leading, spacing: 6) {
                if store.overlay == .plaque {
                    Image("obj-plaque")
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                        .accessibilityHidden(true)
                }
                if store.overlay == .lyric, !store.lyricHint.isEmpty {
                    Text(store.lyricHint)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.82, green: 0.74, blue: 0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if store.overlay == .plaque, !store.plaqueHint.isEmpty {
                    Text(store.plaqueHint)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 0.82, green: 0.74, blue: 0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 8) {
                    textField
                    Button(GameCopy.confirm) {
                        submit()
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.18, green: 0.12, blue: 0.10))
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(Color(red: 0.93, green: 0.86, blue: 0.72))
                    .accessibilityLabel(GameCopy.confirm)
                }
            }
            .offset(x: reduceMotion ? 0 : store.worldOffsetX)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity)
        .background(Color("Night"))
        .onAppear {
            fieldFocused = true
        }
    }

    /// Lyric uses ASCII; plaque uses a decimal pad so 9.29 can be typed.
    @ViewBuilder
    private var textField: some View {
        if store.overlay == .lyric {
            TextField(GameCopy.lyricPlaceholder, text: $store.lyricDraft)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(red: 0.93, green: 0.86, blue: 0.72))
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($fieldFocused)
                .frame(minHeight: 44)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.08))
                .onSubmit { store.submitLyric() }
        } else {
            TextField(GameCopy.plaquePlaceholder, text: $store.plaqueDraft)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(red: 0.93, green: 0.86, blue: 0.72))
                .keyboardType(.decimalPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($fieldFocused)
                .frame(minHeight: 44)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.08))
        }
    }

    /// Routes confirm to the active gate.
    private func submit() {
        if store.overlay == .lyric {
            store.submitLyric()
        } else {
            store.submitPlaque()
        }
    }
}

/// Nine fixed slots. Empty slots show a navy silhouette; collected slots show the object.
struct InventoryBar: View {
    /// Shared game store.
    @Bindable var store: GameStore
    /// Reduce-motion keeps the slot tint change without the punch scale.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            ForEach(EggId.allCases) { egg in
                slot(egg)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .background(Color("Night"))
    }

    /// One 44pt hit target around a 16pt pixel square.
    private func slot(_ egg: EggId) -> some View {
        let on = store.collected.contains(egg)
        let pulsing = store.slotPulse == egg && !reduceMotion
        return Button {
            guard on else { return }
            switch egg {
            case .ivy:
                store.speakReread(GameCopy.vineHints.last ?? "")
            case .sep29:
                store.speakReread(GameCopy.plaqueReread)
            default:
                break
            }
        } label: {
            Image(on ? egg.iconName : egg.offIconName)
                .interpolation(.none)
                .resizable()
                .frame(width: 16, height: 16)
                .scaleEffect(pulsing ? 1.12 : 1)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!on)
        .accessibilityLabel(on ? "Collected \(egg.rawValue)" : "Empty slot \(egg.slotIndex + 1)")
        .animation(reduceMotion ? .easeInOut(duration: 0.1) : .snappy(duration: 0.18), value: store.slotPulse)
    }
}
