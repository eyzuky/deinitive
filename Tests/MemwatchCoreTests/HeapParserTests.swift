import XCTest
@testable import MemwatchCore

final class HeapParserTests: XCTestCase {

    private func loadFixture(_ name: String) throws -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: "txt", subdirectory: "Fixtures") else {
            XCTFail("fixture \(name) not found in test bundle")
            return ""
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    func testWellFormedFixtureParsesAllRows() throws {
        let raw = try loadFixture("heap-sample")
        let entries = HeapParser.parse(raw)

        XCTAssertEqual(entries.count, 9)

        let cfString = entries.first { $0.className == "CFString" }
        XCTAssertEqual(cfString?.instanceCount, 482)
        XCTAssertEqual(cfString?.totalBytes, 983040)

        let scnNode = entries.first { $0.className == "SCNNode" }
        XCTAssertEqual(scnNode?.instanceCount, 247)
        XCTAssertEqual(scnNode?.totalBytes, 198400)

        let ghost = entries.first { $0.className == "GhostController" }
        XCTAssertEqual(ghost?.instanceCount, 12)
        XCTAssertEqual(ghost?.totalBytes, 124928)
    }

    func testMalformedRowsAreSkippedSilently() throws {
        let raw = try loadFixture("heap-malformed")
        let entries = HeapParser.parse(raw)

        // Three valid rows: CFString, SCNNode, GhostController.
        // Skipped: "not a valid row at all", "abc 198400 …", and the blank line.
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries.map(\.className).sorted(), ["CFString", "GhostController", "SCNNode"])
    }

    func testEmptyInputReturnsEmptyArray() throws {
        let raw = try loadFixture("heap-empty")
        XCTAssertEqual(HeapParser.parse(raw), [])
    }

    func testInputWithoutHeaderReturnsEmptyArray() {
        let raw = """
        Some preamble text here
        Even more preamble
            12 4096 64 ClassThatLooksValid
        but no header is present
        """
        XCTAssertEqual(HeapParser.parse(raw), [])
    }

    func testCommaSeparatedBytesAreAccepted() {
        let raw = """
               COUNT     BYTES   AVG  CLASS_NAME
               =====     =====   ===  ==========
                 482   983,040  2.0K  CFString
                  18    89,344  4.9K  SCNGeometry
        """
        let entries = HeapParser.parse(raw)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].totalBytes, 983040)
        XCTAssertEqual(entries[1].totalBytes, 89344)
    }
}
