import SwiftUI

struct BigTopCloseupView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel

    var body: some View {
        Group {
            if panel == .bigTop && store.bigTop.orderSolved {
                ElementMemoryView(store: store, image: "bt-dinner", title: "Big Top",
                                  line: EggId.noodle.memoryLine, back: store.backFromMemory)
            } else {
                Group {
                    switch panel {
                    case .bigTopMenuSearch:
                        SceneDetailStage(bounds: BigTopCounterLayout.drawerCamera) {
                            BigTopCounterArtwork(store: store, interactiveLock: true)
                        }
                    case .bigTopLedger: ledger
                    case .bigTopMirror:
                        SceneDetailStage(bounds: CGRect(x: 48, y: 59, width: 182, height: 53)) {
                            GeometryReader { geometry in
                                let scale = geometry.size.width / 320
                                ZStack {
                                    InspectionBackdrop(surface: .scene("bt3-mirror"))
                                    BigTopEvidenceArtwork(mirrored: true)
                                        .frame(width: 141 * scale, height: 28 * scale)
                                        .position(x: 139 * scale, y: 84 * scale)
                                }
                            }
                        }
                    case .bigTopMenu: BigTopOrderMenu(store: store)
                    default: ordinaryCloseup
                    }
                }
                .overlay(alignment: .bottom) {
                    if panel != .bigTopSign {
                        SceneFeedback(store: store, height: 30).allowsHitTesting(false)
                    }
                }
                .gameBackAction(store.backFromMemory)
                .task {
                    guard panel == .bigTopSign, store.bigTop.signSolved,
                          store.room == .gelato, store.overlay == .memory(.bigTopSign) else { return }
                    try? await Task.sleep(for: .milliseconds(store.prefersReducedMotion ? 0 : 450))
                    guard !Task.isCancelled, store.room == .gelato,
                          store.overlay == .memory(.bigTopSign) else { return }
                    store.transition(to: .noodle)
                }
            }
        }
    }

    private var ordinaryCloseup: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let size = geometry.size
                ZStack {
                    InspectionBackdrop(surface: .scene(panel == .bigTopSign ? "bt2-neon-wall" : "bt2-counter"))
                    if panel == .bigTopSign {
                        BigTopNeonLetters(order: store.bigTop.signOrder ?? "GPIBTO", progress: store.bigTop.signDraft,
                                          solved: store.bigTop.signSolved, reducedMotion: store.prefersReducedMotion,
                                          onTap: { store.tapNeonLetter($0) })
                            .frame(width: size.width * 0.78, height: size.height * 0.46)
                            .position(x: size.width * 0.51, y: size.height * 0.46)
                    } else {
                        Button(action: store.placeBigTopMenu) {
                            Color.clear.frame(width: max(48, size.width * 0.18), height: max(48, size.height * 0.27))
                                .contentShape(Rectangle())
                        }.buttonStyle(.plain)
                            .accessibilityLabel("Place the menu on the clipboard")
                            .inventoryToolDrop(store: store, accepting: [.dinnerMenu]) { _ in store.placeBigTopMenu() }
                            .position(x: size.width * 0.475, y: size.height * 0.51)
                    }
                }
            }
        }
    }

    private var ledger: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let revealed = store.exploration.clues.contains(.bigTopLedger)
                ZStack {
                    InspectionBackdrop(surface: .scene("bt3-ledger"))
                    BigTopEvidenceArtwork(mirrored: false)
                        .opacity(revealed ? 0.85 : 0)
                        .frame(width: geometry.size.width * 0.54, height: geometry.size.height * 0.56)
                        .allowsHitTesting(false).accessibilityHidden(!revealed)
                    Color.clear
                        .frame(width: geometry.size.width * 0.6, height: geometry.size.height * 0.72)
                        .contentShape(Rectangle())
                        .onTapGesture { store.revealBigTopLedger() }
                        .gesture(DragGesture(minimumDistance: 8).onEnded { _ in store.revealBigTopLedger() })
                        .inventoryToolDrop(store: store, accepting: [.bigTopPencil])
                        .accessibilityElement()
                        .accessibilityLabel(revealed ? BigTopMenu.ledgerDescription : "Faint impressions on the next ledger page")
                        .accessibilityAction(named: Text("Shade the impressions"), store.revealBigTopLedger)
                }
            }
        }
    }
}

