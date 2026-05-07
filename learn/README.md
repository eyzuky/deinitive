# memwatch / learn

Static four-lesson site that fills the gaps between "senior iOS dev" and "ready to ship a tool like memwatch." All client-side; nothing leaves your machine.

## Run

From this directory:

```
python3 -m http.server 8000
```

Then open http://localhost:8000 in your browser.

(Or just open `index.html` directly — it works as a `file://` URL too.)

## Lessons

1. **iOS memory: ARC, retain cycles, leaks** — heap vs. leak, the navigate-and-back bug, why diffing snapshots is the right unit
2. **Swift CLIs and SPM** — Swift outside Xcode: Package.swift, executable targets, ArgumentParser
3. **Apple shell tools** — `xcrun simctl`, `heap`, `leaks`, `swift-demangle`, and how memwatch composes them
4. **JSON-RPC, MCP, and the big picture** — the wire protocol, the handshake, why agent + memwatch beats either alone

Each lesson: prose, an interactive stepper diagram, clickable callouts for jargon, and a 3-question quiz. Progress saves to `localStorage` keyed by lesson id; reset from the index page.

## Files

```
index.html
lessons/
  01-memory.html
  02-swift-cli.html
  03-shell-tools.html
  04-mcp.html
assets/
  style.css
  app.js
```

No build step, no dependencies, no tracking. Vanilla HTML + CSS + JS.
