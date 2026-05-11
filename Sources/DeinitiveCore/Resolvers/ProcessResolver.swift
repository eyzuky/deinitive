import Foundation

public enum ProcessResolver {
    public static func findPID(bundleID: String, simulatorUDID: String) async throws -> pid_t {
        try await validateBundleInstalled(bundleID: bundleID, simulatorUDID: simulatorUDID)
        let appPath = try await appBundlePath(bundleID: bundleID, simulatorUDID: simulatorUDID)
        let executablePath = try executableURL(forAppBundleAt: appPath).path

        // pgrep -f matches against the full command line; the simulator launches the app with
        // its full executable path, so this disambiguates between two apps with the same binary name.
        let result = try await Shell.run("/usr/bin/pgrep", ["-f", executablePath])
        guard result.exitCode == 0 else {
            throw DeinitiveError.appNotRunning(bundleID: bundleID, udid: simulatorUDID)
        }
        let pids = result.stdout
            .split(whereSeparator: { $0.isNewline })
            .compactMap { pid_t($0.trimmingCharacters(in: .whitespaces)) }
        guard let pid = pids.first else {
            throw DeinitiveError.appNotRunning(bundleID: bundleID, udid: simulatorUDID)
        }
        return pid
    }

    private static func validateBundleInstalled(bundleID: String, simulatorUDID: String) async throws {
        let result = try await Shell.run("/usr/bin/xcrun", ["simctl", "listapps", simulatorUDID])
        guard result.exitCode == 0 else {
            throw DeinitiveError.simctlFailed(result.stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        if !result.stdout.contains("\"\(bundleID)\"") {
            throw DeinitiveError.bundleNotInstalled(bundleID: bundleID, udid: simulatorUDID)
        }
    }

    private static func appBundlePath(bundleID: String, simulatorUDID: String) async throws -> URL {
        let result = try await Shell.run(
            "/usr/bin/xcrun",
            ["simctl", "get_app_container", simulatorUDID, bundleID, "app"]
        )
        guard result.exitCode == 0 else {
            throw DeinitiveError.bundleNotInstalled(bundleID: bundleID, udid: simulatorUDID)
        }
        let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(fileURLWithPath: path)
    }

    // Reads CFBundleExecutable from the .app's Info.plist and returns the absolute path of the binary.
    private static func executableURL(forAppBundleAt appURL: URL) throws -> URL {
        let infoPlistURL = appURL.appendingPathComponent("Info.plist")
        guard let data = try? Data(contentsOf: infoPlistURL) else {
            throw DeinitiveError.parseFailed("could not read Info.plist at \(infoPlistURL.path)")
        }
        guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let executable = plist["CFBundleExecutable"] as? String else {
            throw DeinitiveError.parseFailed("CFBundleExecutable missing from Info.plist at \(infoPlistURL.path)")
        }
        return appURL.appendingPathComponent(executable)
    }
}
