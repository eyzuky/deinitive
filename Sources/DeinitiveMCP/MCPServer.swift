import Foundation
import DeinitiveCore

public actor MCPServer {
    public static let protocolVersion = "2025-11-25"
    public static let serverName = "deinitive"
    public static let serverVersion = "0.1.0"

    private let context: ToolContext
    private let logToStderr: Bool

    public init(defaultBundle: String?, defaultSimulator: String?, logToStderr: Bool) {
        self.context = ToolContext(defaultBundle: defaultBundle, defaultSimulator: defaultSimulator)
        self.logToStderr = logToStderr
    }

    public func run() async throws {
        log("starting deinitive MCP server (protocol \(Self.protocolVersion))")
        var buffer = Data()
        for try await byte in FileHandle.standardInput.bytes {
            if byte == 0x0A {  // LF
                await processBuffer(&buffer)
            } else {
                buffer.append(byte)
            }
        }
        // Trailing line without newline.
        if !buffer.isEmpty {
            await processBuffer(&buffer)
        }
        log("stdin closed; shutting down")
    }

    private func processBuffer(_ buffer: inout Data) async {
        defer { buffer.removeAll(keepingCapacity: true) }
        guard !buffer.isEmpty else { return }
        let data = buffer

        let message: [String: Any]
        do {
            message = try JSONRPC.decode(data)
        } catch {
            log("parse error: \(error.localizedDescription)")
            send(JSONRPC.errorEnvelope(
                id: nil,
                code: JSONRPC.ErrorCode.parseError,
                message: "parse error"
            ))
            return
        }

        await dispatch(message)
    }

    private func dispatch(_ message: [String: Any]) async {
        let method = message["method"] as? String ?? ""
        let id = message["id"]
        let params = message["params"] as? [String: Any]
        let isNotification = (id == nil)

        log("← \(method)")

        switch method {
        case "initialize":
            send(JSONRPC.responseEnvelope(id: id, result: handleInitialize(params: params)))
        case "notifications/initialized":
            // No response for notifications.
            log("client signaled initialized")
        case "tools/list":
            send(JSONRPC.responseEnvelope(id: id, result: ["tools": ToolRegistry.toolListPayload()]))
        case "tools/call":
            let result = await handleToolsCall(params: params)
            send(JSONRPC.responseEnvelope(id: id, result: result))
        case "ping":
            send(JSONRPC.responseEnvelope(id: id, result: [:]))
        default:
            if !isNotification {
                send(JSONRPC.errorEnvelope(
                    id: id,
                    code: JSONRPC.ErrorCode.methodNotFound,
                    message: "Method not found: \(method)"
                ))
            } else {
                log("ignoring unknown notification \(method)")
            }
        }
    }

    private func handleInitialize(params: [String: Any]?) -> [String: Any] {
        let clientVersion = (params?["protocolVersion"] as? String) ?? "?"
        log("client requested protocol \(clientVersion)")
        return [
            "protocolVersion": Self.protocolVersion,
            "capabilities": [
                "tools": [String: Any]()
            ],
            "serverInfo": [
                "name": Self.serverName,
                "version": Self.serverVersion
            ]
        ]
    }

    private func handleToolsCall(params: [String: Any]?) async -> [String: Any] {
        guard let name = params?["name"] as? String else {
            return ["content": [["type": "text", "text": "tools/call missing 'name'"]], "isError": true]
        }
        let arguments = (params?["arguments"] as? [String: Any]) ?? [:]
        log("tools/call \(name) \(arguments)")
        return await ToolDispatcher.call(name: name, arguments: arguments, context: context)
    }

    private func send(_ payload: [String: Any]) {
        do {
            var data = try JSONRPC.encode(payload)
            data.append(0x0A)
            FileHandle.standardOutput.write(data)
        } catch {
            log("encode error: \(error.localizedDescription)")
        }
    }

    private nonisolated func log(_ message: String) {
        guard logToStderr else { return }
        let line = "[deinitive mcp] \(message)\n"
        FileHandle.standardError.write(Data(line.utf8))
    }
}
