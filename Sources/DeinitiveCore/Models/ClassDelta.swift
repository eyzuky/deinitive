import Foundation

public struct ClassDelta: Equatable, Sendable {
    public let className: String
    public let countDelta: Int
    public let bytesDelta: Int

    public init(className: String, countDelta: Int, bytesDelta: Int) {
        self.className = className
        self.countDelta = countDelta
        self.bytesDelta = bytesDelta
    }
}
