import XCTest
@testable import MemwatchCore

final class DiffTests: XCTestCase {

    private func entry(_ name: String, _ count: Int, _ bytes: Int) -> HeapClassEntry {
        HeapClassEntry(className: name, instanceCount: count, totalBytes: bytes)
    }

    func testEmptyInputsProduceEmptyDiff() {
        XCTAssertEqual(HeapDiff.compute(before: [], after: []), [])
    }

    func testNewClassInAfterShowsAsPositiveDelta() {
        let after = [entry("SCNNode", 247, 198400)]
        let deltas = HeapDiff.compute(before: [], after: after)
        XCTAssertEqual(deltas, [
            ClassDelta(className: "SCNNode", countDelta: 247, bytesDelta: 198400)
        ])
    }

    func testRemovedClassShowsAsNegativeDelta() {
        let before = [entry("SCNNode", 247, 198400)]
        let deltas = HeapDiff.compute(before: before, after: [])
        XCTAssertEqual(deltas, [
            ClassDelta(className: "SCNNode", countDelta: -247, bytesDelta: -198400)
        ])
    }

    func testUnchangedClassesAreOmitted() {
        let before = [entry("CFString", 482, 983040)]
        let after = [entry("CFString", 482, 983040)]
        XCTAssertEqual(HeapDiff.compute(before: before, after: after), [])
    }

    func testDeltasAreSortedByAbsBytesDescending() {
        let before = [
            entry("Small", 1, 100),
            entry("Big", 10, 50000),
            entry("Medium", 5, 1000)
        ]
        let after = [
            entry("Small", 2, 200),
            entry("Big", 20, 100000),
            entry("Medium", 10, 2000)
        ]
        let deltas = HeapDiff.compute(before: before, after: after)
        XCTAssertEqual(deltas.map(\.className), ["Big", "Medium", "Small"])
    }

    func testCanonicalLeakScenarioMatchesSpec() {
        // before — menu state
        let before = [
            entry("CFString", 482, 983040),
            entry("UIView", 100, 6400)
        ]
        // after — back at menu after navigating into a level. 12 ghosts, 247 nodes etc. residue.
        let after = [
            entry("CFString", 482, 983040),
            entry("UIView", 103, 6592),
            entry("SCNNode", 247, 202752),     // ~198 KB
            entry("GhostController", 12, 126976), // ~124 KB
            entry("SCNGeometry", 18, 91136),   // ~89 KB
            entry("UIImage", 3, 12288),        // ~12 KB
            entry("NSConcreteMutableData", 2, 8192) // 8 KB
        ]
        let deltas = HeapDiff.compute(before: before, after: after)
        let topClasses = deltas.prefix(5).map(\.className)
        XCTAssertEqual(topClasses, ["SCNNode", "GhostController", "SCNGeometry", "UIImage", "NSConcreteMutableData"])
    }

    func testFormatterProducesAlignedTableNoColor() {
        let deltas = [
            ClassDelta(className: "SCNNode", countDelta: 247, bytesDelta: 202752),
            ClassDelta(className: "GhostController", countDelta: 12, bytesDelta: 126976)
        ]
        let table = DiffFormatter.format(deltas, colorize: false)
        let lines = table.components(separatedBy: "\n")

        XCTAssertEqual(lines.count, 6) // header, rule, 2 rows, rule, total
        XCTAssertTrue(lines[0].hasPrefix("ClassName"), "header line: \(lines[0])")
        XCTAssertTrue(lines[2].contains("SCNNode"))
        XCTAssertTrue(lines[2].contains("+247"))
        XCTAssertTrue(lines[2].contains("+198 KB"))
        // Last line is total row: 202752 + 126976 = 329728 bytes = 322 KB.
        XCTAssertTrue(lines.last!.contains("+322 KB"), "total line: \(lines.last!)")
    }

    func testFormatterAppliesAnsiWhenRequested() {
        let deltas = [ClassDelta(className: "SCNNode", countDelta: 247, bytesDelta: 198400)]
        let colored = DiffFormatter.format(deltas, colorize: true)
        XCTAssertTrue(colored.contains("\u{001B}[31m"), "expected red ANSI sequence")
        XCTAssertTrue(colored.contains("\u{001B}[0m"), "expected reset ANSI sequence")
    }

    func testFormatterTruncatesLongClassNames() {
        let longName = "Swift.ReferenceWritableKeyPath<DesignLibrary.GlassMaterialProvider.Pocket.Storage, Int>"
        let deltas = [ClassDelta(className: longName, countDelta: 1, bytesDelta: 96)]
        let table = DiffFormatter.format(deltas, colorize: false, maxClassNameWidth: 50)
        // The row should contain a truncated version ending in `…`, and not the full long name.
        XCTAssertTrue(table.contains("…"))
        XCTAssertFalse(table.contains("Pocket.Storage, Int>"))
    }

    func testTruncateHelper() {
        XCTAssertEqual(DiffFormatter.truncate("short", to: 50), "short")
        XCTAssertEqual(DiffFormatter.truncate(String(repeating: "x", count: 60), to: 10), "xxxxxxxxx…")
        // Edge: maxChars < 2 leaves the name unchanged.
        XCTAssertEqual(DiffFormatter.truncate("abc", to: 1), "abc")
    }

    func testBytesFormatter() {
        XCTAssertEqual(BytesFormatter.format(0), "0 B")
        XCTAssertEqual(BytesFormatter.format(512), "512 B")
        XCTAssertEqual(BytesFormatter.format(1024), "1 KB")
        XCTAssertEqual(BytesFormatter.format(198400, signed: true), "+194 KB")
        XCTAssertEqual(BytesFormatter.format(-198400, signed: true), "-194 KB")
        XCTAssertEqual(BytesFormatter.format(5 * 1024 * 1024), "5.0 MB")
    }
}
