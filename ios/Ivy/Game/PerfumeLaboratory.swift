import Foundation

/// Fictional scent-paper marks, not a simulation of real perfume chemistry.
enum PerfumeScentMark: String, Codable {
    case branch, rings, waves, stars, dashes, mesh
}

enum PerfumeLaboratory {
    static func sampleName(_ index: Int) -> String { ["A", "B", "C", "D", "E", "F"].indices.contains(index) ? ["A", "B", "C", "D", "E", "F"][index] : "" }
    static let materials: [AdventureTool] = [.gaiacWood, .cedar, .incense, .bergamot, .oakmoss, .patchouli]
    static let bottles: [AdventureTool] = [.gaiac10, .bergamote22, .mousse30]
    static let recipes: [[AdventureTool]] = [[.gaiacWood, .incense], [.bergamot, .cedar], [.oakmoss, .patchouli]]
    static let observations: [[AdventureTool]] = [[.cedar, .incense], [.cedar, .patchouli],
                                               [.bergamot, .gaiacWood], [.bergamot, .oakmoss]]

    static func mark(for material: AdventureTool) -> PerfumeScentMark? {
        switch material {
        case .cedar: .branch
        case .incense: .rings
        case .patchouli: .waves
        case .bergamot: .stars
        case .gaiacWood: .dashes
        case .oakmoss: .mesh
        default: nil
        }
    }
}

/// A–F are stable positions. Player guesses never affect evidence or correctness.
struct PerfumeLabProgress: Codable, Equatable {
    var sampleOrder: [AdventureTool]
    var papersTaken = false
    var sampled: Set<Int> = []
    var labels: [AdventureTool?] = Array(repeating: nil, count: 6)
    var batches: [[Int]] = [[], [], []]
    // Legacy save field; the Cedar reference is now printed directly on page one.
    var referenceUnfolded = false
    var recordPage = 0
    var readPages: Set<Int> = []
    var produced: Set<AdventureTool> = []
    var taken: Set<AdventureTool> = []

    init(legacy: PerfumeProgress? = nil) {
        sampleOrder = PerfumeLaboratory.materials.shuffled()
        guard let legacy else { return }
        let known = legacy.found.union(legacy.mixture.compactMap { $0 })
        for (sample, material) in sampleOrder.enumerated() where known.contains(material) {
            sampled.insert(sample)
            labels[sample] = material
        }
        papersTaken = !sampled.isEmpty
        produced = legacy.brewed.intersection(PerfumeLaboratory.bottles)
        produced.formUnion(legacy.arrangement.compactMap { $0 }.filter(PerfumeLaboratory.bottles.contains))
        if legacy.arranged { produced = Set(PerfumeLaboratory.bottles) }
        // The old bench had one unclaimed output; all other brewed bottles were taken.
        taken = produced
        if let output = legacy.output, !legacy.arrangement.contains(output) { taken.remove(output) }
        if legacy.arranged { taken = produced }
        prepare()
    }

    var complete: Bool { Set(PerfumeLaboratory.bottles).isSubset(of: produced) }
    var pendingBottles: [AdventureTool] { PerfumeLaboratory.bottles.filter { produced.contains($0) && !taken.contains($0) } }

    /// Normalize persisted indices without shuffling an existing valid sample identity.
    mutating func prepare() {
        var used: Set<AdventureTool> = []
        var order: [AdventureTool?] = (0..<6).map { index in
            guard sampleOrder.indices.contains(index), PerfumeLaboratory.materials.contains(sampleOrder[index]),
                  used.insert(sampleOrder[index]).inserted else { return nil }
            return sampleOrder[index]
        }
        var remaining = PerfumeLaboratory.materials.filter { !used.contains($0) }.makeIterator()
        for index in order.indices where order[index] == nil { order[index] = remaining.next() }
        sampleOrder = order.compactMap { $0 }
        sampled = sampled.filter { (0..<6).contains($0) }
        produced.formIntersection(PerfumeLaboratory.bottles)
        taken.formIntersection(produced)
        recordPage = min(2, max(0, recordPage))
        readPages = readPages.filter { (0..<3).contains($0) }
        var seenLabels: Set<AdventureTool> = []
        labels = (0..<6).map { index in
            guard labels.indices.contains(index), let label = labels[index],
                  PerfumeLaboratory.materials.contains(label), seenLabels.insert(label).inserted else { return nil }
            return label
        }
        // Retained legacy products reserve their ingredients; their recipes need no replay.
        var usedSamples: Set<Int> = []
        let locked: [[Int]?] = PerfumeLaboratory.bottles.indices.map { cup in
            guard produced.contains(PerfumeLaboratory.bottles[cup]) else { return nil }
            let pair = PerfumeLaboratory.recipes[cup].compactMap { sampleOrder.firstIndex(of: $0) }
            usedSamples.formUnion(pair)
            return pair
        }
        batches = (0..<3).map { cup in
            if let pair = locked[cup] { return pair }
            guard batches.indices.contains(cup) else { return [] }
            var pair: [Int] = []
            for sample in batches[cup] where pair.count < 2 && (0..<6).contains(sample) {
                if usedSamples.insert(sample).inserted { pair.append(sample) }
            }
            return pair
        }
    }

