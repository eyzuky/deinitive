import Foundation
import MemwatchCore

struct ToolDefinition {
    let name: String
    let description: String
    let inputSchema: [String: Any]
}

enum ToolRegistry {
    static let definitions: [ToolDefinition] = [
        ToolDefinition(
            name: "memwatch_snapshot",
            description: "Capture the iOS simulator app's heap and persist it under a tag. Pair with memwatch_diff to find round-trip leaks.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "tag": ["type": "string", "description": "Name to store this snapshot under."] as [String: Any],
                    "bundle": ["type": "string", "description": "Bundle identifier of the running simulator app. Defaults to the value passed to `memwatch mcp --bundle`."] as [String: Any]
                ] as [String: Any],
                "required": ["tag"]
            ]
        ),
        ToolDefinition(
            name: "memwatch_diff",
            description: "Compute the per-class delta between two saved snapshots. Positive deltas after a navigation round-trip are leak suspects. Framework warmup classes (Auto Layout solver, glyph caches, runtime metadata, etc.) are filtered out by default; pass all=true to see everything.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "before": ["type": "string", "description": "Earlier snapshot tag."] as [String: Any],
                    "after": ["type": "string", "description": "Later snapshot tag."] as [String: Any],
                    "all": ["type": "boolean", "description": "If true, include framework warmup classes that are otherwise filtered. Defaults to false."] as [String: Any]
                ] as [String: Any],
                "required": ["before", "after"]
            ]
        ),
        ToolDefinition(
            name: "memwatch_current",
            description: "Capture the current heap and return the top-20 allocators without persisting. Useful for one-off spot checks. Framework warmup classes are filtered by default; pass all=true to see everything.",
            inputSchema: [
                "type": "object",
                "properties": [
                    "bundle": ["type": "string", "description": "Bundle identifier. Defaults to the value passed to `memwatch mcp --bundle`."] as [String: Any],
                    "all": ["type": "boolean", "description": "If true, include framework warmup classes that are otherwise filtered. Defaults to false."] as [String: Any]
                ] as [String: Any]
            ]
        ),
        ToolDefinition(
            name: "memwatch_leaks",
            description: "Run Apple's `leaks` tool against the running simulator app and return its raw output. Reports definitively-orphaned allocations (a strict subset of memwatch_diff's signal).",
            inputSchema: [
                "type": "object",
                "properties": [
                    "bundle": ["type": "string", "description": "Bundle identifier. Defaults to the value passed to `memwatch mcp --bundle`."] as [String: Any]
                ] as [String: Any]
            ]
        )
    ]

    static func toolListPayload() -> [[String: Any]] {
        definitions.map { def in
            [
                "name": def.name,
                "description": def.description,
                "inputSchema": def.inputSchema
            ]
        }
    }
}

struct ToolContext {
    let defaultBundle: String?
    let defaultSimulator: String?
}

enum ToolDispatcher {
    static func call(name: String, arguments: [String: Any], context: ToolContext) async -> [String: Any] {
        do {
            switch name {
            case "memwatch_snapshot":
                return try await callSnapshot(arguments, context: context)
            case "memwatch_diff":
                return try await callDiff(arguments)
            case "memwatch_current":
                return try await callCurrent(arguments, context: context)
            case "memwatch_leaks":
                return try await callLeaks(arguments, context: context)
            default:
                return toolError("unknown tool: \(name)")
            }
        } catch let error as MemwatchError {
            return toolError(error.errorDescription ?? "\(error)")
        } catch {
            return toolError(error.localizedDescription)
        }
    }

    private static func callSnapshot(_ args: [String: Any], context: ToolContext) async throws -> [String: Any] {
        guard let tag = args["tag"] as? String else {
            return toolError("missing 'tag' argument")
        }
        guard let bundle = (args["bundle"] as? String) ?? context.defaultBundle else {
            return toolError("missing 'bundle' argument and no default bundle was set on `memwatch mcp --bundle`")
        }
        let snapshot = try await SnapshotOperation.run(
            tag: tag,
            bundleID: bundle,
            simulatorUDID: context.defaultSimulator
        )
        let total = BytesFormatter.format(snapshot.totalBytes)
        return toolText(
            "saved snapshot '\(snapshot.tag)' (pid \(snapshot.pid), \(snapshot.heap.count) classes, \(total) total)"
        )
    }

