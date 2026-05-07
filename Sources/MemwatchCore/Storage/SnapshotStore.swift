import Foundation

public final class SnapshotStore {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public convenience init() {
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        self.init(directory: cwd.appendingPathComponent(".memwatch/snapshots", isDirectory: true))
    }

    public func save(_ snapshot: Snapshot) throws {
        try ensureDirectory()
        let url = fileURL(forTag: snapshot.tag)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(snapshot)
            try data.write(to: url, options: [.atomic])
        } catch {
            throw MemwatchError.storageFailed("could not write \(url.path): \(error.localizedDescription)")
        }
    }

    public func load(tag: String) throws -> Snapshot {
        let url = fileURL(forTag: tag)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw MemwatchError.snapshotNotFound(tag: tag)
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Snapshot.self, from: data)
        } catch let error as MemwatchError {
            throw error
        } catch {
            throw MemwatchError.storageFailed("could not read \(url.path): \(error.localizedDescription)")
        }
    }

    public struct Listing: Equatable, Sendable {
        public let tag: String
        public let timestamp: Date
    }

    public func list() throws -> [Listing] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        let entries: [URL]
        do {
            entries = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        } catch {
            throw MemwatchError.storageFailed("could not list \(directory.path): \(error.localizedDescription)")
        }

        let listings: [Listing] = entries.compactMap { url in
            guard url.pathExtension == "json" else { return nil }
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let snapshot = try decoder.decode(Snapshot.self, from: data)
                return Listing(tag: snapshot.tag, timestamp: snapshot.timestamp)
            } catch {
                return nil
            }
        }

        return listings.sorted { $0.timestamp > $1.timestamp }
    }

    public func clear() throws {
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        do {
            try FileManager.default.removeItem(at: directory)
        } catch {
            throw MemwatchError.storageFailed("could not delete \(directory.path): \(error.localizedDescription)")
        }
    }

    public func count() -> Int {
        (try? list().count) ?? 0
    }

    public func fileURL(forTag tag: String) -> URL {
        directory.appendingPathComponent("\(tag).json", isDirectory: false)
    }

    private func ensureDirectory() throws {
        if FileManager.default.fileExists(atPath: directory.path) { return }
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } catch {
            throw MemwatchError.storageFailed("could not create \(directory.path): \(error.localizedDescription)")
        }
    }
}
