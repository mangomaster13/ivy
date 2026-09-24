import CoreGraphics
import Foundation

/// One walkable object on a 320×160 plate. Never a map pin or a prev/next control.
struct DiegeticHotspot: Identifiable, Equatable {
    /// Stable identity for canvas `ForEach`.
    var id: String { edge.rawValue }
    /// Graph edge this object walks.
    let edge: DiegeticEdge
    /// Rectangle in game pixels.
    let rect: CGRect
    /// VoiceOver name. English, no room title.
    let label: String
}

/// Object that walks the Wonderland line. Names the thing, not the room.
enum DiegeticEdge: String, Equatable {
    case hallExit, hallHole
    case planeHole, planeDepart
    case corridorBack, corridorForward
    case bedroomBack, bedroomForward
    case gelatoBack, gelatoForward
    case noodleBack, noodleForward
    case perfumeBack, perfumeForward
    case cinemaBack, cinemaExit
    case sunsetBack, sunsetForward
    case ferrisBack, ferrisForward
    case taxiBack, taxiDoor
}

/// Pure destinations and hotspot layout. Store calls this; views do not keep a second map.
enum RoomGraph {
    /// Left-strip object: the way you came.
    static let back = CGRect(x: 8, y: 56, width: 44, height: 48)
    /// Right-strip object: the way on.
    static let forward = CGRect(x: 268, y: 56, width: 44, height: 48)
    /// Floor void / car door.
    static let floor = CGRect(x: 138, y: 116, width: 44, height: 36)
    /// Hall grate already painted on `hall`.
    static let hallHole = CGRect(x: 167, y: 118, width: 74, height: 26)

    /// Next room, or nil when the object is locked or does not belong here.
    static func destination(
        from room: Room,
        edge: DiegeticEdge,
        corridorUnlocked: Bool
    ) -> Room? {
        switch (room, edge) {
        case (.hall, .hallExit): return .yard
        case (.hall, .hallHole): return .plane
        case (.plane, .planeHole): return .hall
        case (.plane, .planeDepart): return .corridor
        case (.corridor, .corridorBack): return .plane
        case (.corridor, .corridorForward): return corridorUnlocked ? .bedroom : nil
        case (.bedroom, .bedroomBack): return .corridor
        case (.bedroom, .bedroomForward): return .gelato
        case (.gelato, .gelatoBack): return .bedroom
        case (.gelato, .gelatoForward): return .noodle
        case (.noodle, .noodleBack): return .gelato
        case (.noodle, .noodleForward): return .perfume
        case (.perfume, .perfumeBack): return .noodle
        case (.perfume, .perfumeForward): return .cinema
        case (.cinema, .cinemaBack): return .perfume
        case (.cinema, .cinemaExit): return .dictionary
        case (.dictionary, .sunsetBack): return .cinema
        case (.dictionary, .sunsetForward): return .ferris
        case (.ferris, .ferrisBack): return .dictionary
        case (.ferris, .ferrisForward): return .taxi
        case (.taxi, .taxiBack): return .ferris
        case (.taxi, .taxiDoor): return .hall
        default: return nil
        }
    }

    /// Diegetic objects painted on this plate. Yard is not listed; it keeps its own hotspots.
    static func hotspots(in room: Room) -> [DiegeticHotspot] {
        switch room {
        case .yard:
            return []
        case .hall:
            return [
                DiegeticHotspot(edge: .hallExit, rect: RoomHotspots.hallExit, label: "Door to the yard"),
                DiegeticHotspot(edge: .hallHole, rect: hallHole, label: "Rabbit hole")
            ]
        case .plane:
            return [
                DiegeticHotspot(edge: .planeHole, rect: CGRect(x: 37, y: 101, width: 60, height: 27), label: "The hole you came through"),
                DiegeticHotspot(edge: .planeDepart, rect: CGRect(x: 246, y: 23, width: 51, height: 91), label: "Boarding doorway")
            ]
        case .corridor:
            return [
                DiegeticHotspot(edge: .corridorBack, rect: CGRect(x: 20, y: 25, width: 58, height: 96), label: "Arrivals"),
                DiegeticHotspot(edge: .corridorForward, rect: CGRect(x: 239, y: 23, width: 53, height: 98), label: "Bedroom door")
            ]
        case .bedroom:
            return [
                DiegeticHotspot(edge: .bedroomBack, rect: CGRect(x: 16, y: 15, width: 40, height: 110), label: "Hotel door"),
                DiegeticHotspot(edge: .bedroomForward, rect: CGRect(x: 298, y: 78, width: 21, height: 62), label: "Umbrella")
            ]
        case .gelato:
            return [
                DiegeticHotspot(edge: .gelatoBack, rect: CGRect(x: 4, y: 37, width: 56, height: 108), label: "Steps back to the hotel room"),
                DiegeticHotspot(edge: .gelatoForward, rect: CGRect(x: 257, y: 15, width: 51, height: 28), label: "Big Top neon sign")
            ]
        case .noodle:
            return [
                DiegeticHotspot(edge: .noodleBack, rect: CGRect(x: 0, y: 36, width: 39, height: 89), label: "Door back to Gelato"),
                DiegeticHotspot(edge: .noodleForward, rect: CGRect(x: 271, y: 27, width: 47, height: 113), label: "Door to the sloping street")
            ]
        case .perfume:
            return [
                DiegeticHotspot(edge: .perfumeBack, rect: CGRect(x: 12, y: 45, width: 52, height: 92), label: "Big Top doorway"),
                DiegeticHotspot(edge: .perfumeForward, rect: CGRect(x: 165, y: 59, width: 48, height: 39), label: "Uphill path to the cinema")
            ]
        case .cinema:
            return [
                DiegeticHotspot(edge: .cinemaBack, rect: back, label: "Le Labo doorway"),
                DiegeticHotspot(edge: .cinemaExit, rect: forward, label: "EXIT")
            ]
        case .dictionary:
            return [
                DiegeticHotspot(edge: .sunsetBack, rect: back, label: "Cinema doors"),
                DiegeticHotspot(edge: .sunsetForward, rect: forward, label: "Ferris silhouette")
            ]
        case .ferris:
            return [
                DiegeticHotspot(edge: .ferrisBack, rect: back, label: "Orange glass"),
                DiegeticHotspot(edge: .ferrisForward, rect: forward, label: "Taxi queue")
            ]
        case .taxi:
            return [
                DiegeticHotspot(edge: .taxiBack, rect: back, label: "Rear window"),
                DiegeticHotspot(edge: .taxiDoor, rect: forward, label: "Car door")
            ]
        }
    }
}
