# deinitive v0.1.0 — initial public release

iOS simulator memory profiling in two commands. Snapshot the heap, navigate, snapshot again, diff. Plus an MCP server so coding agents can hunt leaks alongside reading your source.

## what's in the box

- **`deinitive start`** — guided baseline → flow → back snapshot session, auto-diffs at the end. The recommended workflow.
- **`deinitive snapshot / diff / list / clear`** — lower-level snapshot ops for scripting.
- **`deinitive mcp`** — hand-rolled MCP server (protocol `2025-11-25`) exposing four tools to AI coding agents:
  - `deinitive_snapshot(tag, bundle?)` — capture & persist
  - `deinitive_diff(before, after, all?, top?)` — round-trip residue
  - `deinitive_current(bundle?, all?, top?)` — top-N allocators, no save
  - `deinitive_leaks(bundle?)` — Apple `leaks` raw output
- **Curated noise filter** — hides ~40 framework-allocation patterns (Auto Layout solver, glyph caches, runtime metadata, render tree, SwiftUI internals, etc.) by default. Pass `--all` to disable.
- **"Probably your code" highlight** — pulls user-defined classes above the main diff using a name-prefix heuristic, so a small leak isn't buried under 200 rows of `NSConcreteMutableData` churn.
- **Robust shell timeouts** — 45s default with proper child-process termination + pipe FD cleanup so a wedged `simctl` daemon can't hang `deinitive` forever.

## bundled demo app

[`examples/LeakLab/`](https://github.com/eyzuky/deinitive/tree/main/examples/LeakLab) is a small UIKit + SwiftUI app with five leak archetypes (closure cycle, notification observer, timer, Combine sink, singleton retention). Each demo has an "Apply fix" toggle to compare broken vs fixed; verify deinitive surfaces the leak in the broken case and shows nothing leaked in the fixed case.

## install

```
brew install eyzuky/deinitive/deinitive
```

Or download `deinitive-v0.1.0-arm64.tar.gz` below and copy to `/opt/homebrew/bin/`.

## requires

macOS 14+ (Apple Silicon), Xcode Command Line Tools (`xcode-select --install`).

## known limitations

- Simulator only — no device support.
- Requires the target app to already be running in a booted simulator.
- arm64 only for v0.1; x86 binaries on request.

## thanks

Built in a few weekends with a lot of help from Claude Code.
