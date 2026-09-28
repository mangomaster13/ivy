import SwiftUI

/// Coordinates measured from the generated originals, not their requested prompt positions.
/// All artwork/hits use the root's fitted 320×160 canvas. At a 512×256 stage the
/// six bottom targets have 80pt spacing; the closest rack rows are 78pt apart.
enum PerfumeLabLayout {
    static let sampleX: [CGFloat] = [74, 156, 234]
    static let paperX: [CGFloat] = [102, 186, 263]
    static let cupX: [CGFloat] = [70, 120, 171]
    static func sample(_ index: Int) -> CGPoint { CGPoint(x: sampleX[index % 3], y: index < 3 ? 40 : 89) }
    static func paper(_ index: Int) -> CGPoint { CGPoint(x: paperX[index % 3], y: index < 3 ? 54 : 103) }
    static func tag(_ index: Int) -> CGPoint { CGPoint(x: 27 + CGFloat(index) * 53, y: 141) }
}

private func labArt(_ name: String, at point: CGPoint, width: CGFloat, height: CGFloat, scale: CGFloat) -> some View {
    Image(name).resizable().interpolation(.high).scaledToFit()
        .frame(width: width * scale, height: height * scale)
        .position(x: point.x * scale, y: point.y * scale)
        .allowsHitTesting(false).accessibilityHidden(true)
}

struct PerfumeLaboratoryView: View {
    @Bindable var store: GameStore
    let panel: MemoryPanel
    @State private var selectedLabel: AdventureTool?
    @State private var selectedSample: Int?

