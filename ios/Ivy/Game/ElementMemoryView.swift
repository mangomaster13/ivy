import SwiftUI

/// A memory is a single presentation, distinct from a short in-world dialogue.
struct ElementMemoryView: View {
    @Bindable var store: GameStore
    let image: String
    let title: String
    let line: String
    let back: () -> Void
    var onObjectTap: (() -> Void)? = nil
    var decorated = true
    var startsDefocused = false
    @State private var progress: CGFloat = 0
    @State private var closing = false

    private var duration: Double { store.prefersReducedMotion ? 0.12 : 0.32 }

    var body: some View {
        KeepsakeSheet(back: dismiss, surface: .defocusedScene(store.roomImageName), focusProgress: startsDefocused ? 1 : progress) {
            ElementMemoryComposition(store: store, image: image, title: title, line: line,
                                     progress: progress, decorated: decorated, onObjectTap: onObjectTap)
                .background(Color.clear.contentShape(Rectangle()).onTapGesture(perform: dismiss))
            .allowsHitTesting(!closing)
        }
        .accessibilityAction(.escape, dismiss)
        .accessibilityAction(named: "Dismiss", dismiss)
        .task(id: image) {
            progress = 0
            await Task.yield()
            guard !Task.isCancelled, !closing else { return }
            withAnimation(.easeOut(duration: duration)) { progress = 1 }
        }
        .task(id: closing) {
            guard closing else { return }
            withAnimation(.easeInOut(duration: duration)) { progress = 0 }
            do {
                try await Task.sleep(for: .seconds(duration))
                try Task.checkCancellation()
                back()
            } catch { }
        }
    }

    private func dismiss() { if !closing { closing = true } }

}

/// Both puzzle completion and reopening use this exact left-object/right-memory layout.
struct ElementMemoryComposition: View {
    let store: GameStore
    let image: String
    let title: String
    let line: String
    let progress: CGFloat
    var decorated = true
    var assembly = false
    var petals: Set<Int>? = nil
    var onObjectTap: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let pictureWidth = (width - 24) * 0.44
            let finalWidth = pictureWidth * (decorated ? 0.76 : 1)
            let finalHeight = height * (decorated ? 0.612 : 0.82)
            let startHeight = min(330, height * 0.96)
            let movement = assembly ? progress : 1
            ZStack {
                if decorated {
                    ElementSprigs(reduceMotion: store.prefersReducedMotion)
                        .frame(width: min(pictureWidth, height), height: min(pictureWidth, height))
                        .position(x: pictureWidth / 2, y: height / 2)
                        .opacity(Double(progress)).allowsHitTesting(false).accessibilityHidden(true)
                }
                Group {
                    if let petals { RoseFlower(petals: petals) }
                    else { MemoryObjectArtwork(image: image) }
                }
                .frame(width: assembly ? startHeight * RoseArtwork.aspect * (1 - movement) + finalWidth * movement : finalWidth,
                       height: assembly ? startHeight * (1 - movement) + finalHeight * movement : finalHeight)
                .contentShape(Rectangle())
                .onTapGesture { onObjectTap?() }
                .accessibilityAddTraits(onObjectTap == nil ? [] : .isButton)
                .accessibilityAction { onObjectTap?() }
                .opacity(assembly ? 1 : Double(progress))
                .scaleEffect(assembly || store.prefersReducedMotion ? 1 : 0.94 + progress * 0.06)
                .position(x: assembly ? width / 2 * (1 - movement) + pictureWidth / 2 * movement : pictureWidth / 2,
                          y: height / 2)
                .transaction { if assembly && store.prefersReducedMotion { $0.animation = nil } }
                Group {
                    if image == "ll-perfume-trio" {
                        VStack(alignment: .leading, spacing: 16) {
                            Image("ll4-memory-title").resizable().scaledToFit()
                                .frame(height: 34, alignment: .leading)
                            Image("ll4-memory-body").resizable().scaledToFit()
                                .frame(maxHeight: height * 0.68, alignment: .leading)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(title + ". " + line)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            IvyType.inscription(title).font(IvyType.script(27))
                            Text(line).font(IvyType.hand(22)).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .foregroundStyle(IvyType.cream)
                .shadow(color: .black.opacity(0.55), radius: 3, y: 1)
                .frame(width: width - pictureWidth - 24, alignment: .leading)
                .opacity(Double(progress))
                .offset(x: store.prefersReducedMotion ? 0 : 12 * (1 - progress))
                .position(x: pictureWidth + 24 + (width - pictureWidth - 24) / 2, y: height / 2)
                .allowsHitTesting(progress > 0)
                .accessibilityHidden(progress == 0)
                .onTapGesture { }
            }
        }
    }
}

/// The approved transparent sprigs and sparkle shape are shared with first collection.
private struct ElementSprigs: View {
    let reduceMotion: Bool
    @State private var bright = false
    private let stars: [CGPoint] = [
        CGPoint(x: 0.47, y: 0.09), CGPoint(x: 0.11, y: 0.38),
        CGPoint(x: 0.88, y: 0.48), CGPoint(x: 0.17, y: 0.82), CGPoint(x: 0.81, y: 0.89)
    ]
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("keepsake-tap-sprigs").resizable().interpolation(.high).scaledToFit()
                ForEach(stars.indices, id: \.self) { index in
                    KeepsakeSparkle()
                        .fill(Color(red: 1, green: 0.79, blue: 0.39))
                        .overlay(KeepsakeSparkle().stroke(IvyType.cream, lineWidth: 0.65))
                        .frame(width: index.isMultiple(of: 2) ? 7 : 5, height: index.isMultiple(of: 2) ? 11 : 8)
                        .opacity(reduceMotion ? 0.9 : (bright == index.isMultiple(of: 2) ? 1 : 0.4))
                        .position(x: geometry.size.width * stars[index].x, y: geometry.size.height * stars[index].y)
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { bright = true }
        }
    }
}

