import Foundation

func formatElapsed(_ seconds: TimeInterval) -> String {
    if seconds < 1 { return String(format: "%.0fms", seconds * 1000) }
    if seconds < 60 { return String(format: "%.1fs", seconds) }
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return "\(mins)m\(secs)s"
}

// Run `work`, printing a heartbeat tick every `interval` so the user knows we
// haven't hung. The tick reports total elapsed seconds since this helper was
// entered; combined with the per-phase progress messages, the user can see
// which phase is the slow one.
func withTicker<T>(
    every interval: Duration = .seconds(5),
    indent: String = "    ",
    _ work: () async throws -> T
) async throws -> T {
    let started = Date()
    let ticker = Task {
        while !Task.isCancelled {
            try? await Task.sleep(for: interval)
            if Task.isCancelled { break }
            let elapsed = Int(Date().timeIntervalSince(started))
            FileHandle.standardOutput.write(Data("\(indent)still running… (\(elapsed)s elapsed)\n".utf8))
        }
    }
    defer { ticker.cancel() }
    return try await work()
}
