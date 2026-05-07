import XCTest
@testable import MemwatchCore

final class NoiseFilterTests: XCTestCase {
    private let f = NoiseFilter.defaultFramework

    func testExactMatchesAreFiltered() {
        XCTAssertTrue(f.isNoise("non-object"))
        XCTAssertTrue(f.isNoise("@autoreleasepool"))
        XCTAssertTrue(f.isNoise("__NSMallocBlock__"))
        XCTAssertTrue(f.isNoise("Class.methodCache._buckets"))
        XCTAssertTrue(f.isNoise("Class.data"))
        XCTAssertTrue(f.isNoise("CFRunLoop"))
        XCTAssertTrue(f.isNoise("CABackingStore"))
        XCTAssertTrue(f.isNoise("UITraitCollection"))
        XCTAssertTrue(f.isNoise("NSISVariableObservation"))
    }

    func testPrefixMatchesAreFiltered() {
        XCTAssertTrue(f.isNoise("Swift._SetStorage<Swift.Int>"))
        XCTAssertTrue(f.isNoise("Swift._SetStorage<Swift.String>"))
        XCTAssertTrue(f.isNoise("Swift._DictionaryStorage<Swift.ObjectIdentifier,Swift.Int>"))
        XCTAssertTrue(f.isNoise("UIKit._UIObjCEquatableBox<UIKit._GlassBackgroundStyle>"))
        XCTAssertTrue(f.isNoise("Gestures.GestureNode<()>"))
    }

    func testGenericFoundationClassesAreNotFiltered() {
        // These are widely allocated by both framework and user code; we don't filter them
        // because doing so would silently hide real leaks.
        XCTAssertFalse(f.isNoise("CFString"))
        XCTAssertFalse(f.isNoise("NSDictionary"))
        XCTAssertFalse(f.isNoise("NSMutableArray"))
        XCTAssertFalse(f.isNoise("NSNumber"))
        XCTAssertFalse(f.isNoise("UIView"))
        XCTAssertFalse(f.isNoise("CALayer"))
        XCTAssertFalse(f.isNoise("Closure"))
        XCTAssertFalse(f.isNoise("NSLayoutConstraint"))
    }

    func testUserClassesArePreserved() {
        XCTAssertFalse(f.isNoise("ChildVM"))
        XCTAssertFalse(f.isNoise("ClosureCycleViewController"))
        XCTAssertFalse(f.isNoise("LeakLab.Subscriber"))
    }

    func testApplyToDeltasDropsAndCounts() {
        let deltas = [
            ClassDelta(className: "non-object", countDelta: 100, bytesDelta: 1024),
            ClassDelta(className: "ChildVM", countDelta: 3, bytesDelta: 96),
            ClassDelta(className: "CABackingStore", countDelta: 5, bytesDelta: 5000),
            ClassDelta(className: "ClosureCycleViewController", countDelta: 1, bytesDelta: 800),
            ClassDelta(className: "Swift._SetStorage<Swift.Int>", countDelta: 8, bytesDelta: 2000),
        ]
        let (kept, dropped) = f.apply(to: deltas)
        XCTAssertEqual(kept.map(\.className), ["ChildVM", "ClosureCycleViewController"])
        XCTAssertEqual(dropped, 3)
    }

    func testApplyToHeapEntriesDropsAndCounts() {
        let entries = [
            HeapClassEntry(className: "non-object", instanceCount: 100, totalBytes: 1024),
            HeapClassEntry(className: "ChildVM", instanceCount: 3, totalBytes: 96),
            HeapClassEntry(className: "CFRunLoop", instanceCount: 1, totalBytes: 256),
        ]
        let (kept, dropped) = f.apply(to: entries)
        XCTAssertEqual(kept.map(\.className), ["ChildVM"])
        XCTAssertEqual(dropped, 2)
    }
}