    private static func callDiff(_ args: [String: Any]) async throws -> [String: Any] {
        guard let before = args["before"] as? String else {
            return toolError("missing 'before' argument")
        }
        guard let after = args["after"] as? String else {
            return toolError("missing 'after' argument")
        }
        let showAll = (args["all"] as? Bool) ?? false
        let store = SnapshotStore()
        let beforeSnap = try store.load(tag: before)
        let afterSnap = try store.load(tag: after)
        let computed = HeapDiff.compute(before: beforeSnap.heap, after: afterSnap.heap)

        let deltas: [ClassDelta]
        let hidden: Int
        if showAll {
            deltas = computed
            hidden = 0
        } else {
            let result = NoiseFilter.defaultFramework.apply(to: computed)
            deltas = result.kept
            hidden = result.droppedCount
        }

        if deltas.isEmpty {
            if hidden > 0 {
                return toolText("no differences after filtering (\(hidden) framework class\(hidden == 1 ? "" : "es") hidden — pass all=true to show)")
            }
            return toolText("no differences between '\(before)' and '\(after)'")
        }

        var output = DiffFormatter.format(deltas, colorize: false)
        if hidden > 0 {
            output += "\n\n(\(hidden) framework class\(hidden == 1 ? "" : "es") hidden — pass all=true to show)"
        }
        return toolText(output)
    }

    private static func callCurrent(_ args: [String: Any], context: ToolContext) async throws -> [String: Any] {
        guard let bundle = (args["bundle"] as? String) ?? context.defaultBundle else {
            return toolError("missing 'bundle' argument and no default bundle was set on `memwatch mcp --bundle`")
        }
        let showAll = (args["all"] as? Bool) ?? false
        let entries = try await CurrentOperation.run(bundleID: bundle, simulatorUDID: context.defaultSimulator)

        let filteredEntries: [HeapClassEntry]
        let hidden: Int
        if showAll {
            filteredEntries = entries
            hidden = 0
        } else {
            let result = NoiseFilter.defaultFramework.apply(to: entries)
            filteredEntries = result.kept
            hidden = result.droppedCount
        }

        let top = Array(filteredEntries.sorted { $0.totalBytes > $1.totalBytes }.prefix(20))
        if top.isEmpty {
            if hidden > 0 {
                return toolText("heap returned no rows after filtering (\(hidden) framework class\(hidden == 1 ? "" : "es") hidden — pass all=true to show)")
            }
            return toolText("heap returned no parseable rows")
        }
        let nameWidth = max(9, top.map { $0.className.count }.max() ?? 0)
        let countWidth = max(5, top.map { String($0.instanceCount).count }.max() ?? 0)
        let bytesStrs = top.map { BytesFormatter.format($0.totalBytes) }
        let bytesWidth = max(5, bytesStrs.map(\.count).max() ?? 0)

        let totalWidth = nameWidth + 2 + countWidth + 2 + bytesWidth
        let rule = String(repeating: "─", count: totalWidth)

        var lines: [String] = []
        lines.append(
            "ClassName".padded(toRight: nameWidth)
                + "  " + "Count".padded(toLeft: countWidth)
                + "  " + "Bytes".padded(toLeft: bytesWidth)
        )
        lines.append(rule)
        for (i, entry) in top.enumerated() {
            lines.append(
                entry.className.padded(toRight: nameWidth)
                    + "  " + String(entry.instanceCount).padded(toLeft: countWidth)
                    + "  " + bytesStrs[i].padded(toLeft: bytesWidth)
            )
        }
        var output = lines.joined(separator: "\n")
        if hidden > 0 {
            output += "\n\n(\(hidden) framework class\(hidden == 1 ? "" : "es") hidden — pass all=true to show)"
        }
        return toolText(output)
    }

    private static func callLeaks(_ args: [String: Any], context: ToolContext) async throws -> [String: Any] {
        guard let bundle = (args["bundle"] as? String) ?? context.defaultBundle else {
            return toolError("missing 'bundle' argument and no default bundle was set on `memwatch mcp --bundle`")
        }
        let raw = try await LeaksOperation.run(bundleID: bundle, simulatorUDID: context.defaultSimulator)
        return toolText(raw)
    }

    private static func toolText(_ text: String) -> [String: Any] {
        ["content": [["type": "text", "text": text]], "isError": false]
    }

    private static func toolError(_ text: String) -> [String: Any] {
        ["content": [["type": "text", "text": text]], "isError": true]
    }
}
