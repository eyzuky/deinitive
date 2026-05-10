import Foundation

#if canImport(Darwin)
import Darwin
#endif

public enum ANSI {
    public static let reset = "\u{001B}[0m"
    public static let red = "\u{001B}[31m"
    public static let green = "\u{001B}[32m"
    public static let dim = "\u{001B}[2m"

    public static var stdoutIsTTY: Bool {
        #if canImport(Darwin)
        return isatty(fileno(stdout)) != 0
        #else
        return false
        #endif
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

    public static func format(_ deltas: [ClassDelta], colorize: Bool? = nil, maxClassNameWidth: Int = defaultMaxClassNameWidth) -> String {
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
            if useColor {
                let colorPrefix: String
                if row.delta.bytesDelta > 0 {
                    colorPrefix = ANSI.red
                } else if row.delta.bytesDelta < 0 {
                    colorPrefix = ANSI.green
                } else {
                    colorPrefix = ""
                }
                lines.append(colorPrefix + line + (colorPrefix.isEmpty ? "" : ANSI.reset))
            } else {
                lines.append(line)
            }
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

    // Renders a small "Probably your code (N classes):" block listing classes whose
    // names look user-defined (no framework prefix). Returns nil if there's nothing
    // to surface. The caller prints this above the main diff table so the user's
    // own leaks don't get lost in the framework long tail.
    public static func formatUserCodeSection(_ deltas: [ClassDelta], maxClassNameWidth: Int = defaultMaxClassNameWidth) -> String? {
        let user = deltas.filter { UserCodeHeuristic.isLikelyUserCode($0.className) }
        guard !user.isEmpty else { return nil }

        let truncated = user.map { truncate($0.className, to: maxClassNameWidth) }
        let counts = user.map { formatCount($0.countDelta) }
        let bytes = user.map { BytesFormatter.format($0.bytesDelta, signed: true) }

        let nameWidth = truncated.map { $0.count }.max() ?? 0
        let countWidth = counts.map { $0.count }.max() ?? 0
        let bytesWidth = bytes.map { $0.count }.max() ?? 0

        var lines: [String] = []
        let label = user.count == 1 ? "Probably your code (1 class):" : "Probably your code (\(user.count) classes):"
        lines.append(label)
        for i in user.indices {
            lines.append(
                "  " + truncated[i].padded(toRight: nameWidth)
                    + "  " + counts[i].padded(toLeft: countWidth)
                    + "  " + bytes[i].padded(toLeft: bytesWidth)
            )
        }
        return lines.joined(separator: "\n")
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
