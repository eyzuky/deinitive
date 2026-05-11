import Foundation

#if canImport(Darwin)
import Darwin
#endif

public enum ANSI {
    public static let reset = "\u{001B}[0m"
    public static let bold = "\u{001B}[1m"
    public static let dim = "\u{001B}[2m"
    public static let red = "\u{001B}[31m"
    public static let green = "\u{001B}[32m"
    public static let yellow = "\u{001B}[33m"
    public static let cyan = "\u{001B}[36m"

    public static var stdoutIsTTY: Bool {
        #if canImport(Darwin)
        return isatty(fileno(stdout)) != 0
        #else
        return false
        #endif
    }

    public static func boldCyan(_ text: String, useColor: Bool) -> String {
        useColor ? bold + cyan + text + reset : text
    }

    public static func boldText(_ text: String, useColor: Bool) -> String {
        useColor ? bold + text + reset : text
    }

    public static func greenText(_ text: String, useColor: Bool) -> String {
        useColor ? green + text + reset : text
    }
}

public enum BytesFormatter {
    public static func format(_ bytes: Int, signed: Bool = false) -> String {
        if bytes == 0 { return signed ? "0 B" : "0 B" }
        let signedPrefix = signed && bytes > 0 ? "+" : (bytes < 0 ? "-" : "")
        let abs = Swift.abs(bytes)
        if abs < 1024 {
            return "\(signedPrefix)\(abs) B"
        }
        if abs < 1024 * 1024 {
            let kb = Int((Double(abs) / 1024.0).rounded())
            return "\(signedPrefix)\(kb) KB"
        }
        let mb = Double(abs) / (1024.0 * 1024.0)
        if mb < 100 {
            return String(format: "%@%.1f MB", signedPrefix, mb)
        }
        return "\(signedPrefix)\(Int(mb.rounded())) MB"
    }
}

public enum DiffFormatter {
    public static let defaultMaxClassNameWidth = 50

    // Wraps a string in a fixed-width "═══" header bar with the given title centered (well, left-padded).
    public static func sectionHeader(_ title: String, width: Int = 64, useColor: Bool? = nil) -> String {
        let color = useColor ?? ANSI.stdoutIsTTY
        let rule = String(repeating: "═", count: width)
        let lines = [rule, title, rule]
        return lines.map { ANSI.boldCyan($0, useColor: color) }.joined(separator: "\n")
    }

    public static func sectionLabel(_ text: String, useColor: Bool? = nil) -> String {
        let color = useColor ?? ANSI.stdoutIsTTY
        return ANSI.boldCyan("▸ \(text)", useColor: color)
    }

    public static func format(
        _ deltas: [ClassDelta],
        colorize: Bool? = nil,
        maxClassNameWidth: Int = defaultMaxClassNameWidth,
        highlightUserCode: Bool = true
    ) -> String {
        let useColor = colorize ?? ANSI.stdoutIsTTY

        let header = (className: "ClassName", count: "ΔCount", bytes: "ΔBytes")

        let rows: [(className: String, count: String, bytes: String, delta: ClassDelta)] =
            deltas.map { d in
                (
                    className: truncate(d.className, to: maxClassNameWidth),
                    count: formatCount(d.countDelta),
                    bytes: BytesFormatter.format(d.bytesDelta, signed: true),
                    delta: d
                )
            }

        let classWidth = max(header.className.count, rows.map { $0.className.count }.max() ?? 0)
        let countWidth = max(header.count.count, rows.map { $0.count.count }.max() ?? 0)
        let bytesWidth = max(header.bytes.count, rows.map { $0.bytes.count }.max() ?? 0)

        let gutter = "  "
        let totalWidth = classWidth + gutter.count + countWidth + gutter.count + bytesWidth
        let rule = String(repeating: "─", count: totalWidth)

        var lines: [String] = []
        lines.append(
            header.className.padded(toRight: classWidth)
                + gutter + header.count.padded(toLeft: countWidth)
                + gutter + header.bytes.padded(toLeft: bytesWidth)
        )
        lines.append(rule)

        for row in rows {
            let line = row.className.padded(toRight: classWidth)
                + gutter + row.count.padded(toLeft: countWidth)
                + gutter + row.bytes.padded(toLeft: bytesWidth)
            let isUser = highlightUserCode && UserCodeHeuristic.isLikelyUserCode(row.delta.className)
            let formatted: String
            if useColor {
                if row.delta.bytesDelta < 0 {
                    formatted = ANSI.greenText(line, useColor: true)
                } else if isUser {
                    formatted = ANSI.boldText(line, useColor: true)
                } else {
                    formatted = line
                }
            } else {
                formatted = line
            }
            lines.append(formatted)
        }
        lines.append(rule)

        let totalBytes = deltas.reduce(0) { $0 + $1.bytesDelta }
        let totalStr = BytesFormatter.format(totalBytes, signed: true)
        let totalLine = String(repeating: " ", count: classWidth + gutter.count + countWidth)
            + gutter + totalStr.padded(toLeft: bytesWidth)
        lines.append(totalLine)

        return lines.joined(separator: "\n")
    }

    private static func formatCount(_ count: Int) -> String {
        if count == 0 { return "0" }
        return count > 0 ? "+\(count)" : "\(count)"
    }

    public static func truncate(_ name: String, to maxChars: Int) -> String {
        guard maxChars > 1, name.count > maxChars else { return name }
        return String(name.prefix(maxChars - 1)) + "…"
    }

    // Renders the small "Probably your code (N classes)" mini-table of user-defined
    // classes (heuristically detected). Returns nil if there are no user-code rows.
    // Pulled from the post-filter, pre-top-cap set so a tiny user leak doesn't get
    // hidden below the --top fold.
    public static func formatUserCodeSection(_ deltas: [ClassDelta], maxClassNameWidth: Int = defaultMaxClassNameWidth) -> String? {
        let user = deltas.filter { UserCodeHeuristic.isLikelyUserCode($0.className) }
        guard !user.isEmpty else { return nil }
        return format(user, maxClassNameWidth: maxClassNameWidth, highlightUserCode: true)
    }
}

public extension String {
    func padded(toRight width: Int, with pad: Character = " ") -> String {
        if count >= width { return self }
        return self + String(repeating: pad, count: width - count)
    }

    func padded(toLeft width: Int, with pad: Character = " ") -> String {
        if count >= width { return self }
        return String(repeating: pad, count: width - count) + self
    }
}
