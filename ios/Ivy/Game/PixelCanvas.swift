import SwiftUI

/// Keep the exact decoded image used by the canvas alive across the covered room swap.
@MainActor
enum SceneArtwork {
    private static var images: [String: UIImage] = [:]
    private static var order: [String] = []
    static func image(named name: String) -> UIImage {
        if let image = images[name] { return image }
        let original = UIImage(named: name) ?? UIImage()
        let image = original.preparingForDisplay() ?? original
        images[name] = image
        order.append(name)
        if order.count > 4 { images.removeValue(forKey: order.removeFirst()) }
        return image
    }
}

/// Logical interaction coordinates, independent of background texture resolution.
enum GameCanvas {
    /// Playable plate size.
    static let size = CGSize(width: 320, height: 160)
    /// First-run intro plate; wider so vines can reach the landscape edges.
    static let introSize = CGSize(width: 400, height: 176)
    /// Horizontal game pixels.
    static let width: CGFloat = 320
    /// Vertical game pixels.
    static let height: CGFloat = 160
    /// Cloud strip width and wrap period.
    static let cloudPeriod = 320
    /// Vine-writing beats on the boot card. Matches `intro-spread-sheet` and `FRAMES` in `scripts/generate_intro_spread.py`.
    static let introFrames = 20
    /// Hold per intro beat, in milliseconds.
    static let introFrameMilliseconds = 180
    /// Intro star ping-pong. Matches `STAR_FRAMES` in `scripts/generate_intro_spread.py`.
    static let introStarFrames = 4
    /// Hold per star twinkle beat, in milliseconds.
    static let introStarFrameMilliseconds = 320
    /// Registered roll-to-sheet poses from `scripts/export_yard.swift`.
    static let envelopeFrames = 12
    /// Hold per unroll beat, in milliseconds (the first pose gets a longer hold).
    static let envelopeFrameMilliseconds = 145
}

/// Fits scene artwork to the logical canvas. Full-resolution backgrounds use high-quality filtering;
/// deliberately pixel-authored sprite plates can opt into nearest-neighbor filtering.
struct PixelCanvas<Overlay: View>: View {
    @Environment(\.displayScale) private var displayScale
    /// Asset catalog image name (no file extension).
    let imageName: String
    var pixelArt = true

    /// Logical canvas size in game pixels.
    var canvasSize: CGSize = GameCanvas.size

    /// Horizontal nudge in points (walk or shake).
    var offsetX: CGFloat = 0

    /// Black veil 0...1 for the door cut.
    var dim: Double = 0

    /// Hotspots and miss-tap layer, laid out in the scaled canvas.
    @ViewBuilder var overlay: (_ scale: CGFloat) -> Overlay

    /// Convenience for previews that only need the plate.
    init(imageName: String) where Overlay == EmptyView {
        self.imageName = imageName
        self.overlay = { _ in EmptyView() }
    }

    /// Full canvas with a hotspot overlay that shares this scale.
    init(
        imageName: String,
        pixelArt: Bool = true,
        canvasSize: CGSize = GameCanvas.size,
        offsetX: CGFloat = 0,
        dim: Double = 0,
        @ViewBuilder overlay: @escaping (_ scale: CGFloat) -> Overlay
    ) {
        self.imageName = imageName
        self.pixelArt = pixelArt
        self.canvasSize = canvasSize
        self.offsetX = offsetX
        self.dim = dim
        self.overlay = overlay
    }

    var body: some View {
        GeometryReader { geo in
            let scale = min(
                geo.size.width / canvasSize.width,
                geo.size.height / canvasSize.height
            )
            // Whole physical pixels per game pixel keep pixel clusters equally wide.
            let pixelScale = max(0, floor(scale * displayScale + 0.000001)) / displayScale
            let width = canvasSize.width * pixelScale
            let height = canvasSize.height * pixelScale
            ZStack {
                Image(uiImage: SceneArtwork.image(named: imageName))
                    .interpolation(pixelArt ? .none : .high)
                    .resizable()
                    .frame(width: width, height: height)
                    .transaction { $0.animation = nil }
                    .overlay(alignment: .topLeading) {
                        overlay(pixelScale)
                            .frame(width: width, height: height, alignment: .topLeading)
                            .clipped()
                    }
                    .offset(x: offsetX)
                    .overlay {
                        Color.black.opacity(dim)
                            .allowsHitTesting(dim > 0.5)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Night sky, drifting clouds, and bilateral ivy for the yard plate.
struct YardAtmosphere: View {
    @Environment(\.displayScale) private var displayScale
    /// 0, 1, or 2. Both flanks share this density.
    var vineStage: Int
    /// Ping-pong 0...2 sway frame.
    var swayFrame: Int
    /// Cloud origin in game pixels; wraps every `GameCanvas.cloudPeriod`.
    var cloudOffset: Int
    /// Shared canvas scale (points per game pixel).
    var scale: CGFloat

    var body: some View {
        let stage = min(2, max(0, vineStage))
        let sway = min(2, max(0, swayFrame))
        let period = GameCanvas.cloudPeriod
        ZStack(alignment: .topLeading) {
            IvyType.inscription(GameCopy.skyLine)
                .font(IvyType.script(9 * scale))
                .foregroundStyle(IvyType.cream)
                .position(x: 113 * scale, y: 16 * scale)
            cloudStrip(at: cloudOffset)
            cloudStrip(at: cloudOffset - period)
            ForEach([0, -period], id: \.self) { wrap in
                cloudStrip(at: (cloudOffset / 2 + 172) % period + wrap,
                           width: 92, height: 13, y: 29, opacity: 0.65)
                cloudStrip(at: (cloudOffset / 3 + 65) % period + wrap,
                           width: 64, height: 9, y: 40, opacity: 0.4)
            }
            vine(at: CGPoint(x: 104, y: 54), sway: sway)
            vine(at: CGPoint(x: 276, y: 52), sway: sway, mirrored: true)
            if stage >= 1 {
                vine(at: CGPoint(x: 94, y: 80), sway: sway, size: 0.65)
                vine(at: CGPoint(x: 289, y: 78), sway: sway, size: 0.65, mirrored: true)
            }
            if stage >= 2 {
                vine(at: CGPoint(x: 158, y: 54), sway: sway, size: 0.55)
                vine(at: CGPoint(x: 258, y: 66), sway: sway, size: 0.55, mirrored: true)
            }
        }
        .frame(width: GameCanvas.width * scale, height: GameCanvas.height * scale, alignment: .topLeading)
        .clipped()
        .allowsHitTesting(false)
        .transaction { $0.animation = nil }
    }

    private func vine(at point: CGPoint, sway: Int, size: CGFloat = 1, mirrored: Bool = false) -> some View {
        let spriteScale = max(1, (scale * size * displayScale).rounded()) / displayScale
        return PixelSpriteFrame(sheet: .storyVine, index: sway, scale: spriteScale)
            .scaleEffect(x: mirrored ? -1 : 1, y: 1)
            .offset(x: point.x * scale, y: point.y * scale)
    }

    /// Draw above the lettering: the cloud's alpha silhouette hides and reveals it as it passes.
    private func cloudStrip(at x: Int, width: CGFloat = 138, height: CGFloat = 26,
                            y: CGFloat = 3, opacity: Double = 0.98) -> some View {
        Image("story-cloud")
            .interpolation(.high)
            .resizable()
            .frame(width: width * scale, height: height * scale)
            .opacity(opacity)
            .offset(x: CGFloat(x) * scale, y: y * scale)
    }
}
