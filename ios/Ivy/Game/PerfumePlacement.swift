import SwiftUI

/// Authored ll4 source coordinates (320 × 160). Trays belong to the original
/// worktop, not an extra UI layer. All 21 ingredients share these physical slots.
enum PerfumePlacement {
    static let trayCenters: [CGFloat] = [53, 119.5, 181.5]
    static let trayContact: CGFloat = 116
    static let output = CGRect(x: 237, y: 85, width: 23, height: 25)
    static let boxCenters: [CGFloat] = [103, 160, 217]
    static let boxBottleSize = CGSize(width: 36, height: 53)
    static let boxBottleBottom: CGFloat = 114
    // Physical table box in ll4-entry. A separate scene camera, same slot identity.
    static let worldBoxCenters: [CGFloat] = [176, 190, 205]

    static func ingredientSize(_ tool: AdventureTool) -> CGSize {
        switch tool {
        case .gaiacWood, .incense, .oakmoss, .violet, .cardamom:
            CGSize(width: 35, height: 18)
        case .cedar, .patchouli, .vetiver, .cinnamon:
            CGSize(width: 29, height: 24)
        default:
            CGSize(width: 24, height: 27)
        }
    }
}

struct PerfumeBenchObject: View {
    let tool: AdventureTool
    let slot: Int
    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 320
            let size = PerfumePlacement.ingredientSize(tool)
            FragranceBottleArtwork(tool: tool, showLabel: false)
                .frame(width: size.width * scale, height: size.height * scale)
                .shadow(color: .black.opacity(0.32), radius: scale, x: 0, y: scale)
                .position(x: PerfumePlacement.trayCenters[slot] * scale,
                          y: (PerfumePlacement.trayContact - size.height / 2) * scale)
        }
        .allowsHitTesting(false)
    }
}

/// Repaint only the actual front lips above placed objects. No surrogate shapes
/// are visible: the mask reveals pixels from the matching authored background.
struct PerfumeTrayFronts: View {
    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 320
            Image("ll4-bench").resizable().scaledToFit()
                .mask {
                    Path { path in
                        for x in PerfumePlacement.trayCenters {
                            path.addRect(CGRect(x: (x - 30) * scale, y: 119 * scale,
                                                width: 60 * scale, height: 7 * scale))
                        }
                    }
                }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct PerfumeBenchCabinet: View {
    let opened: Bool
    var body: some View {
        if opened {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                Image("ll-bench-open").resizable().scaledToFit()
                    .mask {
                        Rectangle().frame(width: 83 * scale, height: 79 * scale)
                            .position(x: 74 * scale, y: 46 * scale)
                    }
            }.allowsHitTesting(false).accessibilityHidden(true)
        }
    }
}

struct SeatedPerfumeArtwork: View {
    let tool: AdventureTool
    var body: some View {
        Image("ll4-seated-" + tool.rawValue).resizable().interpolation(.high).scaledToFit()
            .accessibilityLabel(tool.label)
    }
}

/// Three matching apertures remain equally permissive for every perfume.
/// Real liner front edge sits at y=114; bottle base can naturally tuck behind it.
struct PerfumeBoxFront: View {
    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 320
            Image("ll4-box").resizable().scaledToFit()
                .mask {
                    Rectangle().frame(width: 320 * scale, height: 46 * scale)
                        .position(x: 160 * scale, y: 137 * scale)
                }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// The distant camera uses the same three slot identities, its own table coordinates.
struct PerfumeWorldBoxFront: View {
    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 320
            Image("ll4-entry").resizable().scaledToFit()
                .mask {
                    Rectangle().frame(width: 54 * scale, height: 8 * scale)
                        .position(x: 190 * scale, y: 124.5 * scale)
                }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
