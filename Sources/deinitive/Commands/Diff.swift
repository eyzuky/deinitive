import ArgumentParser
import DeinitiveCore

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

        let useColor: Bool? = noColor ? false : nil
        let resolvedColor = useColor ?? ANSI.stdoutIsTTY

        printDiff(
            title: "deinitive diff: \(before) → \(after)",
            displayed: displayed,
            allDeltas: allDeltas,
            frameworkHidden: frameworkHidden,
            belowFold: belowFold,
            top: top,
            useColor: resolvedColor
        )
    }
}

func printDiff(
    title: String,
    displayed: [ClassDelta],
    allDeltas: [ClassDelta],
    frameworkHidden: Int,
    belowFold: Int,
    top: Int,
    useColor: Bool
) {
    print("")
    print(DiffFormatter.sectionHeader(title, useColor: useColor))
    print("")

    if displayed.isEmpty {
        if frameworkHidden > 0 {
            print("no differences after filtering (\(frameworkHidden) framework class\(frameworkHidden == 1 ? "" : "es") hidden — pass --all to show)")
        } else {
            print("no differences.")
        }
        return
    }

    // Probably-your-code section comes first, pulled from post-filter pre-top-cap so
    // a small user leak isn't hidden below the --top fold.
    if let userSection = DiffFormatter.formatUserCodeSection(allDeltas) {
        let userCount = allDeltas.filter { UserCodeHeuristic.isLikelyUserCode($0.className) }.count
        let label = userCount == 1 ? "Probably your code (1 class)" : "Probably your code (\(userCount) classes)"
        print(DiffFormatter.sectionLabel(label, useColor: useColor))
        print("")
        print(userSection)
        print("")
    }

    let allLabel = top > 0 ? "All classes (top \(top) by |ΔBytes|)" : "All classes"
    print(DiffFormatter.sectionLabel(allLabel, useColor: useColor))
    print("")
    print(DiffFormatter.format(displayed, colorize: useColor))

    var notes: [String] = []
    if frameworkHidden > 0 {
        notes.append("\(frameworkHidden) framework class\(frameworkHidden == 1 ? "" : "es") hidden — pass --all to show")
    }
    if belowFold > 0 {
        notes.append("\(belowFold) more row\(belowFold == 1 ? "" : "s") below the top \(top) — pass --top 0 to show")
    }
    if !notes.isEmpty {
        print("")
        for note in notes { print("(\(note))") }
    }
}
