import SwiftUI

/// Source-space geometry on the approved 1254 × 1254 painted bouquet.
/// Both the loose petal and its recess use exactly the same silhouette.
enum RoseArtwork {
    static let image = "rose-bouquet"
    static let sourceEdge: CGFloat = 1254
    static let bounds = CGRect(x: 245, y: 16, width: 765, height: 1195)
    static let aspect = bounds.width / bounds.height

    static func petal(_ index: Int) -> Path {
        var path = Path()
        switch index {
        case 0: // The upper rose's broad front petal.
            path.move(to: CGPoint(x: 522, y: 153))
            path.addCurve(to: CGPoint(x: 604, y: 92), control1: CGPoint(x: 532, y: 112), control2: CGPoint(x: 568, y: 88))
            path.addCurve(to: CGPoint(x: 705, y: 133), control1: CGPoint(x: 646, y: 87), control2: CGPoint(x: 686, y: 101))
            path.addCurve(to: CGPoint(x: 720, y: 157), control1: CGPoint(x: 713, y: 140), control2: CGPoint(x: 718, y: 150))
            path.addCurve(to: CGPoint(x: 625, y: 211), control1: CGPoint(x: 690, y: 173), control2: CGPoint(x: 654, y: 190))
            path.addCurve(to: CGPoint(x: 522, y: 153), control1: CGPoint(x: 595, y: 190), control2: CGPoint(x: 558, y: 165))
        case 1: // The left rose's long outer curl.
            path.move(to: CGPoint(x: 550, y: 248))
            path.addCurve(to: CGPoint(x: 580, y: 267), control1: CGPoint(x: 558, y: 245), control2: CGPoint(x: 572, y: 255))
            path.addCurve(to: CGPoint(x: 610, y: 376), control1: CGPoint(x: 604, y: 298), control2: CGPoint(x: 612, y: 339))
            path.addCurve(to: CGPoint(x: 567, y: 508), control1: CGPoint(x: 614, y: 438), control2: CGPoint(x: 597, y: 483))
            path.addCurve(to: CGPoint(x: 501, y: 532), control1: CGPoint(x: 549, y: 523), control2: CGPoint(x: 519, y: 537))
            path.addCurve(to: CGPoint(x: 496, y: 508), control1: CGPoint(x: 491, y: 531), control2: CGPoint(x: 488, y: 519))
            path.addCurve(to: CGPoint(x: 523, y: 388), control1: CGPoint(x: 517, y: 470), control2: CGPoint(x: 523, y: 429))
            path.addCurve(to: CGPoint(x: 521, y: 301), control1: CGPoint(x: 523, y: 351), control2: CGPoint(x: 516, y: 324))
            path.addCurve(to: CGPoint(x: 550, y: 248), control1: CGPoint(x: 523, y: 274), control2: CGPoint(x: 531, y: 255))
        default: // The right rose's small pointed front petal.
            path.move(to: CGPoint(x: 789, y: 328))
            path.addCurve(to: CGPoint(x: 816, y: 343), control1: CGPoint(x: 800, y: 324), control2: CGPoint(x: 810, y: 332))
            path.addCurve(to: CGPoint(x: 839, y: 443), control1: CGPoint(x: 829, y: 371), control2: CGPoint(x: 833, y: 412))
            path.addCurve(to: CGPoint(x: 850, y: 505), control1: CGPoint(x: 843, y: 468), control2: CGPoint(x: 852, y: 490))
            path.addCurve(to: CGPoint(x: 832, y: 525), control1: CGPoint(x: 850, y: 520), control2: CGPoint(x: 842, y: 526))
            path.addCurve(to: CGPoint(x: 778, y: 493), control1: CGPoint(x: 813, y: 523), control2: CGPoint(x: 791, y: 508))
            path.addCurve(to: CGPoint(x: 750, y: 417), control1: CGPoint(x: 759, y: 473), control2: CGPoint(x: 748, y: 446))
            path.addCurve(to: CGPoint(x: 768, y: 350), control1: CGPoint(x: 750, y: 392), control2: CGPoint(x: 756, y: 367))
            path.addCurve(to: CGPoint(x: 789, y: 328), control1: CGPoint(x: 774, y: 339), control2: CGPoint(x: 781, y: 331))
        }
        path.closeSubpath()
        return path
    }

    static func draw(in context: inout GraphicsContext) {
        context.draw(Image(image), in: CGRect(x: 0, y: 0, width: sourceEdge, height: sourceEdge))
    }

    static func fit(_ bounds: CGRect, in size: CGSize, context: inout GraphicsContext) {
        let scale = min(size.width / bounds.width, size.height / bounds.height)
        context.translateBy(x: (size.width - bounds.width * scale) / 2,
                            y: (size.height - bounds.height * scale) / 2)
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -bounds.minX, y: -bounds.minY)
    }
}

/// An actual piece of the original artwork, not an approximate replacement petal.
struct RosePetalArtwork: View {
    let index: Int
    var body: some View {
        Canvas { context, size in
            let silhouette = RoseArtwork.petal(index)
            RoseArtwork.fit(silhouette.boundingRect, in: size, context: &context)
            context.clip(to: silhouette)
            RoseArtwork.draw(in: &context)
        }
    }
}

/// Missing petals become dark painted recesses. The completed image is untouched.
struct RoseFlower: View {
    let petals: Set<Int>
    var body: some View {
        Canvas { context, size in
            RoseArtwork.fit(RoseArtwork.bounds, in: size, context: &context)
            RoseArtwork.draw(in: &context)
            for index in 0..<3 where !petals.contains(index) {
                context.drawLayer { recess in
                    recess.clip(to: RoseArtwork.petal(index))
                    recess.addFilter(.colorMultiply(Color(red: 0.23, green: 0.19, blue: 0.23)))
                    RoseArtwork.draw(in: &recess)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Red rose bouquet in a smiling paper wrapper")
        .accessibilityValue("\(petals.count) of 3 petals in place")
    }
}
