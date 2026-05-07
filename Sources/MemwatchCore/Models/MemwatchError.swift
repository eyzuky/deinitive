import Foundation

public enum MemwatchError: LocalizedError {
    case noBootedSimulator
    case bundleNotInstalled(bundleID: String, udid: String)
    case appNotRunning(bundleID: String, udid: String)
    case simctlFailed(String)
    case heapFailed(String)
    case leaksFailed(String)
    case snapshotNotFound(tag: String)
    case snapshotAlreadyExists(tag: String)
    case storageFailed(String)
    case parseFailed(String)
    case shellTimeout(command: String, seconds: TimeInterval)

    public var errorDescription: String? {
        switch self {
        case .noBootedSimulator:
            return "No booted simulator. Run: xcrun simctl boot <udid>"
        case .bundleNotInstalled(let bundle, let udid):
            return "App \(bundle) is not installed in simulator \(udid). Install it from Xcode first."
        case .appNotRunning(let bundle, let udid):
            return "App \(bundle) not running in simulator \(udid). Launch it first."
        case .simctlFailed(let msg):
            return "simctl failed: \(msg). Check that Xcode Command Line Tools are installed: xcode-select --install"
        case .heapFailed(let msg):
            return "heap failed: \(msg). Confirm the app is running and Xcode Command Line Tools are installed."
        case .leaksFailed(let msg):
            return "leaks failed: \(msg). Confirm the app is running and Xcode Command Line Tools are installed."
        case .snapshotNotFound(let tag):
            return "No snapshot with tag '\(tag)'. Run: memwatch list"
        case .snapshotAlreadyExists(let tag):
            return "Snapshot '\(tag)' already exists. Use a new tag or run: memwatch clear"
        case .storageFailed(let msg):
            return "Storage error: \(msg)"
        case .parseFailed(let msg):
            return "Parse error: \(msg)"
        case .shellTimeout(let cmd, let seconds):
            return "Command timed out after \(Int(seconds))s: \(cmd). heap occasionally gets stuck attaching to a busy process. Try `\(cmd)` manually to see if it's responsive; if not, force-quit the simulator app and re-run."
        }
    }
}
