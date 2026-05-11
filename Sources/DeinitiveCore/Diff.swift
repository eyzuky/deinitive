import Foundation

public enum HeapDiff {
    public static func compute(before: [HeapClassEntry], after: [HeapClassEntry]) -> [ClassDelta] {
        let beforeMap = Dictionary(grouping: before, by: \.className).mapValues { $0[0] }
        let afterMap = Dictionary(grouping: after, by: \.className).mapValues { $0[0] }

        let allKeys = Set(beforeMap.keys).union(afterMap.keys)
        let deltas: [ClassDelta] = allKeys.compactMap { className in
            let b = beforeMap[className]
            let a = afterMap[className]
            let countDelta = (a?.instanceCount ?? 0) - (b?.instanceCount ?? 0)
            let bytesDelta = (a?.totalBytes ?? 0) - (b?.totalBytes ?? 0)
            if countDelta == 0 && bytesDelta == 0 { return nil }
            return ClassDelta(className: className, countDelta: countDelta, bytesDelta: bytesDelta)
        }

        return deltas.sorted {
            if abs($0.bytesDelta) != abs($1.bytesDelta) {
                return abs($0.bytesDelta) > abs($1.bytesDelta)
            }
            return $0.className < $1.className
        }
    }
}
