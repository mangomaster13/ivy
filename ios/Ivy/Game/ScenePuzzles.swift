import SwiftUI

/// The order on the counter is fixed; the remembered pair is order independent.
enum GelatoFlavor: String, CaseIterable, Codable, Identifiable {
    case pistachio, vanilla, mango, chocolate, stracciatella, matcha
    var id: String { rawValue }
    static let correct: Set<Self> = [.pistachio, .stracciatella]
    var label: String { self == .chocolate ? "dark chocolate" : rawValue }

}

enum MemoryObject: String, Identifiable {
    case boardingPass, lock, keycard, window, rose, petal, gelato
    var id: String { rawValue }
    var label: String {
        switch self {
        case .boardingPass: "Boarding pass"
        case .lock: "Four brass number wheels"
        case .keycard: "Keycard on the console"
        case .window: "Look out across the harbour"
        case .rose: "Plush rose on the bed"
        case .petal: "A loose plush petal on the nightstand"
        case .gelato: "Gelato counter"
        }
    }
}

struct MemoryHotspot: Identifiable {
    let object: MemoryObject
    let rect: CGRect
    var id: String { object.id }
}

enum WonderlandLayout {
    // Match art/room/rose-bed/placement-reference.png: heads left of the pillow,
    // horizontal wrapper and stems along its lower-left edge. Artwork and hit region agree.
    static let rose = CGRect(x: 201, y: 96, width: 44, height: 20)
    static let petal = CGRect(x: 276, y: 100, width: 10, height: 9)
    static func objects(in room: Room, petalAvailable: Bool) -> [MemoryHotspot] {
        switch room {
        case .plane: []
        case .corridor: [MemoryHotspot(object: .lock, rect: CGRect(x: 193, y: 51, width: 27, height: 18)),
                         MemoryHotspot(object: .keycard, rect: CGRect(x: 214, y: 78, width: 11, height: 7))]
        case .bedroom:
            [MemoryHotspot(object: .window, rect: CGRect(x: 100, y: 15, width: 159, height: 72)),
             MemoryHotspot(object: .rose, rect: rose)] + (petalAvailable ? [MemoryHotspot(object: .petal, rect: petal)] : [])
        case .gelato: [MemoryHotspot(object: .gelato, rect: CGRect(x: 103, y: 72, width: 88, height: 27))]
        default: []
        }
    }
}

extension GameStore {
    var petalAvailable: Bool { false }
    var memoryHotspots: [MemoryHotspot] {
        guard sceneView == 0 else { return [] }
        return WonderlandLayout.objects(in: room, petalAvailable: petalAvailable).filter {
            $0.object != .keycard || (corridorUnlocked && !collected.contains(.keycard))
        }
    }
    var hasMemoryOverlay: Bool {
        switch overlay {
        case .hotelLock, .rose, .gelato, .observation, .adventure, .memory: true
        default: false
        }
    }

    func tapMemory(_ object: MemoryObject) {
        guard !isHallTransitioning, collectingEgg == nil,
              memoryHotspots.contains(where: { $0.object == object }) else { return }
        sceneHint = ""
        IvyHaptics.light()
        switch object {
        case .boardingPass: openMemory(.ticket)
        case .lock:
            if !corridorUnlocked { corridorMiss = false; overlay = .hotelLock }
            else if !collected.contains(.keycard) { openMemory(.keycard) }
            else { dismissSceneHint() }
        case .keycard:
            guard corridorUnlocked else { return }
            openMemory(.keycard)
        case .window: openMemory(.city)
        case .rose: openMemory(.bouquet)
        case .petal: openMemory(.bouquet)
        case .gelato: openMemory(.tasting)
        }
    }

    func turnHotelWheel(_ index: Int, by delta: Int) {
        guard room == .corridor, overlay == .hotelLock, !corridorUnlocked,
              corridorDigits.indices.contains(index) else { return }
        corridorDigits[index] = (corridorDigits[index] + delta + 10) % 10
        corridorMiss = false
        sceneHint = ""
        IvyHaptics.light()
        persistNow()
    }

    func submitHotelCode() {
        guard room == .corridor, overlay == .hotelLock, !corridorUnlocked else { return }
        guard corridorDigits == exploration.hotelCode else {
            corridorMiss = true
            dismissSceneHint()
            IvyHaptics.warning()
            return
        }
        corridorUnlocked = true
        keycardJustDispensed = true
        corridorMiss = false
        overlay = .memory(.keycard)
        sceneHint = ""
        IvyHaptics.success()
        persistNow()
    }
    func selectGelato(_ flavor: GelatoFlavor) {
        guard room == .gelato, overlay == .gelato, !collected.contains(.gelato), collectingEgg == nil else { return }
        guard exploration.tools.contains(.scoop), exploration.freezerTemperature == -12 else { return }
        guard exploration.scoops.count < 3 else { IvyHaptics.light(); return }
        exploration.scoops.append(flavor)
        sceneHint = ""
        IvyHaptics.light()
        persistNow()
    }

    func showSceneHint(_ text: String, tone: IvyMessageTone = .ordinary, presentation: IvyMessagePresentation = .puzzle) {
        sceneHintPresentation = presentation
        sceneHintTone = tone
        sceneHint = text
        // Use the shared caption clock; repeated misses restart the hold.
        revealSceneCaption(text)
    }
}
