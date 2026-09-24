import SwiftUI

/// First-run invitation: ivy grows across the title while the Yard artwork warms.
struct IntroView: View {
    var onEnter: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var growth: CGFloat = 0
    @State private var crawlComplete = false
    @State private var yardReady = false
    @State private var tipSway = false
    @State private var didEnter = false

    private let artworkSize = CGSize(width: 1774, height: 887)

    var body: some View {
        ZStack {
            Color("Night").ignoresSafeArea()

            GeometryReader { geometry in
                let scale = min(geometry.size.width / artworkSize.width,
                                geometry.size.height / artworkSize.height)

                ZStack(alignment: .topLeading) {
                    Image("intro-yard-background")
                        .interpolation(.high)
                        .resizable()
                        .frame(width: artworkSize.width * scale, height: artworkSize.height * scale)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: finishCrawl)
                        .accessibilityHidden(true)

                    Image("intro-title")
                        .interpolation(.high)
                        .resizable()
                        .frame(width: 650 * scale, height: 325 * scale)
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: 650 * scale * growth)
                        }
                        .position(x: 452 * scale, y: 229 * scale)
                        .accessibilityLabel("Ivy")

                    Image("intro-tagline")
                        .interpolation(.high)
                        .resizable()
                        .frame(width: 600 * scale, height: 200 * scale)
                        .position(x: 483 * scale, y: 395 * scale)
                        .opacity(crawlComplete ? 1 : 0)
                        .accessibilityLabel(GameCopy.introTitle)

                    if crawlComplete && !yardReady && !reduceMotion {
                        Image("ui-ivy-sprig")
                            .interpolation(.high)
                            .resizable()
                            .frame(width: 42 * scale, height: 14 * scale)
                            .rotationEffect(.degrees(tipSway ? 4 : -4), anchor: .leading)
                            .position(x: 711 * scale, y: 178 * scale)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                            .task {
                                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    tipSway = true
                                }
                            }
                    }

                    if crawlComplete && yardReady {
                        PuzzleButton("Enter", width: 120, action: enter)
                            .position(x: 352 * scale, y: 730 * scale)
                    }
                }
                .frame(width: artworkSize.width * scale, height: artworkSize.height * scale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .statusBarHidden(true)
        .task { await crawlIvy() }
        .task { await prepareYard() }
    }

    private func crawlIvy() async {
        if reduceMotion {
            finishCrawl()
            return
        }
        for frame in 1...40 {
            if Task.isCancelled || crawlComplete { return }
            growth = CGFloat(frame) / 40
            try? await Task.sleep(for: .milliseconds(55))
        }
        crawlComplete = true
    }

    private func finishCrawl() {
        guard !crawlComplete else { return }
        growth = 1
        crawlComplete = true
    }

    private func prepareYard() async {
        await Task.yield()
        _ = SceneArtwork.image(named: "story-yard-base")
        SpriteAtlas.warm("story-cloud", SpriteSheet.storyVine.imageName)
        yardReady = true
    }

    private func enter() {
        guard !didEnter, yardReady else { return }
        didEnter = true
        IvyHaptics.light()
        onEnter()
    }
}

#Preview {
    IntroView(onEnter: {})
}
