import ArgumentParser
import Foundation
import DeinitiveCore

#if canImport(Darwin)
import Darwin
#endif

struct Snapshot: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "snapshot",
        abstract: "capture heap state and tag it"
    )

    @Option(name: .shortAndLong, help: "tag to store this snapshot under")
    var tag: String

    @Option(name: .shortAndLong, help: "bundle identifier of the running app")
    var bundle: String

    @Option(name: .shortAndLong, help: "simulator UDID (defaults to booted)")
    var simulator: String?

    func run() async throws {
        setbuf(stdout, nil)

        let started = Date()
        let snapshot = try await withTicker(indent: "") {
            try await SnapshotOperation.run(
                tag: tag,
                bundleID: bundle,
                simulatorUDID: simulator,
                progress: { msg in
                    FileHandle.standardOutput.write(Data("\(msg)\n".utf8))
                }
            )
        }
        let elapsed = Date().timeIntervalSince(started)
        let total = BytesFormatter.format(snapshot.totalBytes)
        print("saved snapshot '\(snapshot.tag)' (pid \(snapshot.pid), \(snapshot.heap.count) classes, \(total) total) in \(formatElapsed(elapsed))")
    }
}
