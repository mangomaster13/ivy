import XCTest
@testable import Ivy

final class EggOrderTests: XCTestCase {
    func testBarOrderMatchesProduct() {
        XCTAssertEqual(
            EggId.allCases.map(\.rawValue),
            [
                "letter", "vuori", "plane", "keycard", "city", "rose", "gelato",
                "noodle", "perfume", "cinema", "dictionary", "ferris", "taxi"
            ]
        )
    }

    func testRetiredEggsAreGone() {
        XCTAssertNil(EggId(rawValue: "ivy"))
        XCTAssertNil(EggId(rawValue: "sep29"))
        XCTAssertNil(EggId(rawValue: "suitcase"))
        XCTAssertNil(EggId(rawValue: "pillow"))
    }

    @MainActor
    func testLegacySunsetKeepsOwnershipAndView() throws {
        let decoder = JSONDecoder()
        XCTAssertEqual(try decoder.decode(EggId.self, from: Data("\"sunset\"".utf8)), .dictionary)
        XCTAssertEqual(try decoder.decode(Room.self, from: Data("\"sunset\"".utf8)), .dictionary)
        let store = StoreHarness.make()
        store.exploration.views["sunset"] = 0
        store.exploration.sanitize()
        store.memories.opened.insert("sunset")
        store.collected.insert(.cinema)
        store.migrateMemories()
        XCTAssertTrue(store.collected.isSuperset(of: [.cinema, .dictionary]))
        XCTAssertTrue(store.memories.opened.contains("dictionary"))
        XCTAssertFalse(store.memories.opened.contains("sunset"))
        XCTAssertEqual(store.exploration.views["dictionary"], 0)
        XCTAssertNil(store.exploration.views["sunset"])
        XCTAssertEqual(String(decoding: try JSONEncoder().encode(EggId.dictionary), as: UTF8.self), "\"dictionary\"")
    }

    @MainActor
    func testDictionaryRequiresSelectedPenAndPreservesActualDraft() throws {
        let store = StoreHarness.make()
        store.room = .dictionary
        store.openMemory(.dictionary)
        let point = DictionaryInkPoint(x: 0.2, y: 0.3)
        store.addDictionaryPoint(point, startingStroke: true)
        XCTAssertTrue(store.dictionary.strokes.isEmpty)
        store.backFromMemory()
        store.takeDictionaryPen()
        XCTAssertTrue(store.exploration.tools.contains(.fountainPen))
        XCTAssertNil(store.selectedTool)
        store.openMemory(.dictionary)
        store.addDictionaryPoint(point, startingStroke: true)
        XCTAssertTrue(store.dictionary.strokes.isEmpty)
        store.chooseTool(.fountainPen)
        store.addDictionaryPoint(point, startingStroke: true)
        store.addDictionaryPoint(DictionaryInkPoint(x: 0.8, y: 0.3), startingStroke: false)
        let saved = try JSONEncoder().encode(store.memories)
        let restored = try JSONDecoder().decode(MemoryProgress.self, from: saved)
        XCTAssertEqual(restored.dictionary?.strokes, [[point, DictionaryInkPoint(x: 0.8, y: 0.3)]])
        store.memories.sunsetFrame = 0.65
        store.solveLater(.dictionary)
        store.collectPhysical(.dictionary)
        XCTAssertFalse(store.collected.contains(.dictionary), "Old framing must not solve the new word")
        store.undoDictionaryStroke()
        XCTAssertTrue(store.dictionary.strokes.isEmpty)
        let damaged = try JSONDecoder().decode(DictionaryProgress.self, from: Data("{\"strokes\":\"bad\",\"solved\":true}".utf8))
        XCTAssertTrue(damaged.solved)
        XCTAssertTrue(damaged.strokes.isEmpty)
    }

    func testOldPerfumeNamesDecodeIntoCurrentIds() throws {
        let decoder = JSONDecoder()
        XCTAssertEqual(try decoder.decode(EggId.self, from: Data("\"supermarket\"".utf8)), .perfume)
        XCTAssertEqual(try decoder.decode(Room.self, from: Data("\"supermarket\"".utf8)), .perfume)
        var exploration = ExplorationProgress()
        exploration.views["supermarket"] = 3
        exploration.sanitize()
        XCTAssertEqual(exploration.views["perfume"], 3)
        XCTAssertNil(exploration.views["supermarket"])
    }
}
