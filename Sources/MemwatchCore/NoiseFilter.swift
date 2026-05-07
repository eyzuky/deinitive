import Foundation

// Curated list of class names that show up in every iOS heap diff but represent
// framework warmup, not user-code retention. Filtering these by default makes the
// signal-to-noise ratio of `memwatch diff` actually useful out of the box. Pass
// --all on the CLI (or `all: true` in MCP) to see the unfiltered set.
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
            // Obj-C runtime metadata.
            "non-object",
            "@autoreleasepool",
            "__NSMallocBlock__",
            "Class.methodCache._buckets",
            "Class.data",
            "(extension",

            // Auto Layout solver internals (per-pass allocations, not your constraints).
            "NSISRestrictedToZeroMarkerVariable",
            "NSISVariableObservation",
            "NSISUnrestrictedVariable",
            "NSISRestrictedToNonNegativeVariable",
            "NSLayoutXAxisAnchor",
            "NSLayoutYAxisAnchor",
            "NSLayoutDimension",

            // Core Text glyph and font caches.
            "_CTNativeGlyphStorage._advanceWidths",
            "_NSCoreTypesetterLayoutCache._advances",
            "TTenuousComponentFont",
            "TSplicedFont",
            "UICTFont",

            // UIKit color and trait pools.
            "UICachedDeviceRGBColor",
            "UICachedDeviceWhiteColor",
            "_UITraitOverrides",
            "UITraitCollection",

            // Core Animation render tree.
            "CA::Render::Vector",
            "CA::Render::KeyValue",
            "CABackingStore",

            // SVG / SF Symbols caches.
            "SVGAttribute",
            "SVGAttributeMap",
            "SVGPaint",
            "CUIDesignLibraryCatalog",
            "vImageConverterRef",

            // Run loop.
            "CFRunLoop",
        ],
        prefixes: [
            "Swift._SetStorage",
            "Swift._DictionaryStorage",
            "Swift._ContiguousArrayStorage",
            "UIKit._UIObjCEquatableBox",
            "Gestures.GestureNode",
        ]
    )
}
