import Foundation

// High-level operations that orchestrate resolvers + tools + parsers + storage.
// Both the CLI subcommands and the MCP tools call into these. The optional
// `progress` callback fires before each phase so callers can surface what's
// happening — useful when heap takes 10–30 seconds on a busy app.

public typealias ProgressHandler = @Sendable (String) -> Void

public enum SnapshotOperation {
    public static func run(
        tag: String,
        bundleID: String,
        simulatorUDID: String?,
        store: SnapshotStore = SnapshotStore(),
        progress: ProgressHandler = { _ in }
    ) async throws -> Snapshot {
        let udid = try await resolveUDID(simulatorUDID, progress: progress)
        progress("finding pid for \(bundleID) in simulator \(udid)")
        let pid = try await ProcessResolver.findPID(bundleID: bundleID, simulatorUDID: udid)
        progress("running heap on pid \(pid)")
        let heap = try await HeapTool.capture(pid: pid)
        progress("saving snapshot '\(tag)'")
        let snapshot = Snapshot(
            tag: tag,
            timestamp: Date(),
            bundleID: bundleID,
            pid: pid,
            heap: heap,
            leaksRaw: nil
        )
        try store.save(snapshot)
        return snapshot
    }
}

public enum CurrentOperation {
    public static func run(
        bundleID: String,
        simulatorUDID: String?,
        progress: ProgressHandler = { _ in }
    ) async throws -> [HeapClassEntry] {
        let udid = try await resolveUDID(simulatorUDID, progress: progress)
        progress("finding pid for \(bundleID) in simulator \(udid)")
        let pid = try await ProcessResolver.findPID(bundleID: bundleID, simulatorUDID: udid)
        progress("running heap on pid \(pid)")
        return try await HeapTool.capture(pid: pid)
    }
}

public enum LeaksOperation {
    public static func run(
        bundleID: String,
        simulatorUDID: String?,
        progress: ProgressHandler = { _ in }
    ) async throws -> String {
        let udid = try await resolveUDID(simulatorUDID, progress: progress)
        progress("finding pid for \(bundleID) in simulator \(udid)")
        let pid = try await ProcessResolver.findPID(bundleID: bundleID, simulatorUDID: udid)
        progress("running leaks on pid \(pid)")
        return try await LeaksTool.capture(pid: pid)
    }
}

private func resolveUDID(_ provided: String?, progress: ProgressHandler) async throws -> String {
    if let provided {
        progress("using simulator \(provided)")
        return provided
    }
    progress("resolving booted simulator")
    return try await SimulatorResolver.bootedUDID()
}