    mutating func sample(_ index: Int) {
        guard papersTaken, sampleOrder.indices.contains(index), !complete else { return }
        sampled.insert(index)
    }

    func visibleMark(at index: Int) -> PerfumeScentMark? {
        guard sampled.contains(index), sampleOrder.indices.contains(index) else { return nil }
        return PerfumeLaboratory.mark(for: sampleOrder[index])
    }

    mutating func assignLabel(_ label: AdventureTool?, to index: Int) {
        guard !complete, labels.indices.contains(index) else { return }
        if let label, !PerfumeLaboratory.materials.contains(label) { return }
        if let label, let source = labels.firstIndex(of: label), source != index {
            labels.swapAt(source, index)
        } else {
            labels[index] = label
        }
    }

    mutating func placeSample(_ sample: Int, in cup: Int) {
        guard !complete, sampleOrder.indices.contains(sample), batches.indices.contains(cup),
              PerfumeLaboratory.bottles.indices.contains(cup),
              !produced.contains(PerfumeLaboratory.bottles[cup]), batches[cup].count < 2,
              !batches[cup].contains(sample) else { return }
        if let source = batches.firstIndex(where: { $0.contains(sample) }) {
            guard PerfumeLaboratory.bottles.indices.contains(source),
                  !produced.contains(PerfumeLaboratory.bottles[source]) else { return }
            batches[source].removeAll { $0 == sample }
        }
        batches[cup].append(sample)
    }

    mutating func removeSample(_ sample: Int, from cup: Int) {
        guard batches.indices.contains(cup), PerfumeLaboratory.bottles.indices.contains(cup),
              !produced.contains(PerfumeLaboratory.bottles[cup]) else { return }
        batches[cup].removeAll { $0 == sample }
    }

    /// The sole correctness gate: one whole-set result, without modifying a wrong draft.
    mutating func submit() -> Bool {
        guard !complete, batches.count == 3, sampleOrder.count == 6,
              Set(sampleOrder) == Set(PerfumeLaboratory.materials) else { return false }
        for cup in 0..<3 {
            let pair = batches[cup]
            guard pair.count == 2, pair.allSatisfy(sampleOrder.indices.contains),
                  Set(pair.map { sampleOrder[$0] }) == Set(PerfumeLaboratory.recipes[cup]) else { return false }
        }
        produced.formUnion(PerfumeLaboratory.bottles)
        return true
    }

    mutating func takeBottle(_ bottle: AdventureTool) -> Bool {
        guard PerfumeLaboratory.bottles.contains(bottle), produced.contains(bottle) else { return false }
        return taken.insert(bottle).inserted
    }
}

extension GameStore {
    var perfumeLab: PerfumeLabProgress {
        get { perfumery.laboratory ?? PerfumeLabProgress(legacy: perfumery) }
        set { perfumery.laboratory = newValue }
    }

