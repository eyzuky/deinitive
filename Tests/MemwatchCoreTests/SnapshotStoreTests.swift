import XCTest
@testable import MemwatchCore

final class SnapshotStoreTests: XCTestCase {

    private var tempDirectory: URL!

    override func setUpWithError() throws {
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("memwatch-tests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDirectory)
    }

    private func makeStore() -> SnapshotStore {
        SnapshotStore(directory: tempDirectory)
    }

    private func makeSnapshot(tag: String, classes: [(String, Int, Int)] = []) -> Snapshot {
        Snapshot(
            tag: tag,
            timestamp: Date(),
            bundleID: "com.example.app",
            pid: 49281,
            heap: classes.map { HeapClassEntry(className: $0.0, instanceCount: $0.1, totalBytes: $0.2) }
        )
    }

    func testSaveAndLoadRoundTrip() throws {
        let store = makeStore()
        let snap = makeSnapshot(tag: "menu", classes: [("CFString", 482, 983040), ("SCNNode", 247, 198400)])
        try store.save(snap)

        let loaded = try store.load(tag: "menu")
        XCTAssertEqual(loaded.tag, "menu")
        XCTAssertEqual(loaded.bundleID, "com.example.app")
        XCTAssertEqual(loaded.heap.count, 2)
        XCTAssertEqual(loaded.heap.first { $0.className == "CFString" }?.instanceCount, 482)
    }

    func testLoadMissingTagThrowsSnapshotNotFound() {
        let store = makeStore()
        XCTAssertThrowsError(try store.load(tag: "does-not-exist")) { error in
            guard let mw = error as? MemwatchError else {
                XCTFail("expected MemwatchError, got \(error)")
                return
            }
            switch mw {
            case .snapshotNotFound(let tag):
                XCTAssertEqual(tag, "does-not-exist")
            default:
                XCTFail("expected .snapshotNotFound, got \(mw)")
            }
        }
    }

    func testListReturnsSnapshotsSortedNewestFirst() throws {
        let store = makeStore()
        let now = Date()
        let older = Snapshot(
            tag: "menu",
            timestamp: now.addingTimeInterval(-60),
            bundleID: "com.example.app",
            pid: 1,
            heap: []
        )
        let newer = Snapshot(
            tag: "level1",
            timestamp: now,
            bundleID: "com.example.app",
            pid: 1,
            heap: []
        )
        try store.save(older)
        try store.save(newer)

        let listings = try store.list()
        XCTAssertEqual(listings.map(\.tag), ["level1", "menu"])
    }

    func testListOnEmptyDirectoryReturnsEmpty() throws {
        let store = makeStore()
        XCTAssertEqual(try store.list(), [])
    }

    func testClearRemovesEverything() throws {
        let store = makeStore()
        try store.save(makeSnapshot(tag: "a"))
        try store.save(makeSnapshot(tag: "b"))
        XCTAssertEqual(store.count(), 2)
        try store.clear()
        XCTAssertEqual(store.count(), 0)
    }

    func testClearOnEmptyStoreIsNoOp() throws {
        let store = makeStore()
        XCTAssertNoThrow(try store.clear())
    }

    func testListSkipsCorruptedJSONFiles() throws {
        let store = makeStore()
        try store.save(makeSnapshot(tag: "good"))
        // Plant a corrupt file in the store directory.
        let badURL = store.fileURL(forTag: "bad")
        try "{ this is not json }".data(using: .utf8)!.write(to: badURL)

        let listings = try store.list()
        XCTAssertEqual(listings.map(\.tag), ["good"])
    }
}
