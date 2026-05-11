import Foundation

public struct Snapshot: Codable, Equatable, Sendable {
    public let tag: String
    public let timestamp: Date
    public let bundleID: String
    public let pid: Int32
    public let heap: [HeapClassEntry]
    public let leaksRaw: String?

    public init(
        tag: String,
        timestamp: Date,
        bundleID: String,
        pid: Int32,
        heap: [HeapClassEntry],
        leaksRaw: String? = nil
    ) {
        self.tag = tag
        self.timestamp = timestamp
        self.bundleID = bundleID
        self.pid = pid
        self.heap = heap
        self.leaksRaw = leaksRaw
    }

    public var totalBytes: Int {
        heap.reduce(0) { $0 + $1.totalBytes }
    }
}
