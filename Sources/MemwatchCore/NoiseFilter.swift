import Foundation

// Curated list of class names that show up in every iOS heap diff but represent
// framework warmup, not user-code retention. Filtering these by default makes the
// signal-to-noise ratio of `memwatch diff` actually useful out of the box. Pass
// --all on the CLI (or all=true via MCP) to see the unfiltered set.
public struct NoiseFilter: Sendable {
    public let exactNames: Set<String>
    public let prefixes: [String]

    public init(exactNames: Set<String>, prefixes: [String]) {
        self.exactNames = exactNames
        self.prefixes = prefixes
    }

    public func isNoise(_ className: String) -> Bool {
        if exactNames.contains(className) { return true }
        for prefix in prefixes where className.hasPrefix(prefix) { return true }
        return false
    }

    public func apply(to deltas: [ClassDelta]) -> (kept: [ClassDelta], droppedCount: Int) {
        var kept: [ClassDelta] = []
        var dropped = 0
        for delta in deltas {
            if isNoise(delta.className) { dropped += 1 } else { kept.append(delta) }
        }
        return (kept, dropped)
    }

    public func apply(to entries: [HeapClassEntry]) -> (kept: [HeapClassEntry], droppedCount: Int) {
        var kept: [HeapClassEntry] = []
        var dropped = 0
        for entry in entries {
            if isNoise(entry.className) { dropped += 1 } else { kept.append(entry) }
        }
        return (kept, dropped)
    }
}

public extension NoiseFilter {
    static let defaultFramework = NoiseFilter(
        exactNames: [
            "non-object",
            "@autoreleasepool",
            "__NSMallocBlock__",
            "(extension",
            "cacheStrike",
            "InProcessAnimationManager",
            "TrackingDictionary",
        ],
        prefixes: [
            // Apple convention: anything starting with underscore is private.
            "_",

            // Obj-C runtime metadata
            "Class.",
            "@",

            // Core Animation render tree
            "CA::",
            "CALayer",
            "CAContext",
            "CAHosting",
            "CAMediaTimingFunction",

            // libdispatch / OS / XPC
            "OS_",
            "dispatch_",
            "xpc_",

            // Core Foundation internals (NOT CFString/CFData/CFDictionary/CFArray — those
            // can be user code via toll-free bridging)
            "CFRunLoop",
            "CFAllocator",
            "CFBag",

            // Core Graphics — almost always framework
            "CG",

            // Core Text glyph and font caches
            "CT",
            "TFP",
            "TFile",
            "TGlyph",
            "TTrueType",
            "THVAR",

            // Color management
            "ColorSync",

            // Core UI / asset catalog
            "CUI",

            // SVG / SF Symbols caches
            "SVG",

            // BackBoard / Backlight services (private system frameworks)
            "BS",
            "BKS",
            "BLS",

            // IOKit
            "IOSurface",

            // PT private settings
            "PT",

            // UIKit private cache/state classes (the ones that aren't already
            // caught by the `_` prefix)
            "UICachedDevice",
            "UICGColor",
            "UICTFont",
            "UIDynamic",
            "UIVibrancy",
            "UIVibrant",
            "UITint",
            "UIUpdateActionPhase",
            "UIAnimator",
            "UIPeripheralHost",
            "UIDeferredMenu",
            "UIBarButtonItemData",
            "UIImageAsset",
            "UIImageConfiguration",
            "UIImageSymbolConfiguration",
            "UITouchesEvent",
            "UITouchData",
            "UIViewSpringAnimation",
            "UITraitCollection",

            // Auto Layout solver internals
            "NSIS",
            "NSAutoresizingMaskLayoutConstraint",
            "NSLayoutXAxisAnchor",
            "NSLayoutYAxisAnchor",
            "NSLayoutDimension",

            // Foundation private internals (NOT NSDictionary/NSArray/NSSet/NSString/etc.)
            "NSCache.",
            "NSConcreteData",
            "NSConcreteValue",
            "NSCountedSet",
            "NSHashTable",
            "NSCFTimer",
            "NSPointerArray",
            "NSPathStore",
            "NSKeyValueMethod",
            "NSKeyValueObservation",
            "NSKeyValueObservance",
            "NSKeyValueUnnestedProperty",
            "NSMutableDictionary.cow",
            "NSSet.cow",
            "NSArray._list",
            "NSTempAttributeDictionary",
            "NSRunLoop",
            "NSThread",
            "NSMapTable",

            // Swift runtime internals
            "Swift._SetStorage",
            "Swift._DictionaryStorage",
            "Swift._ContiguousArrayStorage",
            "Swift.KeyPath",
            "Swift.ReferenceWritableKeyPath",
            "Swift.ManagedBuffer",
            "Swift.StringStorage",

            // Swift Observation framework
            "Observation.",
            "ObservationRegistrar",

            // UIKit framework wrappers
            "UIKit._UIObjCEquatableBox",

            // Misc
            "Gestures.",
            "GlassMaterialProvider",
        ]
    )
}
