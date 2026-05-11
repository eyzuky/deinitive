# deinitive

[![Swift 5.10+](https://img.shields.io/badge/Swift-5.10+-orange.svg)](https://swift.org)
[![macOS 14+](https://img.shields.io/badge/macOS-14+-blue.svg)](#)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](./LICENSE)
[![MCP 2025-11-25](https://img.shields.io/badge/MCP-2025--11--25-purple.svg)](https://modelcontextprotocol.io)

iOS simulator memory profiling in two commands. Snapshot the heap, navigate, snapshot again, diff. Plus an MCP server so coding agents (Cursor, Claude Code) can hunt leaks alongside reading your source.

<!-- demo GIF — record per the script in examples/LeakLab/README.md and replace this line -->
<!-- ![demo](docs/deinitive-demo.gif) -->

```
$ deinitive start --bundle com.example.app

Step 1 of 3 — go to the baseline screen — the place you'll start and end the round trip.
Press Enter when ready: 
captured 1247 classes (8.0 MB)

Step 2 of 3 — navigate into the flow you want to test, all the way to the deepest screen.
Press Enter when ready: 
captured 1494 classes (8.6 MB)

Step 3 of 3 — navigate back to the baseline screen.
Press Enter when ready: 
captured 1264 classes (8.4 MB)

════════════════════════════════════════════════════════════════
deinitive start: round-trip residue (baseline → after)
════════════════════════════════════════════════════════════════

▸ Probably your code (2 classes)

ClassName                   ΔCount  ΔBytes
──────────────────────────────────────────
GhostController                +12  +124 KB
ChildVM                         +3    +96 B

▸ All classes (top 20 by |ΔBytes|)

ClassName                      ΔCount  ΔBytes
─────────────────────────────────────────────
SCNNode                          +247  +198 KB
GhostController                   +12  +124 KB
SCNGeometry                       +18   +89 KB
UIImage                            +3   +12 KB
NSConcreteMutableData              +2    +8 KB
ChildVM                            +3    +96 B
─────────────────────────────────────────────
                                       +431 KB
```

`deinitive start` walks you through a baseline → flow → back round trip and prints what didn't release. The "Probably your code" section pulls user-defined classes out of the noise so you don't squint past 200 rows of `NSConcreteMutableData` churn.

## install

### Homebrew (recommended)

```
brew install eyzuky/deinitive/deinitive
```

### Prebuilt binary

Download `deinitive-v0.1.0-arm64.tar.gz` from [Releases](https://github.com/eyzuky/deinitive/releases) and copy to `/opt/homebrew/bin/`.

### From source

```
git clone https://github.com/eyzuky/deinitive && cd deinitive
swift build -c release
cp .build/release/deinitive /opt/homebrew/bin/
```

Requires macOS 14+ (Apple Silicon) and Xcode Command Line Tools (`xcode-select --install`).

## commands

`start` is the recommended workflow. The lower-level subcommands let you script your own captures or diff older snapshots:

```
deinitive start <flags>                         # interactive: baseline → flow → back, then auto-diff
deinitive snapshot --tag <name> --bundle <id> [--simulator <udid>]
deinitive diff <before> <after> [--no-color] [--all] [--top N]
deinitive list
deinitive clear [--yes]
deinitive mcp --bundle <id> [--simulator <udid>] [--log-stderr]
```

`deinitive start` flags: `--bundle <id>` (required), `--simulator <udid>`, `--no-color`, `--all`, `--top N` (default 20, 0 = unlimited).

Snapshots persist under `.deinitive/snapshots/` in the current directory. Each is a small JSON file you can commit, share, or delete. `start` always writes to `start-baseline`, `start-peak`, `start-post` — you can re-run a manual `deinitive diff start-baseline start-post` any time without re-walking the flow.

`diff` filters out a curated set of iOS framework warmup classes (Auto Layout solver, glyph caches, Obj-C runtime metadata, render-tree internals, etc.) so the signal-to-noise ratio is workable out of the box, and shows only the top 20 rows by `abs(ΔBytes)`. Class names over 50 chars are truncated. Pass `--all` to disable the noise filter, `--top 0` to remove the row cap. The same filter and cap apply to the `deinitive_diff` and `deinitive_current` MCP tools (`all: true`, `top: 0`).

## MCP

Add to `~/.cursor/mcp.json` (or your agent's equivalent):

```json
{
  "mcpServers": {
    "deinitive": {
      "command": "/opt/homebrew/bin/deinitive",
      "args": ["mcp", "--bundle", "com.example.app"]
    }
  }
}
```

Tools exposed:

- `deinitive_snapshot(tag, bundle?)`
- `deinitive_diff(before, after, all?)`
- `deinitive_current(bundle?, all?)` — top-20 allocators, no persistence
- `deinitive_leaks(bundle?)` — raw `leaks` output

`bundle` defaults to whatever was passed via `--bundle` on `deinitive mcp`; tool calls can override per-invocation. The server pins MCP protocol version `2025-11-25` and logs to stderr only when `--log-stderr` is set.

## try it on the bundled demo app

[`examples/LeakLab/`](./examples/LeakLab/) is a small iOS app with five flows, each containing a different memory issue (closure cycle, observer leak, timer cycle, Combine subscription, singleton retention). Each demo has a switch to toggle between broken and fixed.

```
cd examples/LeakLab
brew install xcodegen
xcodegen generate
open LeakLab.xcodeproj
# Hit Run on an iPhone simulator, then from the repo root:
deinitive start --bundle com.deinitive.LeakLab
# Follow the prompts: menu → tap demo + Trigger → back to menu
```

Full instructions in [examples/LeakLab/README.md](./examples/LeakLab/README.md).

## known limitations

- Simulator only — no device support. Devices need entitlements and a different attach flow.
- Requires the app to already be running in a booted simulator.
- `heap` and `leaks` are macOS-only tools, so deinitive itself is macOS-only.

## license

MIT — see [LICENSE](./LICENSE).