/// Ten stable dish IDs, one persistent shuffle, no categories or page turns.
private struct BigTopOrderMenu: View {
    let store: GameStore
    var body: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let size = geometry.size
                // Reflow within the complete 2:1 tabletop; never shorten a 48 pt row.
                let rows = size.height < 240 ? 2 : size.height < 320 ? 3 : 4
                let columns = (10 + rows - 1) / rows
                let columnWidth = max(48, size.width * 0.72 / CGFloat(columns))
                let rowHeight = max(48, size.height * 0.60 / CGFloat(rows))
                let order = store.bigTop.menuOrder ?? BigTopMenu.availableIDs
                ZStack(alignment: .topLeading) {
                    InspectionBackdrop(surface: .scene("bt3-menu"))
                    ForEach(Array(order.enumerated()), id: \.element) { offset, id in
                        let column = offset / rows
                        let row = offset % rows
                        Button { store.selectDish(id) } label: {
                            HStack(spacing: 5) {
                                ZStack {
                                    Circle().stroke(IvyType.ink, lineWidth: 1.2)
                                    if store.bigTop.order.contains(id) {
                                        PencilCheck().stroke(IvyType.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                    }
                                }.frame(width: 16, height: 16)
                                Image("bt3-dish-\(id)").resizable().interpolation(.high).scaledToFit()
                            }
                            .frame(width: columnWidth, height: rowHeight, alignment: .leading)
                            .contentShape(Rectangle())
                        }.buttonStyle(.plain).disabled(store.bigTop.orderSolved)
                            .accessibilityLabel(BigTopMenu.dishes[id])
                            .accessibilityValue(store.bigTop.order.contains(id) ? "Checked" : "Unchecked")
                            .position(x: size.width * 0.06 + columnWidth * (CGFloat(column) + 0.5),
                                      y: size.height * 0.24 + rowHeight * (CGFloat(row) + 0.5))
                    }
                    Button(action: store.placeDinnerOrder) {
                        Color.clear.frame(width: max(48, size.width * 0.13), height: max(48, size.height * 0.46))
                            .contentShape(Ellipse())
                    }.buttonStyle(.plain).disabled(store.bigTop.orderSolved)
                        .accessibilityLabel("Ring the order bell")
                        .position(x: size.width * 0.915, y: size.height * 0.56)
                }
            }
        }
    }
}

private struct PencilCheck: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.49))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.76))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.91, y: rect.minY + rect.height * 0.08))
        }
    }
}

