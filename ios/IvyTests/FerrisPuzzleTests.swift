import XCTest
@testable import Ivy

@MainActor
final class FerrisPuzzleTests: XCTestCase {
    func testGateRequiresHeldTicketUntilUsed() {
        let suite = "ivy.ferris.gate.tests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = GameStore(defaults: defaults)
        store.isIntro = false
        store.room = .ferris
        store.overlay = .none

        for musicSolved in [false, true] {
            store.ferris.musicSolved = musicSolved
            store.openMemory(.ferrisGate)
            XCTAssertEqual(store.overlay, .none)
            XCTAssertFalse(store.sceneHint.isEmpty)
            XCTAssertTrue(store.memoryNavigation.isEmpty)
        }

        store.ferris.musicSolved = false
        store.openMemory(.ferris)
        store.openMemory(.ferrisGate)
        XCTAssertEqual(store.overlay, .memory(.ferris))
        XCTAssertTrue(store.memoryNavigation.isEmpty)

        store.ferris.ticketTaken = true
        store.exploration.tools.insert(.ferrisTicket)
        store.openMemory(.ferrisGate)
        XCTAssertEqual(store.overlay, .memory(.ferrisGate))
        XCTAssertNil(store.selectedTool)
        store.backFromMemory()
        XCTAssertEqual(store.overlay, .memory(.ferris))

        store.ferris.ticketUsed = true
        store.exploration.tools.remove(.ferrisTicket)
        store.openMemory(.ferrisGate)
        XCTAssertEqual(store.overlay, .memory(.ferrisGate))
        XCTAssertTrue(store.sceneHint.isEmpty)
    }

    func testFragmentChainNeedsEveryPaper() {
        let fragments = FerrisProgress.fragments
        var solutions: [[Int]] = []
        func join(_ phrase: [Int], remaining: [Int]) {
            if remaining.isEmpty {
                if phrase.last == 6 { solutions.append(phrase) }
                return
            }
            for index in remaining where fragments[index].first == phrase.last {
                join(phrase + fragments[index].dropFirst(), remaining: remaining.filter { $0 != index })
            }
        }
        join([0], remaining: Array(fragments.indices))
        XCTAssertEqual(solutions, [[0, 3, 2, 5, 0, 1, 4, 3, 6]])
        XCTAssertEqual(FerrisProgress.melody, solutions.first)
        XCTAssertEqual(fragments[0].last, fragments[1].first)
        XCTAssertFalse(fragments[2...].contains { $0.first == fragments[1].last },
                       "Taking the tempting E-B then B-D path leaves two unused papers")
    }

