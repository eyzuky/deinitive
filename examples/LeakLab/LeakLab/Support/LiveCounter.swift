import Foundation

final class LiveCounter: @unchecked Sendable {
    static let shared = LiveCounter()

    private let lock = NSLock()
    private var counts: [String: Int] = [:]

    private init() {}

    func increment(_ name: String) {
        lock.lock(); defer { lock.unlock() }
        counts[name, default: 0] += 1
    }

    func decrement(_ name: String) {
        lock.lock(); defer { lock.unlock() }
        counts[name, default: 0] -= 1
    }

    func count(_ name: String) -> Int {
        lock.lock(); defer { lock.unlock() }
        return counts[name, default: 0]
    }
}