    func preparePerfumeLaboratory() {
        if perfumery.laboratory == nil { perfumery.laboratory = PerfumeLabProgress(legacy: perfumery) }
        if collected.contains(.perfume) {
            perfumery.arranged = true
            perfumery.cinemaUnlocked = true
            perfumery.brewed.formUnion(PerfumeLaboratory.bottles)
            perfumery.arrangement = PerfumeLaboratory.bottles.map(Optional.some)
        }
        if perfumery.arranged || collected.contains(.perfume) {
            perfumeLab.produced = Set(PerfumeLaboratory.bottles)
            perfumeLab.taken = perfumeLab.produced
        }
        perfumeLab.prepare()
        // Old raw materials remain decodable/recorded but are now bench samples, not tools.
        exploration.tools.subtract(PerfumeIngredient.tools)
        if let selectedTool, selectedTool.ingredient != nil { self.selectedTool = nil }
        if perfumeLab.papersTaken && !perfumeLab.complete {
            exploration.tools.insert(.scentPaper)
        } else { exploration.tools.remove(.scentPaper) }
        if !perfumeLab.sampled.isEmpty { exploration.clues.insert(.perfumeSamples) }
        exploration.tools.subtract(PerfumeLaboratory.bottles)
        if !collected.contains(.perfume) {
            exploration.tools.formUnion(perfumeLab.taken.subtracting(perfumery.arrangement.compactMap { $0 }))
        }
    }

    private var canInspectPerfumeLab: Bool {
        !isIntro && !isHallTransitioning && collectingEgg == nil && room == .perfume && sceneView > 0
    }
    private var canChangePerfumeLab: Bool {
        canInspectPerfumeLab && !perfumery.arranged && !collected.contains(.perfume)
    }

    func takeScentPapers() {
        guard canChangePerfumeLab, !perfumeLab.papersTaken, !perfumeLab.complete,
              (overlay == .none && sceneView == 4) || overlay == .memory(.perfumeLab) else { return }
        perfumeLab.papersTaken = true
        acquire(.scentPaper)
        persistNow()
    }

    func samplePerfume(_ index: Int) {
        guard canChangePerfumeLab, overlay == .memory(.perfumeLab), (0..<6).contains(index),
              !perfumeLab.complete else { return }
        guard requireInteractionTool(.scentPaper, missing: "The samples are waiting for paper.") else { return }
        perfumeLab.sample(index)
        discover(.perfumeSamples)
        dismissSceneHint()
        persistNow()
    }

    func labelPerfume(_ material: AdventureTool?, at index: Int) {
        guard canChangePerfumeLab, overlay == .memory(.perfumeLab) else { return }
        perfumeLab.assignLabel(material, to: index)
        dismissSceneHint(); persistNow()
    }

    func placePerfumeSample(_ index: Int, in cup: Int) {
        guard canChangePerfumeLab, overlay == .memory(.perfumeMix) else { return }
        perfumeLab.placeSample(index, in: cup)
        dismissSceneHint(); persistNow()
    }

    func removePerfumeSample(_ index: Int, from cup: Int) {
        guard canChangePerfumeLab, overlay == .memory(.perfumeMix) else { return }
        perfumeLab.removeSample(index, from: cup)
        dismissSceneHint(); persistNow()
    }

    func submitPerfumeLaboratory() {
        guard canChangePerfumeLab, overlay == .memory(.perfumeMix), !perfumeLab.complete else { return }
        guard perfumeLab.batches.allSatisfy({ $0.count == 2 }) else {
            showSceneHint("The three cups are not yet filled.", presentation: .interaction)
            return
        }
        guard perfumeLab.submit() else {
            showSceneHint("The set does not match the formulas.", tone: .wrong)
            return
        }
        perfumery.brewed.formUnion(perfumeLab.produced)
        perfumery.output = nil
        perfumery.mixture = [nil, nil, nil]
        consume(.scentPaper)
        dismissSceneHint(); IvyHaptics.success(); persistNow()
    }

    func takeLaboratoryPerfume(_ bottle: AdventureTool) {
        guard canChangePerfumeLab, overlay == .memory(.perfumeMix), perfumeLab.takeBottle(bottle) else { return }
        if perfumery.output == bottle { perfumery.output = nil }
        acquire(bottle); persistNow()
    }

    func readPerfumeLabPage(_ page: Int) {
        guard canInspectPerfumeLab, overlay == .memory(.perfumeFormula), (0..<3).contains(page) else { return }
        perfumeLab.recordPage = page
        perfumeLab.readPages.insert(page)
        if page == 0 { discover(.perfumeTrialsWood); discover(.perfumeReference) }
        else if page == 1 { discover(.perfumeTrialsCitrus) }
        else { PerfumeFormula.all.forEach { discover($0.clue) } }
        persistNow()
    }
}
