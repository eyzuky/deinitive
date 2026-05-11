import ArgumentParser
import Foundation
import DeinitiveCore

struct Clear: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clear",
        abstract: "delete saved snapshots"
    )

    @Flag(name: .shortAndLong, help: "skip confirmation prompt")
    var yes: Bool = false

    func run() async throws {
        let store = SnapshotStore()
        let count = store.count()
        if count == 0 {
            print("no snapshots to clear")
            return
        }

        if !yes {
            print("delete \(store.directory.path) (\(count) snapshot\(count == 1 ? "" : "s"))? [y/N] ", terminator: "")
            FileHandle.standardOutput.synchronizeFile()
            let response = readLine() ?? ""
            let normalized = response.trimmingCharacters(in: .whitespaces).lowercased()
            guard normalized == "y" || normalized == "yes" else {
                print("aborted")
                return
            }
        }

        try store.clear()
        print("cleared \(count) snapshot\(count == 1 ? "" : "s")")
    }
}
