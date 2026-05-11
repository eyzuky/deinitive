import ArgumentParser

@main
struct Deinitive: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "deinitive",
        abstract: "snapshot and diff iOS simulator heap state",
        subcommands: [
            Start.self,
            Snapshot.self,
            Diff.self,
            List.self,
            Clear.self,
            MCP.self,
        ]
    )
}