extension EggId {
    var memoryImage: String {
        switch self {
        case .keycard: "sheraton-keycard"
        case .rose: "rose-bouquet"
        case .city: "city-jigsaw-master"
        default: iconName
        }
    }
    var memoryTitle: String {
        switch self {
        case .letter: "A letter for you"
        case .vuori: "Vuori"
        case .plane: "Honeyweek"
        case .keycard: "Causeway Bay"
        case .city: "Hong Kong"
        case .rose: "As a whole"
        case .gelato: "White Loquat & Jasmine"
        case .noodle: "Big Top"
        case .perfume: "Le Labo"
        case .cinema: "Cinema"
        case .dictionary: "Dictionary"
        case .ferris: "Above the city"
        case .taxi: "Stay"
        }
    }
    var memoryLine: String {
        switch self {
        case .letter: GameCopy.letterMemory
        case .vuori: "Same store, same brand. Somehow, your Tenet theory became our love story."
        case .plane: "Four days of honeymoon. We rounded up to a week."
        case .keycard: "A room by the sea. A night just for us."
        case .city: "A city walk, a thousand lights, and you beside me."
        case .rose: "Surprise! These roses are for hugging."
        case .gelato: "White loquat and jasmine. Your review was much less elegant."
        case .noodle: "Half a goose, rice, noodles, lemon tea, and Ovaltine. We ordered well."
        case .perfume: "Gaiac 10, Bergamote 22, Mousse de Chene 30. Our little collection, one bottle at a time."
        case .cinema: "I forgot the plot. I remember your arms around me."
        case .dictionary: "Some words belong in our story."
        case .ferris: "A melody below. The harbour above. A little piece of this evening, sent with love."
        case .taxi: "The ride had to end. I wasn't ready to say goodbye."
        }
    }
}

/// Code acceptance produces the card; taking it commits ownership and opens the door.
struct KeycardPickupView: View {
    @Bindable var store: GameStore
    @State private var landed = false
    var body: some View {
        if store.collected.contains(.keycard) && store.collectingEgg == nil {
            ElementMemoryView(store: store, image: "sheraton-keycard", title: EggId.keycard.memoryTitle,
                              line: EggId.keycard.memoryLine, back: store.backFromMemory)
        } else {
            KeepsakeSheet(back: store.backFromMemory, surface: .defocusedScene("hk-corridor-empty")) {
                GeometryReader { geometry in
                    let height = min(235, geometry.size.height * 0.79)
                    ZStack {
                        // A narrow physical brass dispensing slot and lip, not a UI panel.
                        RoundedRectangle(cornerRadius: 3).fill(IvyType.ink)
                            .frame(width: height * 0.84, height: 9)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(red: 0.62, green: 0.49, blue: 0.29), lineWidth: 3))
                            .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.09)
                        if !store.collected.contains(.keycard) {
                            Button { store.collectPhysical(.keycard) } label: {
                                MemoryObjectArtwork(image: "sheraton-keycard")
                                    .frame(width: height * 0.75, height: height)
                                    .shadow(color: .black.opacity(0.35), radius: 5, y: 4)
                            }.buttonStyle(.plain)
                                .accessibilityLabel("Collect room card")
                                .rotationEffect(.degrees(store.prefersReducedMotion || landed ? 0 : -5))
                                .offset(y: store.prefersReducedMotion || landed ? 0 : -height * 0.3)
                                .opacity(landed ? 1 : 0)
                                .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.54)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .onAppear {
                let shouldDrop = store.keycardJustDispensed
                store.keycardJustDispensed = false
                withAnimation(shouldDrop ? (store.prefersReducedMotion ? .linear(duration: 0.12) : .spring(response: 0.55, dampingFraction: 0.7)) : nil) {
                    landed = true
                }
            }
        }
    }
}

/// Native silhouette follows the physical paper; image pixels and UI stay independent.
struct MemoryObjectArtwork: View {
    let image: String
    var body: some View {
        if image == "ll-perfume-trio" {
            PerfumeTrioArtwork()
        } else if image == "memory-yunnan-postcard" {
            Image(image).resizable().interpolation(.high)
                .aspectRatio(1.5, contentMode: .fit)
                .clipShape(PostcardSilhouette())
        } else if image == "city-jigsaw-master" {
            Image(image).resizable().interpolation(.high)
                .aspectRatio(1, contentMode: .fit)
                .background(IvyType.ink)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        } else if image == "rose-bouquet" {
            RoseFlower(petals: Set(0..<3))
        } else if image == "sheraton-keycard" {
            GeometryReader { geometry in
                let height = min(geometry.size.height, geometry.size.width / 0.75)
                Image(image).resizable().interpolation(.high)
                    .frame(width: height * 0.75, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: height * 0.04))
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        } else {
            Image(image).resizable().interpolation(.high).scaledToFit()
        }
    }
}

private struct PostcardSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        let points: [CGPoint] = [
            CGPoint(x: 0.042, y: 0.112), CGPoint(x: 0.895, y: 0.052),
            CGPoint(x: 0.925, y: 0.055), CGPoint(x: 0.938, y: 0.085),
            CGPoint(x: 0.963, y: 0.864), CGPoint(x: 0.952, y: 0.892),
            CGPoint(x: 0.079, y: 0.939), CGPoint(x: 0.064, y: 0.92)
        ]
        var p = Path()
        p.addLines(points.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) })
        p.closeSubpath()
        return p
    }
}
