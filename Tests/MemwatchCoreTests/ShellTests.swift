import XCTest
@testable import MemwatchCore

final class ShellTests: XCTestCase {

    // Verifies the shell timeout actually fires when a long-running command
    // doesn't return — this regressed silently before because the parent
    // wasn't closing pipe FDs after SIGTERM, so readToEnd() never unblocked
    // even though the child was killed.
    func testTimeoutFiresOnLongRunningCommand() async throws {
        let started = Date()
        do {
            _ = try await Shell.run("/bin/sleep", ["30"], timeout: 2)
            XCTFail("expected shellTimeout error; got success")
        } catch let error as MemwatchError {
            switch error {
            case .shellTimeout(let cmd, let seconds):
                XCTAssertTrue(cmd.contains("/bin/sleep"))
                XCTAssertEqual(seconds, 2)
                let elapsed = Date().timeIntervalSince(started)
                // Should fire within ~6s (2s timeout + up to 2s SIGTERM grace + some slack)
                XCTAssertLessThan(elapsed, 6.0, "timeout took too long to fire: \(elapsed)s")
            default:
                XCTFail("expected .shellTimeout, got \(error)")
            }
        }
    }

    func testFastCommandReturnsBeforeTimeout() async throws {
        let result = try await Shell.run("/bin/echo", ["hello"], timeout: 5)
        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.stdout.trimmingCharacters(in: .whitespacesAndNewlines), "hello")
    }
}
