import XCTest
@testable import MemwatchCore

final class NoiseFilterTests: XCTestCase {
    private let f = NoiseFilter.defaultFramework

    func testApplePrivatePrefixIsFiltered() {
        // Anything starting with `_` is Apple's private convention.
        XCTAssertTrue(f.isNoise("_UIFlexInteractionSpec"))
        XCTAssertTrue(f.isNoise("_CUIThemeSVGRendition"))
        XCTAssertTrue(f.isNoise("_NSAutoresizingMaskXAxisAnchor"))
        XCTAssertTrue(f.isNoise("__SwiftNativeNSError"))
        XCTAssertTrue(f.isNoise("_UIAppearanceCustomizableClassInfo"))
    }

    func testRuntimeAndAnimationPrefixesFiltered() {
        XCTAssertTrue(f.isNoise("Class.data.methods"))
        XCTAssertTrue(f.isNoise("Class.methodCache._buckets"))
        XCTAssertTrue(f.isNoise("CA::Render::Vector"))
        XCTAssertTrue(f.isNoise("CALayerArray"))
        XCTAssertTrue(f.isNoise("CAContext._impl"))
        XCTAssertTrue(f.isNoise("@autoreleasepool"))
    }

    func testDispatchAndXPCFiltered() {
        XCTAssertTrue(f.isNoise("dispatch_queue_t"))
        XCTAssertTrue(f.isNoise("dispatch_source_t"))
        XCTAssertTrue(f.isNoise("xpc_connection_t"))
        XCTAssertTrue(f.isNoise("OS_dispatch_queue_runloop"))
        XCTAssertTrue(f.isNoise("OS_os_log"))
    }

    func testCoreGraphicsAndTextFiltered() {
        XCTAssertTrue(f.isNoise("CGColor"))
        XCTAssertTrue(f.isNoise("CGPath"))
        XCTAssertTrue(f.isNoise("CGImage"))
        XCTAssertTrue(f.isNoise("CGFont"))
        XCTAssertTrue(f.isNoise("CGDataProvider"))
        XCTAssertTrue(f.isNoise("ColorSyncProfile"))
        XCTAssertTrue(f.isNoise("ColorSyncTRC"))
        XCTAssertTrue(f.isNoise("TTrueTypeScaler"))
        XCTAssertTrue(f.isNoise("TFPFont"))
    }

    func testCoreUIAndSVGFiltered() {
        XCTAssertTrue(f.isNoise("CUIRenditionKey"))
        XCTAssertTrue(f.isNoise("CUINamedVectorGlyph"))
        XCTAssertTrue(f.isNoise("CUICommonAssetStorage"))
        XCTAssertTrue(f.isNoise("SVGShapeNode"))
        XCTAssertTrue(f.isNoise("SVGRootNode"))
        XCTAssertTrue(f.isNoise("SVGPathCommand"))
    }

    func testBackBoardServicesFiltered() {
        XCTAssertTrue(f.isNoise("BSProtobufSchema"))
        XCTAssertTrue(f.isNoise("BSMutableIntegerMap"))
        XCTAssertTrue(f.isNoise("BKSHIDEventKeyCommand"))
        XCTAssertTrue(f.isNoise("BLSBacklightSceneSettingsDiffInspector"))
    }

    func testUIKitPrivateCachesFiltered() {
        XCTAssertTrue(f.isNoise("UICachedDeviceRGBColor"))
        XCTAssertTrue(f.isNoise("UICTFontDescriptor"))
        XCTAssertTrue(f.isNoise("UIDynamicSystemColor"))
        XCTAssertTrue(f.isNoise("UIDeferredMenuElement"))
        XCTAssertTrue(f.isNoise("UIPeripheralHost"))
        XCTAssertTrue(f.isNoise("UIViewSpringAnimationBehaviorSettings"))
    }

    func testAutoLayoutSolverFiltered() {
        XCTAssertTrue(f.isNoise("NSISVariableObservation"))
        XCTAssertTrue(f.isNoise("NSISRestrictedToZeroMarkerVariable"))
        XCTAssertTrue(f.isNoise("NSAutoresizingMaskLayoutConstraint"))
        XCTAssertTrue(f.isNoise("NSLayoutXAxisAnchor"))
        XCTAssertTrue(f.isNoise("NSLayoutYAxisAnchor"))
    }

    func testFoundationInternalsFiltered() {
        XCTAssertTrue(f.isNoise("NSConcreteData"))
        XCTAssertTrue(f.isNoise("NSConcreteValue"))
        XCTAssertTrue(f.isNoise("NSCountedSet"))
        XCTAssertTrue(f.isNoise("NSHashTable"))
        XCTAssertTrue(f.isNoise("NSPathStore2"))
        XCTAssertTrue(f.isNoise("NSPointerArray"))
        XCTAssertTrue(f.isNoise("NSKeyValueMethodGetter"))
        XCTAssertTrue(f.isNoise("NSMutableDictionary.cow"))
        XCTAssertTrue(f.isNoise("NSCache._cache"))
        XCTAssertTrue(f.isNoise("NSMapTable"))
    }

