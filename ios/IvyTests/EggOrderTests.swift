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
