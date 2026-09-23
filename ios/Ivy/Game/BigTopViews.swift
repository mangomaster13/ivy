import SwiftUI

struct BigTopCloseupView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel

    private var background: String {
        switch panel {
        case .bigTopSign: "bt2-neon-wall"
        case .bigTopMenu: "bt2-menu-open"
        case .bigTopOrder: "bt2-counter"
        case .bigTopMenuSearch: store.bigTop.menuDrawerOpen == true && !store.bigTop.menuTaken ? "bt2-counter-eight-open" : "bt2-counter-eight"
        default: "bt2-counter-eight"
        }
    }
    private var pageNavigation: GamePageNavigation? {
        guard panel == .bigTopMenu else { return nil }
        return GamePageNavigation(canGoPrevious: store.bigTop.menuPage > 0,
                                  canGoNext: store.bigTop.menuPage < 3,
                                  previous: { store.turnDinnerPage(-1) },
                                  next: { store.turnDinnerPage(1) })
    }
    var body: some View {
        if panel == .bigTop && store.bigTop.orderSolved {
            ElementMemoryView(store: store, image: "bt-dinner", title: "Big Top",
                              line: EggId.noodle.memoryLine, back: store.backFromMemory)
        } else {
            FittedSceneStage {
                GeometryReader { geometry in
                    ZStack {
                        InspectionBackdrop(surface: .scene(background))
                        content(size: geometry.size)
                        if panel != .bigTopSign {
                            VStack { Spacer(); SceneFeedback(store: store, height: 30) }
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .gameBackAction(store.backFromMemory)
            .preference(key: GamePageNavigationKey.self, value: pageNavigation)
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
    @ViewBuilder private func content(size: CGSize) -> some View {
        switch panel {
        case .bigTopSign:
            BigTopNeonLetters(order: store.bigTop.signOrder ?? "GPIBTO", progress: store.bigTop.signDraft, solved: store.bigTop.signSolved,
                              reducedMotion: store.prefersReducedMotion, onTap: { store.tapNeonLetter($0) })
                .frame(width: size.width * 0.78, height: size.height * 0.46)
                .position(x: size.width * 0.51, y: size.height * 0.46)
        case .bigTopMenu: menu(size: size)
        case .bigTopOrder: clipboard(size: size)
        default: search(size: size)
        }
    }
    private func search(size: CGSize) -> some View {
        BigTopMenuDiscovery(store: store)
            .frame(width: size.width, height: size.height)
    }
    private func clipboard(size: CGSize) -> some View {
        Button {
            if store.bigTop.menuPlaced { store.openMemory(.bigTopMenu) }
            else { store.placeBigTopMenu() }
        } label: {
            ZStack {
                Color.clear
                if store.bigTop.menuPlaced {
                    DinnerMenuArtwork().rotationEffect(.degrees(7))
                        .padding(.horizontal, size.width * 0.018)
                }
            }.frame(width: size.width * 0.18, height: size.height * 0.27)
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel(store.bigTop.menuPlaced ? "Open the menu" : "Empty order clipboard")
            .inventoryToolDrop(store: store, accepting: [.dinnerMenu]) { _ in store.placeBigTopMenu() }
            .position(x: size.width * 0.475, y: size.height * 0.51)
    }
    private func menu(size: CGSize) -> some View {
        let page = store.bigTop.menuPage
        let rowHeight = max(48, size.height * 0.115)
        return ZStack {
            Image("bt2-menu-lettering-\(page + 1)")
                .resizable().interpolation(.high)
                .frame(width: size.width, height: size.height)
                .accessibilityHidden(true)
            ForEach(0..<5) { offset in
                dish(page * 5 + offset)
                    .frame(width: size.width * 0.29, height: rowHeight)
                    .position(x: size.width * (offset < 3 ? 0.255 : 0.565),
                              y: size.height * 0.38 + CGFloat(offset < 3 ? offset : offset - 3) * size.height * 0.134)
            }
            Button(action: store.placeDinnerOrder) {
                Color.clear.frame(width: max(48, size.width * 0.19), height: max(48, size.height * 0.37))
                    .contentShape(Ellipse())
            }.buttonStyle(.plain)
                .position(x: size.width * 0.89, y: size.height * 0.49)
                .disabled(store.bigTop.orderSolved)
                .accessibilityLabel("Ring the order bell")
                .accessibilityValue(store.bigTop.orderSolved ? "Order accepted" : "")
        }.foregroundStyle(IvyType.ink)
    }
    private func dish(_ index: Int) -> some View {
        let checked = store.bigTop.order.contains(index)
        return Button { store.selectDish(index) } label: {
            HStack(spacing: 7) {
                ZStack {
                    Circle().stroke(IvyType.ink.opacity(0.8), lineWidth: 1.1)
                    if checked { PencilCheck().stroke(IvyType.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)) }
                }.frame(width: 18, height: 18)
                Spacer(minLength: 0)
            }.frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(store.bigTop.orderSolved)
            .accessibilityLabel(BigTopMenu.dishes[index])
            .accessibilityValue(checked ? "Checked" : "Unchecked")
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

/// One set of authored glass tubes serves both the small street sign and its closeup.
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

/// The tracing sheet and eight drawer hit targets share the counter's 320×160 canvas.
struct BigTopMenuDiscovery: View {
    let store: GameStore
    @State private var dragOffset: CGFloat = 0
    @State private var turnOffset: Double = 0
    private var paperAngle: Double { (store.bigTop.tracingAngle ?? 0) + turnOffset }
    private var paperOffset: CGFloat { CGFloat(store.bigTop.tracingOffset ?? 0) + dragOffset }
    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / 320, geometry.size.height / 160)
            ZStack {
                if !store.bigTop.menuTaken {
                    Image("bt2-tracing-paper")
                        .resizable().interpolation(.high)
                        .frame(width: 82 * scale, height: 40 * scale)
                        .rotationEffect(.degrees(paperAngle + 180))
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 2)
                            .onChanged { dragOffset = $0.translation.width / scale }
                            .onEnded { value in
                                store.slideBigTopTracingPaper((store.bigTop.tracingOffset ?? 0) + Double(value.translation.width / scale))
                                dragOffset = 0
                            })
                        .simultaneousGesture(RotationGesture()
                            .onChanged { turnOffset = $0.degrees }
                            .onEnded { value in
                                let raw = (store.bigTop.tracingAngle ?? 0) + value.degrees
                                store.turnBigTopTracingPaper((raw.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360))
                                turnOffset = 0
                            })
                        .accessibilityElement()
                        .accessibilityLabel("Tracing paper with two registration holes")
                        .accessibilityValue("Rotated \(Int(paperAngle)) degrees, slid \(Int(paperOffset)) units")
                        .accessibilityAdjustableAction { direction in
                            switch direction {
                            case .increment: store.turnBigTopTracingPaper(min(360, paperAngle + 15))
                            case .decrement: store.turnBigTopTracingPaper(max(0, paperAngle - 15))
                            @unknown default: break
                            }
                        }
                        .accessibilityAction(named: Text("Slide right")) { store.slideBigTopTracingPaper((store.bigTop.tracingOffset ?? 0) + 5) }
                        .accessibilityAction(named: Text("Slide left")) { store.slideBigTopTracingPaper((store.bigTop.tracingOffset ?? 0) - 5) }
                        .position(x: (151 + paperOffset) * scale, y: 106 * scale)
                }
                ForEach(0..<8, id: \.self) { index in
                    let column = index % 4
                    let row = index / 4
                    Button {
                        if index == 6 { store.openBigTopMenuDrawer() }
                    } label: {
                        Color.clear.frame(width: 25 * scale, height: 14 * scale)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .position(x: (157 + CGFloat(column) * 25.5) * scale,
                                  y: (131 + CGFloat(row) * 18.2) * scale)
                        .accessibilityLabel("\(row == 0 ? "Upper" : "Lower") row, cabinet \(column + 1)")
                }
                if store.bigTop.menuDrawerOpen == true && !store.bigTop.menuTaken {
                    Button(action: store.takeBigTopMenu) {
                        Color.clear.frame(width: 29 * scale, height: 17 * scale).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .position(x: 207 * scale, y: 142 * scale)
                        .accessibilityLabel("Take the folded menu")
                }
            }.frame(width: 320 * scale, height: 160 * scale)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}