    // Runnable on request. This is a state/compatibility check, not gesture or layout acceptance.
    func testMusicTicketPostcardAndLegacyRestore() throws {
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
        store.tapDiegetic(.ferrisForward)
        XCTAssertEqual(store.room, .ferris)
        store.openMemory(.ferris)
        store.strikeFerrisNote(4)
        XCTAssertEqual(store.ferris.lastNote, 4)
        XCTAssertTrue(store.ferris.notes.isEmpty, "Exploration must not record an answer")
        store.toggleFerrisRecording()
        store.strikeFerrisNote(6)
        store.submitFerrisMusic()
        XCTAssertFalse(store.ferris.musicSolved)
        XCTAssertEqual(store.ferris.notes, [6], "Wrong complete attempts preserve the draft")
        store.strikeFerrisNote(99)
        XCTAssertEqual(store.ferris.notes, [6])
        store.persistNow()
        XCTAssertEqual(GameStore(defaults: defaults).ferris.notes, [6])
        store.undoFerrisNote()
        for note in [0, 3, 2, 5, 0, 1, 4, 3, 6] { store.strikeFerrisNote(note) }
        XCTAssertFalse(store.ferris.musicSolved, "No correct-prefix or automatic phrase completion")
        store.submitFerrisMusic()
        XCTAssertTrue(store.ferris.musicSolved)
        XCTAssertFalse(store.exploration.tools.contains(.ferrisTicket))
        store.openMemory(.ferrisTicket)
        store.takeFerrisTicket()
        XCTAssertNil(store.selectedTool)
        store.openMemory(.ferrisGate)
        store.useFerrisTicket()
        XCTAssertFalse(store.ferris.ticketUsed)
        store.chooseTool(.ferrisTicket)
        store.useFerrisTicket()
        XCTAssertTrue(store.ferris.ticketUsed)
        XCTAssertFalse(store.exploration.tools.contains(.ferrisTicket))
        store.enterFerrisCabin()
        XCTAssertEqual(store.overlay, .none, "The carriage is a main scene, not an inspection")
        XCTAssertEqual(store.sceneView, 2)
        XCTAssertTrue(store.memoryNavigation.isEmpty)
        store.turnView(-1)
        XCTAssertEqual(store.sceneView, 2, "Scene arrows cannot bypass the cabin door")
        store.changeFerrisHeight(Int.min)
        XCTAssertEqual(store.ferris.height, 0)
        store.changeFerrisHeight(1)
        store.changeFerrisHeight(1)
        store.changeFerrisHeight(1)
        XCTAssertEqual(store.ferris.height, 2)
        store.changeFerrisHeight(-1)
        XCTAssertEqual(store.ferris.height, 1)
        store.exitFerrisCabin()
        XCTAssertEqual(store.sceneView, 2, "The cabin cannot be left above the platform")
        let riding = GameStore(defaults: defaults)
        XCTAssertEqual(riding.sceneView, 2)
        XCTAssertEqual(riding.ferris.height, 1)
        XCTAssertFalse(store.exploration.tools.contains(.ferrisPostcard))
        store.openMemory(.ferrisCamera)
        XCTAssertEqual(store.overlay, .memory(.ferrisCamera))
        XCTAssertTrue(store.exploration.clues.contains(.ferrisHarbour))
        store.retrieveFerrisPostcard()
        XCTAssertFalse(store.ferris.cardRetrieved, "The card cannot be taken before stamping")
        XCTAssertFalse(store.exploration.tools.contains(.ferrisPostcard))
        store.pressFerrisPostcard()
        XCTAssertFalse(store.ferris.stamped)
        XCTAssertEqual(store.ferris.stamps, [2, 0, 1])
        for slot in 0..<3 { store.turnFerrisStamp(slot) }
        store.turnFerrisStamp(-1)
        store.turnFerrisStamp(0, by: Int.min)
        XCTAssertEqual(store.ferris.stamps, [0, 1, 2])
        store.pressFerrisPostcard()
        XCTAssertTrue(store.ferris.stamped)
        XCTAssertFalse(store.collected.contains(.ferris))
        XCTAssertFalse(store.exploration.tools.contains(.ferrisPostcard))
        store.retrieveFerrisPostcard()
        XCTAssertTrue(store.exploration.tools.contains(.ferrisPostcard))
        XCTAssertTrue(store.toolsVisible)
        XCTAssertNil(store.selectedTool)
        XCTAssertTrue(GameStore(defaults: defaults).exploration.tools.contains(.ferrisPostcard))
        store.backFromMemory()
        XCTAssertEqual(store.overlay, .none)
        XCTAssertEqual(store.sceneView, 2)
        store.changeFerrisHeight(-1)
        store.exitFerrisCabin()
        XCTAssertEqual(store.sceneView, 1)
        store.postFerrisPostcard()
        XCTAssertFalse(store.collected.contains(.ferris), "Posting still requires active tool selection")
        store.chooseTool(.ferrisPostcard)
        store.postFerrisPostcard()
        XCTAssertTrue(store.collected.contains(.ferris))
        XCTAssertTrue(store.ferris.exitUnlocked)
        XCTAssertFalse(store.exploration.tools.contains(.ferrisPostcard))
        XCTAssertFalse(store.toolsVisible)
        store.cancelOverlay()
        store.postFerrisPostcard()
        XCTAssertEqual(store.collected.filter { $0 == .ferris }.count, 1)
        let restored = GameStore(defaults: defaults)
        XCTAssertTrue(restored.ferris.posted)
        XCTAssertFalse(restored.exploration.tools.contains(.ferrisPostcard))

        let oldPhone = try JSONDecoder().decode(FerrisProgress.self, from: Data(#"{"playlistSolved":true,"ticketTaken":true,"ticketUsed":true,"phoneTaken":true}"#.utf8))
        XCTAssertTrue(oldPhone.postcardTaken)
        XCTAssertFalse(oldPhone.posted)
        let oldPhoto = try JSONDecoder().decode(FerrisProgress.self, from: Data(#"{"photoTaken":true}"#.utf8))
        XCTAssertTrue(oldPhoto.posted)
        XCTAssertTrue(oldPhoto.ticketUsed)
        XCTAssertTrue(oldPhoto.exitUnlocked)
        let damaged = try JSONDecoder().decode(FerrisProgress.self, from: Data(#"{"notes":[99,2,-1],"stamps":[99],"height":99,"ticketUsed":true}"#.utf8))
        XCTAssertTrue(damaged.musicSolved)
        XCTAssertEqual(damaged.stamps, [2, 0, 1])
        XCTAssertEqual(damaged.height, 2)
        XCTAssertFalse(damaged.posted)
        XCTAssertEqual(try JSONDecoder().decode(FerrisProgress.self, from: JSONEncoder().encode(oldPhoto)), oldPhoto)

        store.ferris = oldPhone
        store.collected = [.letter]
        store.memories.opened.remove("ferris")
        store.exploration.tools.insert(.ferrisPostcard)
        store.selectedTool = .ferrisPostcard
        store.migrateFerris()
        XCTAssertTrue(store.ferris.ticketUsed)
        XCTAssertFalse(store.ferris.stamped)
        XCTAssertFalse(store.exploration.tools.contains(.ferrisPostcard), "An old unstamped card now waits in the press")
        XCTAssertNil(store.selectedTool)

        store.memories = MemoryProgress()
        store.memories.ferrisMatches = [0, 1]
        store.collected = [.letter]
        store.exploration.views.removeValue(forKey: "taxi")
        store.exploration.tools = []
        store.migrateFerris()
        XCTAssertTrue(store.ferris.musicSolved)
        XCTAssertFalse(store.ferris.posted)
        XCTAssertEqual(store.collected, [.letter])
        store.memories.opened.insert("ferris")
        store.migrateFerris()
        XCTAssertEqual(store.collected, [.letter, .ferris])
        XCTAssertTrue(store.ferris.posted)
    }
}
