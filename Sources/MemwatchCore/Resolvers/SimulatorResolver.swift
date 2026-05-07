import Foundation

public enum SimulatorResolver {
    private struct DevicesEnvelope: Decodable {
        let devices: [String: [Device]]
    }

    private struct Device: Decodable {
        let udid: String
        let state: String
    }

    public static func bootedUDID() async throws -> String {
        let result = try await Shell.run("/usr/bin/xcrun", ["simctl", "list", "devices", "booted", "-j"])
        guard result.exitCode == 0 else {
            throw MemwatchError.simctlFailed(result.stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        guard let data = result.stdout.data(using: .utf8) else {
            throw MemwatchError.simctlFailed("non-UTF-8 output")
        }
        let envelope: DevicesEnvelope
        do {
            envelope = try JSONDecoder().decode(DevicesEnvelope.self, from: data)
        } catch {
            throw MemwatchError.simctlFailed("could not parse simctl JSON: \(error.localizedDescription)")
        }
        let booted = envelope.devices.values.flatMap { $0 }.filter { $0.state == "Booted" }
        guard let first = booted.first else {
            throw MemwatchError.noBootedSimulator
        }
        return first.udid
    }
}
