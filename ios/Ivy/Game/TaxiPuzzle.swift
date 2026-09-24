import Foundation

struct TaxiProgress: Codable, Equatable {
    // A is already marked as the departure point on the physical route board.
    var route = [0]
    var cardTaken = false
    var arrived = false
    var receiptPrinted = false
    var receiptTaken = false

    static let homeRoute = [0, 1, 4, 3, 6] // A → B → E → D → G
    static let roads: [Int: Set<Int>] = [
        0: [1, 2], 1: [3, 4], 2: [5], 3: [6], 4: [3, 5], 5: [6]
    ]

    private enum CodingKeys: String, CodingKey {
        case route, cardTaken, arrived, receiptPrinted, receiptTaken
    }

    init() {}

    init(from decoder: Decoder) throws {
        guard let values = try? decoder.container(keyedBy: CodingKeys.self) else { return }
        route = (try? values.decode([Int].self, forKey: .route)) ?? [0]
        cardTaken = (try? values.decode(Bool.self, forKey: .cardTaken)) ?? false
        arrived = (try? values.decode(Bool.self, forKey: .arrived)) ?? false
        receiptPrinted = (try? values.decode(Bool.self, forKey: .receiptPrinted)) ?? false
        receiptTaken = (try? values.decode(Bool.self, forKey: .receiptTaken)) ?? false
        sanitize()
    }

    mutating func sanitize() {
        if !(route.first == 0 && route.count <= 7 &&
              Set(route).count == route.count &&
              zip(route, route.dropFirst()).allSatisfy({ edge in Self.roads[edge.0]?.contains(edge.1) == true })) {
            route = [0]
        }
        if receiptTaken { receiptPrinted = true }
        if receiptPrinted { arrived = true }
        if arrived { cardTaken = true; route = Self.homeRoute }
    }
}

extension GameStore {
    var taxi: TaxiProgress {
        get { memories.taxi ?? TaxiProgress() }
        set { memories.taxi = newValue }
    }

    func takeTaxiCard() {
        guard room == .taxi, overlay == .memory(.taxiCard), !taxi.cardTaken else { return }
        taxi.cardTaken = true
        discover(.taxiRoute)
        persistNow()
    }

    func extendTaxiRoute(to node: Int) {
        guard room == .taxi, overlay == .memory(.taxi), taxi.cardTaken,
              !taxi.arrived, collectingEgg == nil, let last = taxi.route.last,
              TaxiProgress.roads[last]?.contains(node) == true,
              !taxi.route.contains(node) else { return }
        taxi.route.append(node)
        if node == 6 && taxi.route == TaxiProgress.homeRoute {
            taxi.arrived = true
            memories.opened.insert("taxi")
            IvyHaptics.success()
            backFromMemory()
        } else if node == 6 {
            showWrongAnswer()
        } else {
            dismissSceneHint()
        }
        persistNow()
    }

    func undoTaxiRoute() {
        guard room == .taxi, overlay == .memory(.taxi), !taxi.arrived,
              taxi.route.count > 1 else { return }
        taxi.route.removeLast()
        dismissSceneHint()
        persistNow()
    }

    func takeTaxiReceipt() {
        guard room == .taxi, overlay == .memory(.taxiReceipt),
              taxi.arrived, taxi.receiptPrinted, !taxi.receiptTaken,
              collectingEgg == nil else { return }
        taxi.receiptTaken = true
        collect(.taxi)
        persistNow()
    }

    func migrateTaxi() {
        var progress = taxi
        if memories.taxi == nil && (memories.opened.contains("taxi") || collected.contains(.taxi)) {
            progress.arrived = true
            progress.receiptPrinted = true
        }
        if collected.contains(.taxi) { progress.receiptTaken = true }
        progress.sanitize()
        taxi = progress
        if progress.cardTaken { exploration.clues.insert(.taxiRoute) }
        if progress.arrived { memories.opened.insert("taxi") }
    }
}
