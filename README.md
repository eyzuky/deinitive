# memwatch

```
$ memwatch start --bundle com.example.app

Step 1 of 3 — go to the baseline screen — the place you'll start and end the round trip.
Press Enter when ready: 
captured 1247 classes (8.0 MB)

Step 2 of 3 — navigate into the flow you want to test, all the way to the deepest screen.
Press Enter when ready: 
captured 1494 classes (8.6 MB)

Step 3 of 3 — navigate back to the baseline screen.
Press Enter when ready: 
captured 1264 classes (8.4 MB)

Round-trip residue (baseline → after):

ClassName                   ΔCount  ΔBytes
──────────────────────────────────────────
SCNNode                       +247  +198 KB
GhostController                +12  +124 KB
SCNGeometry                    +18   +89 KB
UIImage                         +3   +12 KB
NSConcreteMutableData           +2    +8 KB
──────────────────────────────────────────
                                     +431 KB

Saved as start-baseline, start-peak, start-post.
```

Memory profiler for the iOS simulator. `memwatch start` walks you through a baseline → flow → back round trip and prints what didn't release. Commands return in seconds. memwatch also ships an MCP server so coding agents can call the same operations alongside reading your source.

## install

```
swift build -c release
cp .build/release/memwatch /opt/homebrew/bin/   # or sudo cp …/usr/local/bin/
```

Requires macOS 14+ and Xcode Command Line Tools (`xcode-select --install`).

## commands

`start` is the recommended workflow. The lower-level subcommands let you script your own captures or diff older snapshots:

```
memwatch start <flags>                         # interactive: baseline → flow → back, then auto-diff
memwatch snapshot --tag <name> --bundle <id> [--simulator <udid>]
memwatch diff <before> <after> [--no-color] [--all]
memwatch list
memwatch clear [--yes]
memwatch mcp --bundle <id> [--simulator <udid>] [--log-stderr]
```

`memwatch start` flags: `--bundle <id>` (required), `--simulator <udid>`, `--no-color`, `--all`.

Snapshots persist under `.memwatch/snapshots/` in the current directory. Each is a small JSON file you can commit, share, or delete. `start` always writes to `start-baseline`, `start-peak`, `start-post` — you can re-run a manual `memwatch diff start-baseline start-post` any time without re-walking the flow.

`diff` filters out a curated set of iOS framework warmup classes (Auto Layout solver, glyph caches, Obj-C runtime metadata, render-tree internals, etc.) so the signal-to-noise ratio is workable out of the box. Pass `--all` to see every class. The same filter applies to the `memwatch_diff` and `memwatch_current` MCP tools — call with `all: true` to disable.

## MCP

Add to `~/.cursor/mcp.json` (or your agent's equivalent):

```json
{
  "mcpServers": {
    "memwatch": {
      "command": "/opt/homebrew/bin/memwatch",
      "args": ["mcp", "--bundle", "com.example.app"]
    }
  }
}
```

Tools exposed:

- `memwatch_snapshot(tag, bundle?)`
- `memwatch_diff(before, after, all?)`
- `memwatch_current(bundle?, all?)` — top-20 allocators, no persistence
- `memwatch_leaks(bundle?)` — raw `leaks` output

`bundle` defaults to whatever was passed via `--bundle` on `memwatch mcp`; tool calls can override per-invocation. The server pins MCP protocol version `2025-11-25` and logs to stderr only when `--log-stderr` is set.

## try it on the bundled demo app

[`examples/LeakLab/`](./examples/LeakLab/) is a small iOS app with five flows, each containing a different memory issue (closure cycle, observer leak, timer cycle, Combine subscription, singleton retention). Each demo has a switch to toggle between broken and fixed.

```
cd examples/LeakLab
brew install xcodegen
xcodegen generate
open LeakLab.xcodeproj
# Hit Run on an iPhone simulator, then from the repo root:
memwatch start --bundle com.memwatch.LeakLab
# Follow the prompts: menu → tap demo + Trigger → back to menu
```

Full instructions in [examples/LeakLab/README.md](./examples/LeakLab/README.md).

## known limitations

- Simulator only — no device support. Devices need entitlements and a different attach flow.
- Requires the app to already be running in a booted simulator.
- `heap` and `leaks` are macOS-only tools, so memwatch itself is macOS-only.

## license

MIT — see [LICENSE](./LICENSE).
