import Foundation

#if canImport(Darwin)
import Darwin
#endif

public struct ShellResult: Sendable {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int32

    public init(stdout: String, stderr: String, exitCode: Int32) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
    }
}

public enum Shell {
    // Default timeout. heap can take 10–30s on a busy app; simctl/pgrep should be
    // sub-second. 45s gives slow-but-legit operations room while still failing fast
    // when something genuinely wedged (e.g., CoreSimulatorService daemon stuck).
    public static let defaultTimeoutSeconds: TimeInterval = 45

    public static func run(
        _ executable: String,
        _ arguments: [String] = [],
        timeout: TimeInterval = defaultTimeoutSeconds
    ) async throws -> ShellResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()

        let didTimeOut = TimeoutFlag()
        // Detached so it runs on its own background thread regardless of the
        // cooperative-pool state (the parent task suspends on the pipe-drain await).
        let timeoutTask = Task.detached { [process, outPipe, errPipe] in
            try? await Task.sleep(for: .seconds(timeout))
            if Task.isCancelled { return }
            guard process.isRunning else { return }

            didTimeOut.set()
            let pid = process.processIdentifier
            FileHandle.standardError.write(Data(
                "deinitive: shell timeout after \(Int(timeout))s on \(executable) (pid \(pid)) — killing\n".utf8
            ))

            // SIGTERM first.
            process.terminate()
            try? await Task.sleep(for: .seconds(2))

            // SIGKILL if still alive.
            if process.isRunning {
                #if canImport(Darwin)
                kill(pid, SIGKILL)
                #endif
            }

            // CRITICAL: even after the immediate child dies, grandchildren that
            // inherited the pipe write FDs (e.g., xcrun → simctl → CoreSimulatorService
            // chatter) keep the pipes open, so readToEnd() never sees EOF. Close the
            // read ends from our side to force the reader tasks to unblock.
            try? outPipe.fileHandleForReading.close()
            try? errPipe.fileHandleForReading.close()
        }

        async let stdoutData = readAll(outPipe.fileHandleForReading)
        async let stderrData = readAll(errPipe.fileHandleForReading)
        let (out, err) = await (stdoutData, stderrData)
        process.waitUntilExit()
        timeoutTask.cancel()

        if didTimeOut.value {
            let cmd = ([executable] + arguments).joined(separator: " ")
            throw DeinitiveError.shellTimeout(command: cmd, seconds: timeout)
        }

        return ShellResult(
            stdout: String(data: out, encoding: .utf8) ?? "",
            stderr: String(data: err, encoding: .utf8) ?? "",
            exitCode: process.terminationStatus
        )
    }

    private static func readAll(_ handle: FileHandle) async -> Data {
        await Task.detached(priority: .utility) {
            (try? handle.readToEnd()) ?? Data()
        }.value
    }
}

private final class TimeoutFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = false
    var value: Bool { lock.lock(); defer { lock.unlock() }; return _value }
    func set() { lock.lock(); _value = true; lock.unlock() }
}
