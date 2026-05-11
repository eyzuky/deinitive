import Foundation

public enum HeapTool {
    public static func capture(pid: pid_t) async throws -> [HeapClassEntry] {
        let result = try await Shell.run("/usr/bin/heap", ["\(pid)"])
        guard result.exitCode == 0 else {
            throw DeinitiveError.heapFailed(result.stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return HeapParser.parse(result.stdout)
    }
}

public enum LeaksTool {
    public static func capture(pid: pid_t) async throws -> String {
        let result = try await Shell.run("/usr/bin/leaks", ["\(pid)"])
        // leaks returns nonzero exit code when leaks ARE found; that's not an error for us.
        // It only fails (no output) when it can't attach.
        if result.exitCode != 0 && result.stdout.isEmpty {
            throw DeinitiveError.leaksFailed(result.stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return result.stdout
    }
}
