import ArgumentParser
import Foundation
import MemwatchCore

struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "list saved snapshots"
    )

    func run() async throws {
        let store = SnapshotStore()
        let listings = try store.list()
        if listings.isEmpty { return }

        let tagWidth = max(3, listings.map { $0.tag.count }.max() ?? 0)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        for listing in listings {
            let tagPart = listing.tag.padded(toRight: tagWidth)
            let timePart = formatter.string(from: listing.timestamp)
            print("\(tagPart)  \(timePart)")
        }
    }
}
