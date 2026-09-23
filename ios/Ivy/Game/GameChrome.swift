// xcode: set sdk=iOS

import SwiftUI

/// Root-owned layout budgets shared by the content viewport and inventory.
enum GameLayout {
    static let footerHeight: CGFloat = 54
    /// Keep navigation outside the fitted stage, including on narrower phones.
    static let navigationGutter: CGFloat = 64

    /// Match the scene compositor, including its physical-pixel rounding.
    static func stageSize(in available: CGSize, displayScale: CGFloat) -> CGSize {
        let scale = min(available.width / 320, available.height / 160)
        let fittedScale = max(0, floor(scale * displayScale + 0.000001)) / displayScale
        return CGSize(width: 320 * fittedScale, height: 160 * fittedScale)
    }
}

/// Pages supply their own return behavior; only the root renders the button.
struct GameBackAction {
    let perform: () -> Void
}

struct GameBackActionKey: PreferenceKey {
    static var defaultValue: GameBackAction? { nil }

    static func reduce(value: inout GameBackAction?, nextValue: () -> GameBackAction?) {
        if let next = nextValue() { value = next }
    }
}

extension View {
    func gameBackAction(_ action: @escaping () -> Void) -> some View {
        preference(key: GameBackActionKey.self, value: GameBackAction(perform: action))
    }
}

/// Notebook pagination is navigation chrome, independent of the physical page artwork.
struct GamePageNavigation {
    let canGoPrevious: Bool
    let canGoNext: Bool
    let previous: () -> Void
    let next: () -> Void
}

struct GamePageNavigationKey: PreferenceKey {
    static var defaultValue: GamePageNavigation? { nil }

    static func reduce(value: inout GamePageNavigation?, nextValue: () -> GamePageNavigation?) {
        if let next = nextValue() { value = next }
    }
}

struct GamePageNavigationControls: View {
    let navigation: GamePageNavigation

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                if navigation.canGoPrevious {
                    SceneNavigationButton(kind: .page(previous: true), label: "Previous page",
                                          action: navigation.previous)
                }
            }
            .frame(width: GameLayout.navigationGutter, height: 48)
            Spacer(minLength: 0)
            ZStack {
                if navigation.canGoNext {
                    SceneNavigationButton(kind: .page(previous: false), label: "Next page",
                                          action: navigation.next)
                }
            }
            .frame(width: GameLayout.navigationGutter, height: 48)
        }
    }
}

/// Bundled typography: Kiddos for controls and help, Juniper for in-world inscriptions.
enum IvyType {
    static let cream = Color(red: 0.96, green: 0.90, blue: 0.75)
    static let ink = Color(red: 0.06, green: 0.20, blue: 0.22)
    static func hand(_ size: CGFloat) -> Font {
        .custom("KidDos-Font", fixedSize: size)
    }
    /// Handwritten swashes can extend beyond typographic advances. Internal spaces keep that ink
    /// inside Text's raster bounds; outer view padding cannot recover already clipped ink.
    static func inscription(_ value: String) -> some View {
        let guarded = value.components(separatedBy: "\n")
            .map { "\u{2002}" + $0 + "\u{2002}" }
            .joined(separator: "\n")
        return Text(guarded).accessibilityLabel(value)
    }

    static func script(_ size: CGFloat) -> Font {
        .custom("Juniper-Regular", fixedSize: size)
    }
}

/// Press style: 1 game-pixel bright edge, no ripple, no scale bounce on the room.
struct PixelPressStyle: ButtonStyle {
    /// Canvas nearest-neighbor scale; stroke width tracks one game pixel.
    var scale: CGFloat = 2

    /// Wraps a lock tile with a press-only white edge.
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                Rectangle()
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.9 : 0), lineWidth: max(1, scale / 3))
            }
            .contentShape(Rectangle())
    }
}

/// Door glow plus VoiceOver. Hits go through to the canvas tap layer.
struct HotspotMarker: View {
    /// Rectangle in game pixels.
    let rect: CGRect
    /// Shared canvas scale.
    let scale: CGFloat
    /// Optional idle glow (door nudge).
    var glow: Double = 0
    /// VoiceOver name.
    let label: String
    /// Fire from VoiceOver; finger taps use the canvas gesture.
    let action: () -> Void

    var body: some View {
        let hitW = max(44, rect.width * scale)
        let hitH = max(44, rect.height * scale)
        Color.clear
            .frame(width: hitW, height: hitH)
            .overlay {
                Rectangle()
                    .stroke(Color.white.opacity(glow * 0.85), lineWidth: max(1, scale / 3))
            }
            .position(x: rect.midX * scale, y: rect.midY * scale)
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default, action)
    }
}

/// A dialogue has no visible dismissal controls; the surrounding scene handles taps.
struct DialogueBox: View {
    let line: String
    var tone: IvyMessageTone = .ordinary
    let onDismiss: () -> Void
    var body: some View {
        IvyMessage(text: line, tone: tone)
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .onTapGesture { } // A tap inside the panel must not hit the scene beneath it.
            .accessibilityAction(.escape, onDismiss)
            .accessibilityAction(named: "Dismiss", onDismiss)
    }
}

/// Thirteen fixed slots. Empty slots show a navy silhouette; collected slots show the object.
struct InventoryBar: View {
    /// Shared game store.
    @Bindable var store: GameStore
    /// Reduce-motion keeps the slot tint change without the punch scale.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
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

    /// One 44pt hit target around a transparent hand-painted keepsake.
    private func slot(_ egg: EggId) -> some View {
        let on = store.collected.contains(egg) && !store.collectionQueue.contains(egg)
        let pulsing = store.slotPulse == egg && !reduceMotion
        return Button {
            guard on, store.collectingEgg == nil, !store.isHallTransitioning else { return }
            store.replayKeepsake(egg)
        } label: {
            Group {
                if egg == .perfume && on {
                    FragranceBottleArtwork(tool: .gaiac10)
                } else if egg == .perfume {
                    Image("keepsake-perfume-sealed")
                        .resizable().interpolation(.high).scaledToFit()
                } else {
                    Image(egg.iconName)
                        .renderingMode(on ? .original : .template)
                        .resizable().interpolation(.high).scaledToFit()
                        .foregroundStyle(Color(red: 0.16, green: 0.24, blue: 0.27))
                }
            }
                .frame(width: egg == .keycard ? 27 : 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: egg == .keycard ? 2 : egg == .city ? 4 : 0))
                .scaleEffect(pulsing ? 1.12 : 1)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Blocking interaction must not apply the system's disabled tint to collectible art.
        .allowsHitTesting(on && store.collectingEgg == nil && !store.isHallTransitioning)
        .id(egg)
        .anchorPreference(key: EggSlotAnchors.self, value: .bounds) { [egg: $0] }
        .accessibilityLabel(on ? "Collected \(egg.rawValue)" : "Empty slot \(egg.slotIndex + 1)")
        .accessibilityIdentifier("keepsake-\(egg.rawValue)")
        .animation(reduceMotion ? .easeInOut(duration: 0.1) : .snappy(duration: 0.18), value: store.slotPulse)
    }
}
