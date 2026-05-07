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
    // Default timeout. heap on a busy app can take 10–30s; longer than this is almost
    // certainly a hang (heap occasionally gets stuck on task_for_pid attach). The timeout
    // SIGTERMs the child, then SIGKILLs after 5s if it's still alive.
    public static let defaultTimeoutSeconds: TimeInterval = 60

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
        let timeoutTask = Task { [process] in
            try? await Task.sleep(for: .seconds(timeout))
            if Task.isCancelled { return }
            guard process.isRunning else { return }
            didTimeOut.set()
            process.terminate()  // SIGTERM
            try? await Task.sleep(for: .seconds(5))
            if process.isRunning {
                #if canImport(Darwin)
                kill(process.processIdentifier, SIGKILL)
                #endif
            }
        }

        async let stdoutData = readAll(outPipe.fileHandleForReading)
        async let stderrData = readAll(errPipe.fileHandleForReading)
        let (out, err) = await (stdoutData, stderrData)
        process.waitUntilExit()
        timeoutTask.cancel()

        if didTimeOut.value {
            let cmd = ([executable] + arguments).joined(separator: " ")
            throw MemwatchError.shellTimeout(command: cmd, seconds: timeout)
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
