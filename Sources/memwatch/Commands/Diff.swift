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

    @Option(name: .long, help: "show only the top N rows by abs(\u{0394}Bytes); 0 = unlimited (default 20)")
    var top: Int = 20

    func run() async throws {
        let store = SnapshotStore()
        let beforeSnap = try store.load(tag: before)
        let afterSnap = try store.load(tag: after)
        let computed = HeapDiff.compute(before: beforeSnap.heap, after: afterSnap.heap)

        let allDeltas: [ClassDelta]
        let frameworkHidden: Int
        if all {
            allDeltas = computed
            frameworkHidden = 0
        } else {
            let result = NoiseFilter.defaultFramework.apply(to: computed)
            allDeltas = result.kept
            frameworkHidden = result.droppedCount
        }

        let displayed: [ClassDelta]
        let belowFold: Int
        if top > 0 && allDeltas.count > top {
            displayed = Array(allDeltas.prefix(top))
            belowFold = allDeltas.count - top
        } else {
            displayed = allDeltas
            belowFold = 0
        }

        if displayed.isEmpty {
            if frameworkHidden > 0 {
                print("no differences after filtering (\(frameworkHidden) framework class\(frameworkHidden == 1 ? "" : "es") hidden — pass --all to show)")
            } else {
                print("no differences between '\(before)' and '\(after)'")
            }
            return
        }

        // "Probably your code" section pulled from the post-filter, pre-top-cap set so
        // a small (low-bytes) user-code leak doesn't get hidden below the --top fold.
        if let userSection = DiffFormatter.formatUserCodeSection(allDeltas) {
            print(userSection)
            print("")
        }

        let colorize: Bool? = noColor ? false : nil
        print(DiffFormatter.format(displayed, colorize: colorize))
        printFooter(frameworkHidden: frameworkHidden, belowFold: belowFold)
    }

    private func printFooter(frameworkHidden: Int, belowFold: Int) {
        var notes: [String] = []
        if frameworkHidden > 0 {
            notes.append("\(frameworkHidden) framework class\(frameworkHidden == 1 ? "" : "es") hidden — pass --all to show")
        }
        if belowFold > 0 {
            notes.append("\(belowFold) more row\(belowFold == 1 ? "" : "s") below the top \(top) — pass --top 0 to show")
        }
        guard !notes.isEmpty else { return }
        print("")
        for note in notes { print("(\(note))") }
    }
}
