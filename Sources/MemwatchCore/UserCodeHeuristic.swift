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
        // SwiftUI / Swift runtime / std
        "SwiftUI", "Swift.", "Observation.", "ObservationRegistrar",
        // C++ standard library
        "std::",
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
        // Core Text font internals (T<uppercase> family)
        "TFP", "TFile", "TGlyph", "TTrueType", "THVAR", "TTenuous", "TSpliced", "TChar",
        // MaterialKit / VisualStyling private UIKit
        "MT",
        // Accelerate / vImage
        "vImage",
        // Misc framework
        "PT", "Gestures.", "GlassMaterial",
        // iOS 26+ UIKit internals that don't use the legacy `UI` prefix
        "NavigationBar", "NavigationStack", "ButtonBar", "GlassGroup",
        "PlatterContainer", "SDFElement", "DesignLibrary",
    ]

    private static let swiftBuiltins: Set<String> = [
        // Swift std types that surface as bare names in heap output
        "Closure", "Array", "Dictionary", "Set", "String", "Int", "UInt",
        "Double", "Float", "Bool", "Optional", "Result", "Range", "Slice",
        "ContiguousArray", "Data", "Date", "URL",
        // Bare framework type names that show up in heap output
        "Class", "Swift", "BridgedProperty", "Implementation",
    ]

    public static func isLikelyUserCode(_ className: String) -> Bool {
        if swiftBuiltins.contains(className) { return false }
        for prefix in frameworkPrefixes where className.hasPrefix(prefix) { return false }
        guard let first = className.first, first.isLetter else { return false }
        return true
    }
}
