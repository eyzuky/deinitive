import ArgumentParser
import DeinitiveMCP

struct MCP: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mcp",
        abstract: "start MCP server over stdio"
    )

    @Option(name: .shortAndLong, help: "default bundle identifier (tool calls can override)")
    var bundle: String?

    @Option(name: .shortAndLong, help: "simulator UDID (defaults to booted)")
    var simulator: String?

    @Flag(help: "log JSON-RPC traffic to stderr")
    var logStderr: Bool = false

    func run() async throws {
        let server = MCPServer(
            defaultBundle: bundle,
            defaultSimulator: simulator,
            logToStderr: logStderr
        )
        try await server.run()
    }
}
