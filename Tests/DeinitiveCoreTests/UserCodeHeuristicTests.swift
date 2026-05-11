import XCTest
@testable import DeinitiveCore

final class UserCodeHeuristicTests: XCTestCase {

    func testLeakLabClassesAreUserCode() {
        XCTAssertTrue(UserCodeHeuristic.isLikelyUserCode("ChildVM"))
        XCTAssertTrue(UserCodeHeuristic.isLikelyUserCode("ClosureCycleViewController"))
        XCTAssertTrue(UserCodeHeuristic.isLikelyUserCode("NotificationLeakViewController"))
        XCTAssertTrue(UserCodeHeuristic.isLikelyUserCode("TimerLeakViewController"))
        XCTAssertTrue(UserCodeHeuristic.isLikelyUserCode("Workload"))
        XCTAssertTrue(UserCodeHeuristic.isLikelyUserCode("TimerWorker"))
        XCTAssertTrue(UserCodeHeuristic.isLikelyUserCode("Subscriber"))
        XCTAssertTrue(UserCodeHeuristic.isLikelyUserCode("Subject"))
        XCTAssertTrue(UserCodeHeuristic.isLikelyUserCode("LeakyManager"))
        XCTAssertTrue(UserCodeHeuristic.isLikelyUserCode("LiveCounter"))
    }

    func testFoundationAndUIKitAreFramework() {
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("NSString"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("NSDictionary"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("NSConcreteMutableData"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("NSMutableSet"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("UIView"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("UILabel"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("UIStackView"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("UIMenu"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("UICommand"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("UIKeyCommand"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("CFString"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("CFData"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("CGPath"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("CALayer"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("CABackingStore"))
    }

    func testApplePrivatesAreFramework() {
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("_UIFlexInteractionSpec"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("__SwiftNativeNSError"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("_NSAutoresizingMaskXAxisAnchor"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("Class.methodCache._buckets"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("@autoreleasepool"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("(extension"))
    }

    func testSwiftBuiltinsAreNotUserCode() {
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("Closure"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("Array"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("Dictionary"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("String"))
    }

    func testSwiftRuntimeAndObservationAreFramework() {
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("Swift._SetStorage<Swift.Int>"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("Swift.KeyPath<Foo, Bar>"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("Observation._ManagedCriticalState<Foo>"))
        XCTAssertFalse(UserCodeHeuristic.isLikelyUserCode("ObservationRegistrar.Extent"))
    }

    func testFormatUserCodeSectionPullsOnlyUserClasses() {
        let deltas = [
            ClassDelta(className: "CFString", countDelta: 300, bytesDelta: 15000),
            ClassDelta(className: "NotificationLeakViewController", countDelta: 1, bytesDelta: 1024),
            ClassDelta(className: "Workload", countDelta: 3, bytesDelta: 96),
            ClassDelta(className: "UIView", countDelta: 2, bytesDelta: 832),
            ClassDelta(className: "Closure", countDelta: 36, bytesDelta: 1100),
        ]
        let section = DiffFormatter.formatUserCodeSection(deltas)
        XCTAssertNotNil(section)
        XCTAssertTrue(section!.contains("NotificationLeakViewController"))
        XCTAssertTrue(section!.contains("Workload"))
        // Should NOT include framework or ambiguous-builtin classes.
        XCTAssertFalse(section!.contains("CFString"))
        XCTAssertFalse(section!.contains("UIView"))
        XCTAssertFalse(section!.contains("Closure"))
    }

    func testFormatUserCodeSectionReturnsNilWhenNoUserClasses() {
        let deltas = [
            ClassDelta(className: "CFString", countDelta: 300, bytesDelta: 15000),
            ClassDelta(className: "UIView", countDelta: 2, bytesDelta: 832),
            ClassDelta(className: "Closure", countDelta: 36, bytesDelta: 1100),
        ]
        XCTAssertNil(DiffFormatter.formatUserCodeSection(deltas))
    }
}
