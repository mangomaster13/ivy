import XCTest
@testable import Ivy

final class RoomGraphTests: XCTestCase {
    func testHallHoleGoesToPlaneNotHall() {
        XCTAssertEqual(
            RoomGraph.destination(from: .hall, edge: .hallHole, corridorUnlocked: false),
            .plane
        )
    }

    func testCinemaExitGoesToSunset() {
        XCTAssertEqual(
            RoomGraph.destination(from: .cinema, edge: .cinemaExit, corridorUnlocked: true),
            .dictionary
        )
        XCTAssertNil(
            RoomGraph.destination(from: .cinema, edge: .ferrisForward, corridorUnlocked: true)
        )
    }

    func testCorridorForwardNeedsUnlock() {
        XCTAssertNil(
            RoomGraph.destination(from: .corridor, edge: .corridorForward, corridorUnlocked: false)
        )
        XCTAssertEqual(
            RoomGraph.destination(from: .corridor, edge: .corridorForward, corridorUnlocked: true),
            .bedroom
        )
    }

    func testClimbOut() {
        XCTAssertEqual(
            RoomGraph.destination(from: .plane, edge: .planeHole, corridorUnlocked: false),
            .hall
        )
        XCTAssertEqual(
            RoomGraph.destination(from: .taxi, edge: .taxiDoor, corridorUnlocked: false),
            .hall
        )
    }

    func testEveryHongKongRoomHasBackAndForwardExceptHallRules() {
        let rooms: [Room] = [
            .plane, .corridor, .bedroom, .gelato, .noodle,
            .perfume, .cinema, .dictionary, .ferris, .taxi
        ]
        for room in rooms {
            let edges = RoomGraph.hotspots(in: room).map(\.edge)
            XCTAssertFalse(edges.isEmpty, "\(room)")
        }
        let hallEdges = RoomGraph.hotspots(in: .hall).map(\.edge)
        XCTAssertTrue(hallEdges.contains(.hallHole))
        XCTAssertTrue(hallEdges.contains(.hallExit))
    }
}
