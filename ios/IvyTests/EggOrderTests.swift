import XCTest
@testable import Ivy

final class EggOrderTests: XCTestCase {
    func testBarOrderMatchesProduct() {
        XCTAssertEqual(
            EggId.allCases.map(\.rawValue),
            [
                "letter", "vuori", "plane", "keycard", "city", "rose", "gelato",
                "noodle", "perfume", "cinema", "sunset", "ferris", "taxi"
            ]
        )
    }

    func testRetiredEggsAreGone() {
        XCTAssertNil(EggId(rawValue: "ivy"))
        XCTAssertNil(EggId(rawValue: "sep29"))
        XCTAssertNil(EggId(rawValue: "suitcase"))
        XCTAssertNil(EggId(rawValue: "pillow"))
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
