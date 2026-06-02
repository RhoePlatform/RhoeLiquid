//
//  CustomTagDescriptor.swift
//  LiquidParser
//

import Foundation

/// Lightweight parser metadata for runtime custom tags.
///
/// The parser only needs enough information to recognize the tag name and
/// whether it owns a closing `end...` tag. Tag validation and execution stay
/// in the `LiquidTags` module.
public struct CustomTagDescriptor: Sendable, Hashable {
    /// The registered tag name, for example `highlight` or `data`.
    public let name: String

    /// Whether the tag requires a matching closing tag like `{% endhighlight %}`.
    public let requiresEndTag: Bool

    public init(name: String, requiresEndTag: Bool) {
        self.name = name
        self.requiresEndTag = requiresEndTag
    }

    /// The closing tag name used for block-style custom tags.
    public var endTagName: String {
        "end\(name)"
    }
}
