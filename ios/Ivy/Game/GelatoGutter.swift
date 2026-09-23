import SwiftUI

struct GelatoWaterProgress: Codable {
    static let targetAngles = [-28.0, 18.0, -32.0]
    static let restingAngles = [48.0, -42.0, 55.0]
    // Read the former two-position puzzle without requiring an old save to decode new fields.
    var gates = [0, 1, 0]
    var angles: [Double]? = nil
    var tagRevealed = false

    mutating func sanitize() {
        if gates.count != 3 || !gates.allSatisfy({ $0 == 0 || $0 == 1 }) { gates = [0, 1, 0] }
        if let angles, angles.count != 3 || !angles.allSatisfy({ $0.isFinite && (-65.0...65.0).contains($0) }) {
            self.angles = nil
        }
    }

    var currentAngles: [Double] {
        if let angles, angles.count == 3 { return angles }
        return (0..<3).map { gates[$0] == [1, 0, 1][$0]
            ? Self.targetAngles[$0] : Self.restingAngles[$0] }
    }

    var reach: Int {
        var count = 0
        let angles = currentAngles
        while count < 3 && abs(angles[count] - Self.targetAngles[count]) <= 8 { count += 1 }
        return count
    }

    func landingDescription(_ index: Int) -> String {
        let difference = currentAngles[index] - Self.targetAngles[index]
        if abs(difference) <= 8 { return "Water enters the next channel" }
        return difference < 0 ? "Water falls into the near overflow" : "Water overshoots into the far overflow"
    }
}

extension GameStore {
    var gelatoWater: GelatoWaterProgress {
        get { memories.gelatoWater ?? GelatoWaterProgress() }
        set { memories.gelatoWater = newValue }
    }

    func setGelatoAngle(_ index: Int, to angle: Double) {
        guard room == .gelato, overlay == .memory(.rainGutter), collectingEgg == nil,
              (0..<3).contains(index) else { return }
        var water = gelatoWater
        var angles = water.currentAngles
        angles[index] = min(65, max(-65, angle))
        water.angles = angles
        if water.reach == 3 && !water.tagRevealed {
            water.tagRevealed = true
            gelatoWater = water
            discover(.rainRelation)
            IvyHaptics.success()
        } else {
            gelatoWater = water
            schedulePersist()
        }
    }


    func finishGelatoAdjustment() { persistNow() }
}

struct GelatoGutterView: View {
    @Bindable var store: GameStore
    @State private var dragStarts: [Int: Double] = [:]
    private let mounts = [CGPoint(x: 307, y: 237), CGPoint(x: 605, y: 300), CGPoint(x: 896, y: 372)]

    var body: some View {
        FittedSceneStage(aspectRatio: 2) {
            GeometryReader { geometry in
                let scale = geometry.size.width / 1774
                ZStack(alignment: .topLeading) {
                    InspectionBackdrop(surface: .scene("gelato-gutter-empty"))
                    waterline(scale: scale)
                        .allowsHitTesting(false).accessibilityHidden(true)
                    ForEach(0..<3) { index in
                        let mount = mounts[index]
                        Image("gelato-pivot").resizable().interpolation(.high)
                            .frame(width: 125 * scale, height: 125 * scale)
                            .rotationEffect(.degrees(store.gelatoWater.currentAngles[index]),
                                            anchor: UnitPoint(x: 0.32, y: 0.5))
                            .frame(width: max(48, 125 * scale), height: max(48, 125 * scale))
                            .contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 4)
                                .onChanged { value in
                                    let start = dragStarts[index] ?? store.gelatoWater.currentAngles[index]
                                    if dragStarts[index] == nil { dragStarts[index] = start }
                                    store.setGelatoAngle(index, to: start + Double(value.translation.width / 2.5))
                                }
                                .onEnded { _ in
                                    dragStarts[index] = nil
                                    store.finishGelatoAdjustment()
                                })
                        .position(x: (mount.x + 22.5) * scale, y: mount.y * scale)
                        .accessibilityLabel("Rainwater diverter \(index + 1)")
                        .accessibilityValue(store.gelatoWater.landingDescription(index))
                        .accessibilityAdjustableAction { direction in
                            switch direction {
                            case .increment: store.setGelatoAngle(index, to: store.gelatoWater.currentAngles[index] + 5)
                            case .decrement: store.setGelatoAngle(index, to: store.gelatoWater.currentAngles[index] - 5)
                            @unknown default: break
                            }
                            store.finishGelatoAdjustment()
                        }
                    }
                    if store.gelatoWater.tagRevealed {
                        Image("gelato-float-tag").resizable().interpolation(.high).scaledToFit()
                            .frame(width: 175 * scale, height: 88 * scale)
                            .position(x: 1137 * scale, y: 578 * scale)
                            .accessibilityLabel("Five-petal blossom points to crescent moon")
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .gameBackAction(store.backFromMemory)
    }

    private func waterline(scale: CGFloat) -> some View {
        let reach = store.gelatoWater.reach
        let stops = [CGPoint(x: 175, y: 206), CGPoint(x: 307, y: 237),
                     CGPoint(x: 605, y: 300), CGPoint(x: 896, y: 372)]
        return Canvas { context, _ in
            var path = Path()
            path.move(to: CGPoint(x: stops[0].x * scale, y: stops[0].y * scale))
            for point in stops[1...min(3, reach + 1)] {
                path.addLine(to: CGPoint(x: point.x * scale, y: point.y * scale))
            }
            if reach == 3 {
                path.addLine(to: CGPoint(x: 1148 * scale, y: 450 * scale))
                path.addLine(to: CGPoint(x: 1150 * scale, y: 541 * scale))
            } else {
                let angleError = store.gelatoWater.currentAngles[reach] - GelatoWaterProgress.targetAngles[reach]
                let pivot = stops[reach + 1]
                let landingX = pivot.x + 20 + min(62, max(-62, angleError * 1.2))
                path.addLine(to: CGPoint(x: landingX * scale, y: (pivot.y + 112) * scale))
            }
            context.stroke(path, with: .color(Color(red: 0.70, green: 0.83, blue: 0.85).opacity(0.75)),
                           style: StrokeStyle(lineWidth: max(2, 6 * scale), lineCap: .round))
        }
    }
}
