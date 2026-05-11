import Foundation

public enum HeapParser {
    public static func parse(_ output: String) -> [HeapClassEntry] {
        let lines = output.components(separatedBy: "\n")

        guard let headerIdx = lines.firstIndex(where: { isHeader($0) }) else {
            return []
        }

        var i = headerIdx + 1
        // Skip any separator rows (predominantly '=' chars).
        while i < lines.count, isSeparator(lines[i]) {
            i += 1
        }

        var entries: [HeapClassEntry] = []
        while i < lines.count {
            let line = lines[i]
            i += 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { break }

            let tokens = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard tokens.count >= 4 else { continue }

            let countStr = tokens[0].replacingOccurrences(of: ",", with: "")
            let bytesStr = tokens[1].replacingOccurrences(of: ",", with: "")
            guard let count = Int(countStr), let bytes = Int(bytesStr) else { continue }

            // tokens[2] is AVG (e.g. "2.0K") — discarded.
            // tokens[3] onwards is the class name; some heap versions append TYPE/BINARY columns.
            // Take the first non-numeric token after AVG as the class name.
            let className = tokens[3]
            entries.append(HeapClassEntry(className: className, instanceCount: count, totalBytes: bytes))
        }

        return entries
    }

    private static func isHeader(_ line: String) -> Bool {
        let upper = line.uppercased()
        return upper.contains("COUNT") && upper.contains("BYTES") && upper.contains("CLASS")
    }

    private static func isSeparator(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return trimmed.allSatisfy { $0 == "=" || $0.isWhitespace }
    }
}
