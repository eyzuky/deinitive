import ArgumentParser
import MemwatchCore

struct Diff: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "diff",
        abstract: "compare two snapshots"
    )

    @Argument(help: "earlier snapshot tag")
    var before: String

    @Argument(help: "later snapshot tag")
    var after: String

    @Flag(help: "disable ANSI color output")
    var noColor: Bool = false

    @Flag(help: "show all classes including framework warmup noise")
    var all: Bool = false

    func run() async throws {
        let store = SnapshotStore()
        let beforeSnap = try store.load(tag: before)
        let afterSnap = try store.load(tag: after)
        let computed = HeapDiff.compute(before: beforeSnap.heap, after: afterSnap.heap)

        let deltas: [ClassDelta]
        let hidden: Int
        if all {
            deltas = computed
            hidden = 0
        } else {
            let result = NoiseFilter.defaultFramework.apply(to: computed)
            deltas = result.kept
            hidden = result.droppedCount
        }

        if deltas.isEmpty {
            if hidden > 0 {
                print("no differences after filtering (\(hidden) framework class\(hidden == 1 ? "" : "es") hidden — pass --all to show)")
            } else {
                print("no differences between '\(before)' and '\(after)'")
            }
            return
        }

        let colorize: Bool? = noColor ? false : nil
        print(DiffFormatter.format(deltas, colorize: colorize))
        if hidden > 0 {
            print("")
            print("(\(hidden) framework class\(hidden == 1 ? "" : "es") hidden — pass --all to show)")
        }
    }
}
