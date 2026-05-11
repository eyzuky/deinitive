import Foundation

public struct HeapClassEntry: Codable, Equatable, Sendable {
    public let className: String
    public let instanceCount: Int
    public let totalBytes: Int

    public init(className: String, instanceCount: Int, totalBytes: Int) {
        self.className = className
        self.instanceCount = instanceCount
        self.totalBytes = totalBytes
    }
}