    var body: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let scale = geometry.size.width / 320
                ZStack {
                    if panel == .perfumeFormula {
                        PerfumeLabRecordArtwork(store: store, page: store.perfumeLab.recordPage)
                    } else if panel == .perfumeLab {
                        Image("ll5-samples").resizable().scaledToFit().accessibilityHidden(true)
                        samples(scale: scale)
                    } else {
                        Image("ll5-blending").resizable().scaledToFit().accessibilityHidden(true)
                        blending(scale: scale)
                        SceneFeedback(store: store, height: 36)
                            .frame(width: geometry.size.width * 0.66)
                            .position(x: geometry.size.width * 0.34, y: 17 * scale)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .gameBackAction(store.backFromMemory)
        .onDisappear { selectedLabel = nil; selectedSample = nil }
        .onChange(of: store.selectedTool) { _, tool in
            if tool != nil { selectedLabel = nil; selectedSample = nil }
        }
        .preference(key: GamePageNavigationKey.self, value: panel == .perfumeFormula ? GamePageNavigation(
            canGoPrevious: store.perfumeLab.recordPage > 0,
            canGoNext: store.perfumeLab.recordPage < 2,
            previous: { store.readPerfumeLabPage(store.perfumeLab.recordPage - 1) },
            next: { store.readPerfumeLabPage(store.perfumeLab.recordPage + 1) }
        ) : nil)
    }

    private func hit(_ label: String, at point: CGPoint, width: CGFloat = 36, height: CGFloat = 30,
                     scale: CGFloat, drag: String = "", drop: @escaping ([String]) -> Bool = { _ in false },
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Color.clear.frame(width: max(48, width * scale), height: max(48, height * scale)).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(label)
            .draggable(drag)
            .dropDestination(for: String.self) { items, _ in drop(items) }
            .position(x: point.x * scale, y: point.y * scale)
    }

    @ViewBuilder private func samples(scale: CGFloat) -> some View {
        ForEach(0..<6) { index in
            let point = PerfumeLabLayout.sample(index)
            let mark = store.perfumeLab.visibleMark(at: index)
            let guess = store.perfumeLab.labels[index]
            if let mark {
                labArt("ll5-mark-" + mark.rawValue, at: PerfumeLabLayout.paper(index), width: 9, height: 13, scale: scale)
            }
            if let guess {
                labArt("ll4-label-" + guess.rawValue,
                       at: CGPoint(x: point.x, y: index < 3 ? 66 : 117), width: 49, height: 10, scale: scale)
            }
            hit("Sample " + PerfumeLaboratory.sampleName(index), at: point, width: 51, height: 42, scale: scale,
                drag: guess.map { "ivy-perfume-label:" + $0.rawValue } ?? "", drop: { items in
                guard let token = items.first else { return false }
                if token == "ivy-tool:scentPaper" {
                    store.chooseTool(.scentPaper); store.samplePerfume(index); return true
                }
                guard token.hasPrefix("ivy-perfume-label:"),
                      let label = AdventureTool(rawValue: String(token.dropFirst("ivy-perfume-label:".count))),
                      PerfumeLaboratory.materials.contains(label) else { return false }
                store.labelPerfume(label, at: index); return true
            }) {
                if let selectedLabel {
                    store.labelPerfume(guess == selectedLabel ? nil : selectedLabel, at: index)
                    self.selectedLabel = nil
                } else if store.selectedTool != .scentPaper, let guess {
                    selectedLabel = guess
                } else { store.samplePerfume(index) }
            }
            .accessibilityValue((mark.map { "Paper: " + $0.rawValue } ?? "Untested") +
                                (guess.map { "; your label: " + $0.label } ?? "; no label"))
            .accessibilityAction(named: "Remove your label") { store.labelPerfume(nil, at: index) }

        }
        ForEach(Array(PerfumeLaboratory.materials.enumerated()), id: \.offset) { index, material in
            let point = PerfumeLabLayout.tag(index)
            if !store.perfumeLab.labels.contains(material) {
                labArt("ll4-label-" + material.rawValue, at: point, width: 48, height: 16, scale: scale)
                hit(material.label, at: point, width: 48, height: 22, scale: scale, drag: "ivy-perfume-label:" + material.rawValue) {
                    store.selectedTool = nil
                    selectedLabel = selectedLabel == material ? nil : material
                }
                .accessibilityValue(selectedLabel == material ? "Selected label" : "Label")
            }
            if selectedLabel == material && !store.perfumeLab.labels.contains(material) {
                Image("ui-storybook-page").resizable().scaledToFit()
                    .frame(width: 7 * scale, height: 7 * scale).rotationEffect(.degrees(90))
                    .position(x: point.x * scale, y: 129 * scale).allowsHitTesting(false).accessibilityHidden(true)
            }
        }
        if !store.perfumeLab.papersTaken && !store.perfumeLab.complete {
            labArt("ll5-paper-tool", at: CGPoint(x: 308, y: 31), width: 17, height: 24, scale: scale)
            hit("Take scent papers", at: CGPoint(x: 306, y: 31), width: 28, scale: scale, action: store.takeScentPapers)
        }
    }

    @ViewBuilder private func blending(scale: CGFloat) -> some View {
        ForEach(0..<3) { cup in
            let bottle = PerfumeLaboratory.bottles[cup]
            let x = PerfumeLabLayout.cupX[cup]
            if store.perfumeLab.produced.contains(bottle) {
                // Remove the completed cup using the matching empty-tray artwork.
                Image("ll5-empty-tray").resizable().scaledToFit()
                    .mask {
                        Rectangle().frame(width: 49 * scale, height: 57 * scale)
                            .position(x: x * scale, y: 87 * scale)
                    }.allowsHitTesting(false).accessibilityHidden(true)
                if !store.perfumeLab.taken.contains(bottle) {
                    labArt(bottle.fragranceImageName, at: CGPoint(x: x, y: 91), width: 30, height: 41, scale: scale)
                    hit("Take " + bottle.label, at: CGPoint(x: x, y: 91), width: 38, height: 46, scale: scale) {
                        store.takeLaboratoryPerfume(bottle)
                    }
                }
            } else {
                let pair = store.perfumeLab.batches[cup]
                ForEach(Array(pair.enumerated()), id: \.offset) { position, sample in
                    labArt("ll5-id-" + PerfumeLaboratory.sampleName(sample),
                           at: CGPoint(x: x + (position == 0 ? -8 : 8), y: 95), width: 10, height: 11, scale: scale)
                }
                hit(PerfumeFormula.all[cup].name + " blending cup", at: CGPoint(x: x, y: 93), width: 45, height: 43, scale: scale,
                    drop: { items in
                    guard let value = items.first, value.hasPrefix("ivy-perfume-sample:"),
                          let index = Int(value.dropFirst("ivy-perfume-sample:".count)), (0..<6).contains(index) else { return false }
                    store.placePerfumeSample(index, in: cup); return true
                }) {
                    if let selectedSample {
                        store.placePerfumeSample(selectedSample, in: cup)
                        self.selectedSample = nil
                    } else if let last = pair.last { store.removePerfumeSample(last, from: cup) }
                }
                .accessibilityValue(pair.map(PerfumeLaboratory.sampleName).joined(separator: ", "))
                .accessibilityAction(named: "Remove first sample") {
                    if let first = pair.first { store.removePerfumeSample(first, from: cup) }
                }

            }
        }
        if !store.perfumeLab.complete {
            ForEach(0..<6) { index in
                let point = CGPoint(x: PerfumeLabLayout.tag(index).x, y: 139)
                labArt("ll5-token-" + PerfumeLaboratory.sampleName(index), at: point, width: 12, height: 36, scale: scale)
                if let mark = store.perfumeLab.visibleMark(at: index) {
                    labArt("ll5-mark-" + mark.rawValue, at: CGPoint(x: point.x, y: 145), width: 8, height: 8, scale: scale)
                }
                hit("Sample " + PerfumeLaboratory.sampleName(index), at: point, width: 46, height: 36, scale: scale, drag: "ivy-perfume-sample:" + String(index)) {
                    selectedSample = selectedSample == index ? nil : index
                }
                .accessibilityValue(selectedSample == index ? "Selected" : "")
                if selectedSample == index {
                    Image("ui-storybook-page").resizable().scaledToFit()
                        .frame(width: 7 * scale, height: 7 * scale).rotationEffect(.degrees(90))
                        .position(x: point.x * scale, y: 116 * scale).allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            hit("Press the bottling handle", at: CGPoint(x: 232, y: 28), width: 48, height: 39, scale: scale,
                action: store.submitPerfumeLaboratory)
        }
    }
}

/// The same authored evidence appears in the physical book and Notes.
struct PerfumeLabRecordArtwork: View {
    let store: GameStore
    let page: Int

    var body: some View {
        FittedSceneStage {
            GeometryReader { geometry in
                let s = geometry.size.width / 320
                ZStack {
                    Image(recordImage).resizable().interpolation(.high)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .accessibilityHidden(true)
                    if page == 4 {
                        // Only the player's discovered sample marks remain dynamic.
                        ForEach(0..<6) { index in
                            let x: CGFloat = index < 3 ? 87 : 234
                            let y = CGFloat(40 + (index % 3) * 35)
                            if let mark = store.perfumeLab.visibleMark(at: index) {
                                labArt("ll5-id-" + PerfumeLaboratory.sampleName(index), at: CGPoint(x: x - 29, y: y), width: 18, height: 18, scale: s)
                                labArt("ll5-mark-" + mark.rawValue, at: CGPoint(x: x + 23, y: y), width: 25, height: 25, scale: s)
                            }
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(evidenceDescription)
            }
        }
    }

    private var recordImage: String {
        switch page {
        case 0: "ll5-record-wood"
        case 1: "ll5-record-citrus"
        case 2: "ll5-record-recipes"
        case 3: "ll5-record-reference"
        default: "ll4-notes"
        }
    }

    private var evidenceDescription: String {
        switch page {
        case 0: store.clueText(.perfumeTrialsWood) + " " + store.clueText(.perfumeReference)
        case 1: store.clueText(.perfumeTrialsCitrus)
        case 2: PerfumeFormula.all.map { store.clueText($0.clue) }.joined(separator: ". ")
        case 3: store.clueText(.perfumeReference)
        default: store.clueText(.perfumeSamples)
        }
    }
}

struct PerfumeLabWorldControls: View {
    let store: GameStore
    var body: some View {
        GeometryReader { geometry in
            let s = geometry.size.width / 320
            if !store.perfumeLab.papersTaken && !store.perfumeLab.complete {
                Button(action: store.takeScentPapers) {
                    Color.clear.frame(width: max(48, 34 * s), height: max(48, 22 * s)).contentShape(Rectangle())
                }.buttonStyle(.plain).position(x: 88 * s, y: 134 * s).accessibilityLabel("Take scent papers")
            }
        }
    }
}

struct PerfumeLabWorldArtwork: View {
    let store: GameStore
    var body: some View {
        GeometryReader { geometry in
            let s = geometry.size.width / 320
            ZStack {
                labArt("ll5-observation-0", at: CGPoint(x: 47, y: 87), width: 40, height: 6, scale: s)
                labArt("ll5-observation-1", at: CGPoint(x: 43, y: 108), width: 42, height: 6, scale: s)
                ForEach(0..<2) { row in
                    labArt("ll5-mark-branch", at: CGPoint(x: 35, y: CGFloat(98 + row * 21)), width: 8, height: 9, scale: s)
                    labArt(row == 0 ? "ll5-mark-rings" : "ll5-mark-waves",
                           at: CGPoint(x: 50, y: CGFloat(98 + row * 21)), width: 8, height: 9, scale: s)
                }
                labArt("ll5-reference-name", at: CGPoint(x: 82, y: 88), width: 24, height: 4, scale: s)
                labArt("ll5-mark-branch", at: CGPoint(x: 82, y: 106), width: 13, height: 15, scale: s)
                ForEach(Array(PerfumeLaboratory.materials.enumerated()), id: \.offset) { index, material in
                    if !store.perfumeLab.labels.contains(material) && !store.perfumeLab.complete {
                        labArt("ll4-label-" + material.rawValue, at: CGPoint(x: 129 + CGFloat(index) * 25, y: 141), width: 23, height: 10, scale: s)
                    }
                }
                if store.perfumeLab.papersTaken {
                    Image("ll5-overview-empty").resizable().scaledToFit()
                        .mask {
                            Rectangle().frame(width: 39 * s, height: 23 * s).position(x: 88 * s, y: 130 * s)
                        }
                }
                ForEach(0..<3) { cup in
                    let bottle = PerfumeLaboratory.bottles[cup]
                    let x = CGFloat(216 + cup * 21)
                    if store.perfumeLab.produced.contains(bottle) {
                        Image("ll5-overview-empty").resizable().scaledToFit()
                            .mask {
                                Rectangle().frame(width: 21 * s, height: 30 * s).position(x: x * s, y: 91 * s)
                            }
                        if !store.perfumeLab.taken.contains(bottle) {
                            labArt(bottle.fragranceImageName, at: CGPoint(x: x, y: 94), width: 13, height: 20, scale: s)
                        }
                    }
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}
