import SwiftUI

/// Logical landscape size in game pixels. Wider than 3:2 so iPhone landscape has less night gutter.
enum GameCanvas {
    /// Playable plate size.
    static let size = CGSize(width: 320, height: 160)
    /// Horizontal game pixels.
    static let width: CGFloat = 320
    /// Vertical game pixels.
    static let height: CGFloat = 160
    /// Cloud strip width and wrap period.
    static let cloudPeriod = 320
}

/// Scales a pixel-art asset with nearest-neighbor filtering to the landscape canvas.
struct PixelCanvas<Overlay: View>: View {
    /// Asset catalog image name (no file extension).
    let imageName: String

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
        canvasSize: CGSize = GameCanvas.size,
        offsetX: CGFloat = 0,
        dim: Double = 0,
        @ViewBuilder overlay: @escaping (_ scale: CGFloat) -> Overlay
    ) {
        self.imageName = imageName
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
            let width = canvasSize.width * scale
            let height = canvasSize.height * scale
            ZStack {
                Image(imageName)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: width, height: height)
                    .transaction { $0.animation = nil }
                    .overlay(alignment: .topLeading) {
                        overlay(scale)
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
            pixelPlate("sky-lyric")
            cloudStrip(at: cloudOffset)
            cloudStrip(at: cloudOffset - period)
            pixelPlate("ivy-left-\(stage)-\(sway)")
            pixelPlate("ivy-right-\(stage)-\(sway)")
        }
        .frame(width: GameCanvas.width * scale, height: GameCanvas.height * scale, alignment: .topLeading)
        .clipped()
        .allowsHitTesting(false)
        .transaction { $0.animation = nil }
    }

    /// Full-canvas nearest-neighbor plate (sky text or one ivy overlay).
    private func pixelPlate(_ name: String) -> some View {
        Image(name)
            .interpolation(.none)
            .resizable()
            .frame(width: GameCanvas.width * scale, height: GameCanvas.height * scale)
    }

    /// Cloud strip in the lyric band so drift occludes `your ivy grows, ____`.
    private func cloudStrip(at x: Int) -> some View {
        Image("yard-cloud")
            .interpolation(.none)
            .resizable()
            .frame(width: CGFloat(GameCanvas.cloudPeriod) * scale, height: 40 * scale)
            .offset(x: CGFloat(x) * scale, y: 0)
    }
}