struct BigTopNeonLetters: View {
    let order: String
    let progress: String
    let solved: Bool
    var reducedMotion = false
    var onTap: ((String) -> Void)? = nil
    private let letters = Array("BIGTOP").map(String.init)
    var body: some View {
        GeometryReader { geometry in
            ForEach(letters, id: \.self) { letter in
                let order = Array(solved ? "BIGTOP" : self.order).map(String.init)
                let index = order.firstIndex(of: letter) ?? 0
                let lit = solved || progress.contains(letter)
                let selectedPosition = progress.range(of: letter).map { progress.distance(from: progress.startIndex, to: $0.lowerBound) + 1 }
                let spokenOrder = progress.isEmpty ? "none" : progress
                Group {
                    if let onTap {
                        Button { onTap(letter) } label: { tube(letter, lit: lit) }
                            .buttonStyle(.plain).disabled(solved)
                            .accessibilityLabel("Neon letter " + letter)
                            .accessibilityValue(solved ? "Sign complete" : selectedPosition != nil
                                ? "Selected position \(selectedPosition ?? 0) of six. Current order: \(spokenOrder). Tap again to undo the last letter."
                                : "Not selected. Current order: \(spokenOrder).")
                    } else { tube(letter, lit: lit) }
                }
                .frame(width: geometry.size.width / 6, height: geometry.size.height)
                .contentShape(Rectangle())
                .position(x: geometry.size.width * (CGFloat(index) + 0.5) / 6,
                          y: geometry.size.height / 2)
            }
        }
        .animation(reducedMotion ? nil : .easeInOut(duration: 0.45), value: solved)
    }
    private func tube(_ letter: String, lit: Bool) -> some View {
        ZStack {
            Image("bt2-neon-" + letter.lowercased() + "-off").resizable().interpolation(.high).scaledToFit()
            Image("bt2-neon-" + letter.lowercased() + "-on").resizable().interpolation(.high).scaledToFit()
                .shadow(color: glowColor(letter).opacity(lit ? 0.55 : 0), radius: 6)
                .opacity(lit ? 1 : 0)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
    }
    private func glowColor(_ letter: String) -> Color {
        switch letter {
        case "B": .pink
        case "I": .blue
        case "G": .yellow
        case "T": .mint
        case "O": .orange
        default: .purple
        }
    }
}

struct DinnerMenuArtwork: View {
    var body: some View {
        GeometryReader { geometry in
            let source = SceneArtwork.image(named: "bt2-menu-cover-lettered").size
            let aspect = max(1, source.width) / max(1, source.height)
            let width = min(geometry.size.width, geometry.size.height * aspect)
            let height = width / aspect
            Image("bt2-menu-cover-lettered").resizable().interpolation(.high).scaledToFit()
                .frame(width: width, height: height)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

/// The physical surface, scene objects and all counter hotspots use this same 320×160 canvas.
enum BigTopCounterLayout {
    static let pencil = CGRect(x: 107, y: 65, width: 29, height: 15)
    static let mirror = CGRect(x: 182, y: 61, width: 57, height: 23)
    static let ledger = CGRect(x: 41, y: 53, width: 68, height: 29)
    static let slit = CGRect(x: 174, y: 55, width: 60, height: 8)
    static let drawer = CGRect(x: 97, y: 117, width: 126, height: 37)
    static let drawerCamera = CGRect(x: 92, y: 103, width: 135, height: 54)
    // The menu lies on the drawer floor, behind the front lip, in bt-state-menu.
    static let menu = CGRect(x: 117, y: 105, width: 55, height: 20)
    static func wheel(_ index: Int, open: Bool) -> CGPoint {
        CGPoint(x: (open ? 117.5 : 121.5) + CGFloat(index) * (open ? 28.3 : 25.4), y: open ? 138.5 : 130.7)
    }
}

/// Room and lock camera share complete closed / occupied / empty counter plates.
struct BigTopCounterArtwork: View {
    let store: GameStore
    var interactiveLock = false
    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 320
            let open = store.bigTop.menuDrawerOpen == true
            ZStack(alignment: .topLeading) {
                Image(store.bigTopCounterImageName).resizable().interpolation(.high)
                if !store.memories.picked.contains(.bigTopPencil) {
                    object(.bigTopPencil, rect: BigTopCounterLayout.pencil, scale: scale)
                }
                if !store.memories.picked.contains(.bigTopInspectionMirror) {
                    object(.bigTopInspectionMirror, rect: BigTopCounterLayout.mirror, scale: scale)
                }
                if store.exploration.clues.contains(.bigTopMirror) {
                    Image(AdventureTool.bigTopInspectionMirror.imageName).resizable().interpolation(.high).scaledToFit()
                        .frame(width: 37 * scale, height: 10 * scale)
                        .rotationEffect(.degrees(-18))
                        .position(x: 204 * scale, y: 59 * scale)
                }
                ForEach(0..<4, id: \.self) { index in
                    let value = (store.bigTop.drawerSymbols ?? [1, 3, 2, 4])[index]
                    let point = BigTopCounterLayout.wheel(index, open: open)
                    Button { store.turnBigTopSymbol(index) } label: {
                        Image("bt3-symbol-" + BigTopMenu.symbols[value]).resizable().interpolation(.high).scaledToFit()
                            .frame(width: 10 * scale, height: 10 * scale)
                            .frame(width: max(48, 19 * scale), height: max(48, 19 * scale))
                            .contentShape(Circle())
                    }.buttonStyle(.plain).disabled(open)
                        .allowsHitTesting(interactiveLock && !open)
                        .accessibilityLabel("Wheel \(index + 1)")
                        .accessibilityValue(BigTopMenu.symbols[value])
                        .accessibilityAdjustableAction { direction in
                            store.turnBigTopSymbol(index, by: direction == .decrement ? -1 : 1)
                        }
                        .position(x: point.x * scale, y: point.y * scale)
                }
                if open && !store.bigTop.menuTaken {
                    Button(action: store.takeBigTopMenu) {
                        Color.clear
                            .frame(width: max(48, BigTopCounterLayout.menu.width * scale),
                                   height: max(48, BigTopCounterLayout.menu.height * scale))
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain).allowsHitTesting(interactiveLock)
                        .accessibilityLabel("Take the folded menu")
                        .position(x: BigTopCounterLayout.menu.midX * scale, y: BigTopCounterLayout.menu.midY * scale)
                }
                if interactiveLock && !open {
                    Button(action: store.openBigTopMenuDrawer) {
                        Color.clear.frame(width: 60 * scale, height: max(48, 8 * scale)).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel("Pull the drawer handle")
                        .position(x: 159 * scale, y: 143 * scale)
                }
            }.frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    private func object(_ tool: AdventureTool, rect: CGRect, scale: CGFloat) -> some View {
        Image(tool.imageName).resizable().interpolation(.high).scaledToFit()
            .frame(width: rect.width * scale, height: rect.height * scale)
            .position(x: rect.midX * scale, y: rect.midY * scale)
    }
}

extension GameStore {
    var bigTopCounterImageName: String {
        guard bigTop.menuDrawerOpen == true else { return "bt-state-closed" }
        return bigTop.menuTaken ? "bt-state-empty" : "bt-state-menu"
    }
}

/// The mirror derives from the SAME front-view geometry, flipped as a whole exactly once.
/// Notes reuses this artwork without translating the evidence into an answer.
struct BigTopEvidenceArtwork: View {
    let mirrored: Bool
    var notebook = false
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let insetX = size.width * 0.065
            let insetY = size.height * 0.12
            let width = size.width * 0.84
            let height = size.height * 0.76
            let ink = mirrored && !notebook ? Color(red: 0.86, green: 0.70, blue: 0.44) : IvyType.ink
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: insetX + 12, y: insetY))
                    path.addLine(to: CGPoint(x: insetX + width, y: insetY))
                    path.addLine(to: CGPoint(x: insetX + width, y: insetY + height))
                    path.addLine(to: CGPoint(x: insetX, y: insetY + height))
                    path.addLine(to: CGPoint(x: insetX, y: insetY + 12))
                    path.closeSubpath()
                    for column in 1..<4 {
                        let x = insetX + width * CGFloat(column) / 4
                        path.move(to: CGPoint(x: x, y: insetY)); path.addLine(to: CGPoint(x: x, y: insetY + height))
                    }
                    path.move(to: CGPoint(x: insetX, y: insetY + height / 2))
                    path.addLine(to: CGPoint(x: insetX + width, y: insetY + height / 2))
                    for offset in [CGFloat(0.77), 0.92] {
                        path.addEllipse(in: CGRect(x: insetX + width + 4, y: insetY + height * offset - 2, width: 4, height: 4))
                    }
                }.stroke(ink.opacity(0.7), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                if mirrored {
                    let points = BigTopMenu.drawerAnswer.map { index in
                        CGPoint(x: insetX + width * (CGFloat(index % 4) + 0.5) / 4,
                                y: insetY + height * (CGFloat(index / 4) + 0.5) / 2)
                    }
                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() { path.addLine(to: point) }
                        path.addEllipse(in: CGRect(x: points[0].x - 4, y: points[0].y - 4, width: 8, height: 8))
                        let end = points[3]
                        let angle = atan2(end.y - points[2].y, end.x - points[2].x)
                        for turn in [-CGFloat.pi / 5, CGFloat.pi / 5] {
                            path.move(to: end)
                            path.addLine(to: CGPoint(x: end.x - 9 * cos(angle + turn), y: end.y - 9 * sin(angle + turn)))
                        }
                    }.stroke(ink, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                } else {
                    ForEach(0..<8, id: \.self) { index in
                        Image("bt3-symbol-" + BigTopMenu.symbols[index]).resizable().interpolation(.high).scaledToFit()
                            .frame(width: width * 0.16, height: height * 0.33)
                            .position(x: insetX + width * (CGFloat(index % 4) + 0.5) / 4,
                                      y: insetY + height * (CGFloat(index / 4) + 0.5) / 2)
                    }
                }
            }.frame(width: size.width, height: size.height)
                .scaleEffect(x: mirrored ? -1 : 1, y: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mirrored ? BigTopMenu.mirrorDescription : BigTopMenu.ledgerDescription)
    }
}
