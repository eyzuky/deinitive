import Foundation

func formatElapsed(_ seconds: TimeInterval) -> String {
    if seconds < 1 { return String(format: "%.0fms", seconds * 1000) }
    if seconds < 60 { return String(format: "%.1fs", seconds) }
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return "\(mins)m\(secs)s"
}