    func testSwiftRuntimeFiltered() {
        XCTAssertTrue(f.isNoise("Swift._SetStorage<Swift.Int>"))
        XCTAssertTrue(f.isNoise("Swift._DictionaryStorage<Swift.ObjectIdentifier,Swift.Int>"))
        XCTAssertTrue(f.isNoise("Swift._ContiguousArrayStorage<Foo>"))
        XCTAssertTrue(f.isNoise("Swift.KeyPath<Foo, Bar>"))
        XCTAssertTrue(f.isNoise("Swift.ReferenceWritableKeyPath<UIKit.NavigationBarLayout, Foo>"))
        XCTAssertTrue(f.isNoise("Swift.ManagedBuffer<UIKit.InProcessAnimationManager.ConfigurationState, Int>"))
        XCTAssertTrue(f.isNoise("Swift.StringStorage"))
    }

    func testObservationFrameworkFiltered() {
        XCTAssertTrue(f.isNoise("Observation._ManagedCriticalState<Observation.ObservationTracking.State>"))
        XCTAssertTrue(f.isNoise("ObservationRegistrar.Extent"))
    }

    func testIOSurfaceAndPTFiltered() {
        XCTAssertTrue(f.isNoise("IOSurface"))
        XCTAssertTrue(f.isNoise("IOSurface._impl"))
        XCTAssertTrue(f.isNoise("PTSettingsClassStructure"))
        XCTAssertTrue(f.isNoise("PTFrameRateRangeSettings"))
    }

    func testGenericFoundationClassesAreNotFiltered() {
        // These are widely allocated by both framework and user code; we don't filter them
        // because doing so would silently hide real leaks.
        XCTAssertFalse(f.isNoise("CFString"))
        XCTAssertFalse(f.isNoise("CFData"))
        XCTAssertFalse(f.isNoise("CFDictionary"))
        XCTAssertFalse(f.isNoise("NSDictionary"))
        XCTAssertFalse(f.isNoise("NSMutableArray"))
        XCTAssertFalse(f.isNoise("NSMutableDictionary"))
        XCTAssertFalse(f.isNoise("NSNumber"))
        XCTAssertFalse(f.isNoise("NSURL"))
        XCTAssertFalse(f.isNoise("NSData"))
        XCTAssertFalse(f.isNoise("NSArray"))
        XCTAssertFalse(f.isNoise("NSCache"))
        XCTAssertFalse(f.isNoise("NSLock"))
        XCTAssertFalse(f.isNoise("NSTimer"))
        XCTAssertFalse(f.isNoise("UIView"))
        XCTAssertFalse(f.isNoise("UIImage"))
        XCTAssertFalse(f.isNoise("UIBarButtonItem"))
        XCTAssertFalse(f.isNoise("Closure"))
        XCTAssertFalse(f.isNoise("NSLayoutConstraint"))
    }

    // CALayer is filtered (UIKit creates one per view internally; rarely a real signal),
    // but the more interesting fact is that UIView remains visible — that's the user's signal.
    func testCALayerIsFilteredButUIViewIsNot() {
        XCTAssertTrue(f.isNoise("CALayer"))
        XCTAssertFalse(f.isNoise("UIView"))
    }

    func testUserClassesArePreserved() {
        XCTAssertFalse(f.isNoise("ChildVM"))
        XCTAssertFalse(f.isNoise("ClosureCycleViewController"))
        XCTAssertFalse(f.isNoise("LeakLab.Subscriber"))
        XCTAssertFalse(f.isNoise("Subject"))
        XCTAssertFalse(f.isNoise("Workload"))
        XCTAssertFalse(f.isNoise("TimerWorker"))
        XCTAssertFalse(f.isNoise("LiveCounter"))
    }

    func testApplyToDeltasDropsAndCounts() {
        let deltas = [
            ClassDelta(className: "non-object", countDelta: 100, bytesDelta: 1024),
            ClassDelta(className: "ChildVM", countDelta: 3, bytesDelta: 96),
            ClassDelta(className: "_UIFlexInteractionSpec", countDelta: 5, bytesDelta: 500),
            ClassDelta(className: "ClosureCycleViewController", countDelta: 1, bytesDelta: 800),
            ClassDelta(className: "Swift._SetStorage<Swift.Int>", countDelta: 8, bytesDelta: 2000),
            ClassDelta(className: "CFString", countDelta: 100, bytesDelta: 5000),
        ]
        let (kept, dropped) = f.apply(to: deltas)
        // Kept: ChildVM, ClosureCycleViewController, CFString. Filtered: non-object, _UIFlexInteractionSpec, Swift._SetStorage.
        XCTAssertEqual(kept.map(\.className).sorted(), ["CFString", "ChildVM", "ClosureCycleViewController"])
        XCTAssertEqual(dropped, 3)
    }

    func testApplyToHeapEntriesDropsAndCounts() {
        let entries = [
            HeapClassEntry(className: "non-object", instanceCount: 100, totalBytes: 1024),
            HeapClassEntry(className: "ChildVM", instanceCount: 3, totalBytes: 96),
            HeapClassEntry(className: "CFRunLoop", instanceCount: 1, totalBytes: 256),
            HeapClassEntry(className: "_UIFontSystemCacheKey", instanceCount: 4, totalBytes: 256),
        ]
        let (kept, dropped) = f.apply(to: entries)
        XCTAssertEqual(kept.map(\.className), ["ChildVM"])
        XCTAssertEqual(dropped, 3)
    }
}
