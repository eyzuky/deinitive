import Foundation

// Heuristic that decides whether a class name "looks like" user-defined code vs.
// a framework class. Used to surface a small "Probably your code" section above
// the full diff so leaked app-defined classes (view controllers, view models,
// sentinels) don't get lost in the framework long tail.
//
// Strategy: a class is "framework" if its name starts with any well-known Apple
// framework prefix (NS, UI, CA, CG, CT, CF, CU, OS_, dispatch_, xpc_, BS, BKS,
// BLS, IO, SVG, ColorSync, Swift., Observation., ...) or matches a small set of
// Swift built-in names (Closure, Array, Dictionary, ...). Anything else is
// "probably user code." Heuristic — false positives possible if the user uses
// these prefixes themselves.
public enum UserCodeHeuristic {
    private static let frameworkPrefixes: [String] = [
        // Foundation / Cocoa
        "NS", "CF", "CG", "CA", "CT", "CU", "CUI",
        // UIKit (catches UIView, UIKit.UIAnimatableProperty<...>, etc.)
        "UI",
        // Swift runtime / std
        "Swift.", "Observation.", "ObservationRegistrar",
        // Apple internal / private convention
        "_", "@", "Class.", "(",
        // Concurrency / OS internals
        "OS_", "dispatch_", "xpc_",
        // BackBoard / Backlight private system frameworks
        "BS", "BKS", "BL", "BLS",
        // Core Graphics-adjacent
        "IO", "ColorSync",
        // SVG / SF Symbols
        "SVG",
        // Core Text font internals
        "TFP", "TFile", "TGlyph", "TTrueType", "THVAR",
        // Misc framework
        "PT", "Gestures.", "GlassMaterial",
    ]

    private static let swiftBuiltins: Set<String> = [
        "Closure", "Array", "Dictionary", "Set", "String", "Int", "UInt",
        "Double", "Float", "Bool", "Optional", "Result", "Range", "Slice",
        "ContiguousArray", "Data", "Date", "URL"
    ]

    public static func isLikelyUserCode(_ className: String) -> Bool {
        if swiftBuiltins.contains(className) { return false }
        for prefix in frameworkPrefixes where className.hasPrefix(prefix) { return false }
        guard let first = className.first, first.isLetter else { return false }
        return true
    }
}
