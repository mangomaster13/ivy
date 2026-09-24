import XCTest
@testable import Ivy

@MainActor
final class FerrisPuzzleTests: XCTestCase {
    func testPlaylistTicketCameraAndLegacyRestore() throws {
        let suite = "ivy.ferris.tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = GameStore(defaults: defaults)
        store.isIntro = false
        store.prefersReducedMotion = true
        store.room = .ferris
        store.overlay = .none
        store.openMemory(.ferrisCabin)
        XCTAssertEqual(store.overlay, .none)
        store.openMemory(.ferris)
        store.memories.ferrisMatches = [0, 1]
        store.solveLater(.ferris)
        store.collectPhysical(.ferris)
        XCTAssertFalse(store.collected.contains(.ferris), "The retired ticket pair must not bypass the camera")
        store.memories.ferrisMatches = []
        store.submitFerrisPlaylist()
        XCTAssertFalse(store.ferris.playlistSolved)
        store.moveFerrisSong(0, to: 0)
        let draft = store.ferris.order
        store.moveFerrisSong(99, to: 1)
        store.moveFerrisSong(0, to: 5)
        XCTAssertEqual(store.ferris.order, draft)
        store.persistNow()
        XCTAssertEqual(GameStore(defaults: defaults).ferris.order, draft)
        for song in 0..<5 { store.moveFerrisSong(song, to: song) }
        store.submitFerrisPlaylist()
        XCTAssertEqual(store.overlay, .memory(.ferrisTicket))
        XCTAssertFalse(store.exploration.tools.contains(.ferrisTicket))
        store.takeFerrisTicket()
        XCTAssertNil(store.selectedTool)
        store.openMemory(.ferrisGate)
        store.enterFerrisCabin()
        XCTAssertEqual(store.overlay, .memory(.ferrisGate))
        store.useFerrisTicket()
        XCTAssertFalse(store.ferris.ticketUsed)
        store.chooseTool(.ferrisTicket)
        store.useFerrisTicket()
        XCTAssertTrue(store.ferris.ticketUsed)
        XCTAssertFalse(store.exploration.tools.contains(.ferrisTicket))
        store.enterFerrisCabin()
        store.takeFerrisSelfie()
        XCTAssertFalse(store.collected.contains(.ferris))
        store.takeFerrisPhone()
        store.openFerrisCamera()
        XCTAssertEqual(store.overlay, .memory(.ferrisCabin))
        store.chooseTool(.ferrisPhone)
        store.openFerrisCamera()
        store.takeFerrisSelfie()
        XCTAssertEqual(store.overlay, .observation(.ferris))
        XCTAssertTrue(store.collected.contains(.ferris))
        XCTAssertFalse(store.exploration.tools.contains(.ferrisPhone))
        store.takeFerrisSelfie()
        XCTAssertEqual(store.collected.filter { $0 == .ferris }.count, 1)
        let restored = GameStore(defaults: defaults)
        XCTAssertTrue(restored.ferris.photoTaken)
        XCTAssertTrue(restored.ferris.ticketUsed)
        XCTAssertFalse(restored.exploration.tools.contains(.ferrisTicket))

        // Optional record decodes old saves; a damaged new draft cannot discard old ownership.
        var old = MemoryProgress()
        old.opened.insert("ferris")
        store.memories = try JSONDecoder().decode(MemoryProgress.self, from: JSONEncoder().encode(old))
        XCTAssertNil(store.memories.ferris)
        store.collected = [.letter]
        store.migrateFerris()
        XCTAssertEqual(store.collected, [.letter, .ferris])
        XCTAssertTrue(store.ferris.ticketUsed)
        let damaged = Data(#"{"order":[99,99],"ticketUsed":true}"#.utf8)
        let recovered = try JSONDecoder().decode(FerrisProgress.self, from: damaged)
        XCTAssertEqual(recovered.order, Array(0..<5))
        XCTAssertTrue(recovered.ticketTaken)
        XCTAssertFalse(recovered.photoTaken)
    }
}
