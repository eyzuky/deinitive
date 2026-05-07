import ArgumentParser

@main
struct Memwatch: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "memwatch",
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
