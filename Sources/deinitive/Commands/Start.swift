import ArgumentParser
import Foundation
import DeinitiveCore

#if canImport(Darwin)
import Darwin
#endif

struct Start: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "interactive snapshot–navigate–snapshot session, then auto-diff"
    )

    @Option(name: .shortAndLong, help: "bundle identifier of the running app")
    var bundle: String

    @Option(name: .shortAndLong, help: "simulator UDID (defaults to booted)")
    var simulator: String?

    @Flag(help: "disable ANSI color output")
    var noColor: Bool = false

    @Flag(help: "show all classes including framework warmup noise")
    var all: Bool = false

    @Option(name: .long, help: "show only the top N rows in the diff; 0 = unlimited (default 20)")
    var top: Int = 20

    func run() async throws {
        // Make stdout unbuffered so prompts appear in order even when piped or captured.
        setbuf(stdout, nil)

        let store = SnapshotStore()

        guard let baseline = try await prompt(
            stepIndex: 1,
            instruction: "go to the baseline screen — the place you'll start and end the round trip",
            tag: "start-baseline",
            store: store
        ) else { cancelled(); return }

        guard let peak = try await prompt(
            stepIndex: 2,
            instruction: "navigate into the flow you want to test, all the way to the deepest screen",
            tag: "start-peak",
            store: store
        ) else { cancelled(); return }

        guard let post = try await prompt(
            stepIndex: 3,
            instruction: "navigate back to the baseline screen",
            tag: "start-post",
            store: store
        ) else { cancelled(); return }

        _ = peak  // kept for completeness; user can `deinitive diff start-baseline start-peak` later

        let computed = HeapDiff.compute(before: baseline.heap, after: post.heap)
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

        let useColor = noColor ? false : ANSI.stdoutIsTTY
        printDiff(
            title: "deinitive start: round-trip residue (baseline → after)",
            displayed: displayed,
            allDeltas: allDeltas,
            frameworkHidden: frameworkHidden,
            belowFold: belowFold,
            top: top,
            useColor: useColor
        )

        print("")
        print("Saved as start-baseline, start-peak, start-post. Re-run `deinitive diff start-baseline start-post` any time without re-walking the flow.")
    }

    private func prompt(
        stepIndex: Int,
        instruction: String,
        tag: String,
        store: SnapshotStore
    ) async throws -> DeinitiveCore.Snapshot? {
        print("")
        print("Step \(stepIndex) of 3 — \(instruction).")
        writeRaw("Press Enter when ready: ")
        guard readLine() != nil else { return nil }  // EOF (Ctrl-D) → graceful cancel

        let started = Date()
        let snapshot = try await withTicker {
            try await SnapshotOperation.run(
                tag: tag,
                bundleID: bundle,
                simulatorUDID: simulator,
                store: store,
                progress: { msg in
                    FileHandle.standardOutput.write(Data("  \(msg)\n".utf8))
                }
            )
        }
        let elapsed = Date().timeIntervalSince(started)
        let total = BytesFormatter.format(snapshot.totalBytes)
        print("  captured \(snapshot.heap.count) classes (\(total)) in \(formatElapsed(elapsed))")
        return snapshot
    }

    private func cancelled() {
        print("")
        print("session cancelled.")
    }

    // print(_:terminator:) buffers when stdout isn't a TTY; we want the prompt visible
    // before readLine() blocks, so write directly to the file handle.
    private func writeRaw(_ s: String) {
        FileHandle.standardOutput.write(Data(s.utf8))
    }
}
