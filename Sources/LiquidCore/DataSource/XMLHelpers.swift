//
//  XMLHelpers.swift
//  LiquidCore
//
//  Helper utilities for XML/HTML data source
//

import Foundation

/// Configuration for XML/HTML parsing behavior
public struct XMLParseOptions: Sendable {
    /// Whether to preserve namespaces
    public let preserveNamespaces: Bool

    /// Whether to preserve comments
    public let preserveComments: Bool

    /// Whether to preserve CDATA sections
    public let preserveCDATA: Bool

    /// Whether to simplify single-child arrays
    public let simplifyArrays: Bool

    /// Whether to convert attributes to @ prefix
    public let attributePrefix: String

    /// Whether to include text node prefix
    public let textNodeName: String

    /// Maximum depth to parse (prevents stack overflow)
    public let maxDepth: Int

    public init(
        preserveNamespaces: Bool = true,
        preserveComments: Bool = false,
        preserveCDATA: Bool = true,
        simplifyArrays: Bool = true,
        attributePrefix: String = "@",
        textNodeName: String = "#text",
        maxDepth: Int = 100
    ) {
        self.preserveNamespaces = preserveNamespaces
        self.preserveComments = preserveComments
        self.preserveCDATA = preserveCDATA
        self.simplifyArrays = simplifyArrays
        self.attributePrefix = attributePrefix
        self.textNodeName = textNodeName
        self.maxDepth = maxDepth
    }

    /// Default options for HTML parsing
    public static let html = XMLParseOptions(
        preserveNamespaces: false,
        preserveComments: false,
        simplifyArrays: true,
        attributePrefix: "@",
        textNodeName: "text"
    )

    /// Default options for XML parsing
    public static let xml = XMLParseOptions(
        preserveNamespaces: true,
        preserveComments: false,
        simplifyArrays: true,
        attributePrefix: "@",
        textNodeName: "#text"
    )
}

// MARK: - CSS Selector Support

/// Simple CSS selector parser for the active XML / HTML query surface.
public struct CSSSelector {
    public enum SelectorType {
        case element(String)
        case id(String)
        case className(String)
        case attribute(name: String, value: String?)
        case descendant
        case child
        case all
    }

    public let components: [SelectorType]

    private let pattern: SelectorPattern

    public init(selector: String) {
        let pattern = SelectorPattern(selector: selector)
        self.pattern = pattern
        self.components = pattern.legacyComponents
    }

    /// Match a single element against the first selector step.
    public func matches(_ value: DataValue, at index: Int = 0) -> Bool {
        guard index == 0, pattern.steps.count == 1 else {
            return false
        }

        return pattern.matchesStep(value, stepIndex: 0)
    }

    /// Select all matching elements in document order.
    public func selectAll(in value: DataValue) -> [DataValue] {
        pattern.selectAll(in: value)
    }
}

private struct SelectorPattern {
    fileprivate struct AttributeRequirement {
        let name: String
        let expectedValue: String?
    }

    fileprivate struct Step {
        let elementName: String?
        let id: String?
        let classes: [String]
        let attributes: [AttributeRequirement]
    }

    fileprivate enum Combinator {
        case descendant
        case child
    }

    let steps: [Step]
    let combinators: [Combinator]
    let legacyComponents: [CSSSelector.SelectorType]

    init(selector: String) {
        let parsed = Self.parse(selector: selector)
        self.steps = parsed.steps
        self.combinators = parsed.combinators
        self.legacyComponents = parsed.legacyComponents
    }

    func matchesStep(_ value: DataValue, stepIndex: Int) -> Bool {
        guard stepIndex >= 0, stepIndex < steps.count else {
            return false
        }

        return Self.matchesElement(value, against: steps[stepIndex])
    }

    func selectAll(in root: DataValue) -> [DataValue] {
        guard !steps.isEmpty else {
            return []
        }

        var current = allElementsAndDescendants(in: root).filter { Self.matchesElement($0, against: steps[0]) }

        guard steps.count > 1 else {
            return current
        }

        for index in 1..<steps.count {
            let combinator = combinators[index - 1]
            let step = steps[index]
            var next: [DataValue] = []

            for candidate in current {
                let matches: [DataValue]
                switch combinator {
                case .child:
                    matches = candidate.childElements.filter { Self.matchesElement($0, against: step) }
                case .descendant:
                    matches = descendantElements(in: candidate).filter { Self.matchesElement($0, against: step) }
                }

                for match in matches where !next.contains(match) {
                    next.append(match)
                }
            }

            current = next
        }

        return current
    }

    private static func parse(selector: String) -> (steps: [Step], combinators: [Combinator], legacyComponents: [CSSSelector.SelectorType]) {
        var tokens: [String] = []
        var combinators: [Combinator] = []
        var pendingCombinator: Combinator?
        var current = ""
        var bracketDepth = 0
        var quote: Character?

        func flushCurrent() {
            let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                current = ""
                return
            }

            if !tokens.isEmpty {
                combinators.append(pendingCombinator ?? .descendant)
            }

            tokens.append(trimmed)
            pendingCombinator = nil
            current = ""
        }

        for character in selector {
            if let activeQuote = quote {
                current.append(character)
                if character == activeQuote {
                    quote = nil
                }
                continue
            }

            switch character {
            case "\"", "'":
                quote = character
                current.append(character)

            case "[":
                bracketDepth += 1
                current.append(character)

            case "]":
                bracketDepth = max(0, bracketDepth - 1)
                current.append(character)

            case ">" where bracketDepth == 0:
                flushCurrent()
                pendingCombinator = .child

            default:
                if bracketDepth == 0, character.isWhitespace {
                    flushCurrent()
                    if !tokens.isEmpty {
                        pendingCombinator = pendingCombinator ?? .descendant
                    }
                } else {
                    current.append(character)
                }
            }
        }

        flushCurrent()

        let steps = tokens.map(Self.parseStep)
        let legacyComponents = Self.buildLegacyComponents(steps: steps, combinators: combinators)
        return (steps, combinators, legacyComponents)
    }

    private static func parseStep(_ token: String) -> Step {
        var elementName: String?
        var id: String?
        var classes: [String] = []
        var attributes: [AttributeRequirement] = []

        var index = token.startIndex

        func advanceIndex() {
            index = token.index(after: index)
        }

        func collectUntilSpecial() -> String {
            let start = index
            while index < token.endIndex {
                let character = token[index]
                if character == "." || character == "#" || character == "[" {
                    break
                }
                advanceIndex()
            }

            return String(token[start..<index])
        }

        func collectIdentifier() -> String {
            let start = index
            while index < token.endIndex {
                let character = token[index]
                if character == "." || character == "#" || character == "[" || character == "]" {
                    break
                }
                advanceIndex()
            }

            return String(token[start..<index])
        }

        while index < token.endIndex {
            switch token[index] {
            case ".":
                advanceIndex()
                let className = collectIdentifier()
                if !className.isEmpty {
                    classes.append(className)
                }

            case "#":
                advanceIndex()
                let identifier = collectIdentifier()
                if !identifier.isEmpty {
                    id = identifier
                }

            case "[":
                advanceIndex()
                let start = index
                var quote: Character?
                while index < token.endIndex {
                    let character = token[index]
                    if let activeQuote = quote {
                        if character == activeQuote {
                            quote = nil
                        }
                    } else if character == "\"" || character == "'" {
                        quote = character
                    } else if character == "]" {
                        break
                    }

                    advanceIndex()
                }

                let content = String(token[start..<index])
                if index < token.endIndex, token[index] == "]" {
                    advanceIndex()
                }

                let parts = content.split(separator: "=", maxSplits: 1).map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                if let name = parts.first, !name.isEmpty {
                    let expectedValue = parts.count == 2
                        ? parts[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                        : nil
                    attributes.append(AttributeRequirement(name: name, expectedValue: expectedValue))
                }

            default:
                let candidate = collectUntilSpecial()
                if candidate != "*", !candidate.isEmpty {
                    elementName = candidate
                }
            }
        }

        return Step(
            elementName: elementName,
            id: id,
            classes: classes,
            attributes: attributes
        )
    }

    private static func buildLegacyComponents(
        steps: [Step],
        combinators: [Combinator]
    ) -> [CSSSelector.SelectorType] {
        var components: [CSSSelector.SelectorType] = []

        for (index, step) in steps.enumerated() {
            if index > 0 {
                switch combinators[index - 1] {
                case .descendant:
                    components.append(.descendant)
                case .child:
                    components.append(.child)
                }
            }

            if let elementName = step.elementName {
                components.append(.element(elementName))
            } else if step.id == nil && step.classes.isEmpty && step.attributes.isEmpty {
                components.append(.all)
            }

            if let id = step.id {
                components.append(.id(id))
            }

            for className in step.classes {
                components.append(.className(className))
            }

            for attribute in step.attributes {
                components.append(.attribute(name: attribute.name, value: attribute.expectedValue))
            }
        }

        return components
    }

    private static func matchesElement(_ value: DataValue, against step: Step) -> Bool {
        guard case .object(let object) = value,
              let nameValue = object["@name"],
              case .string(let rawElementName) = nameValue else {
            return false
        }

        if let elementName = step.elementName,
           rawElementName.caseInsensitiveCompare(elementName) != .orderedSame {
            return false
        }

        if let expectedID = step.id {
            guard let idValue = value.attribute("id"),
                  idValue.stringValue == expectedID else {
                return false
            }
        }

        if !step.classes.isEmpty {
            guard let classValue = value.attribute("class")?.stringValue else {
                return false
            }

            let classSet = Set(classValue.split(whereSeparator: \.isWhitespace).map(String.init))
            for className in step.classes where !classSet.contains(className) {
                return false
            }
        }

        for attribute in step.attributes {
            guard let attributeValue = value.attribute(attribute.name) else {
                return false
            }

            if let expectedValue = attribute.expectedValue,
               attributeValue.stringValue != expectedValue {
                return false
            }
        }

        return true
    }

    private func allElementsAndDescendants(in value: DataValue) -> [DataValue] {
        var results: [DataValue] = []
        collectElementsAndDescendants(from: value, into: &results)
        return results
    }

    private func collectElementsAndDescendants(from value: DataValue, into results: inout [DataValue]) {
        switch value {
        case .object(let object):
            if object["@name"] != nil {
                results.append(value)
            }

            for child in value.childElements {
                collectElementsAndDescendants(from: child, into: &results)
            }

        case .array(let values):
            for item in values {
                collectElementsAndDescendants(from: item, into: &results)
            }

        default:
            break
        }
    }

    private func descendantElements(in value: DataValue) -> [DataValue] {
        var results: [DataValue] = []
        for child in value.childElements {
            collectElementsAndDescendants(from: child, into: &results)
        }
        return results
    }
}

// MARK: - XPath Support

/// XPath query support for the active XML / HTML query surface.
public struct XPathQuery {
    public let expression: String

    public init(_ expression: String) {
        self.expression = expression
    }

    /// Execute the supported XPath subset on a DataValue tree.
    public func execute(on value: DataValue) -> [DataValue] {
        guard let pattern = XPathPattern(expression: expression) else {
            return []
        }

        return pattern.execute(on: value)
    }
}

private struct XPathPattern {
    enum Axis {
        case absolute
        case descendant
    }

    enum ComparisonOperator {
        case equal
        case greaterThan
        case greaterThanOrEqual
        case lessThan
        case lessThanOrEqual
    }

    enum PredicateValue {
        case string(String)
        case number(Double)
    }

    enum Predicate {
        case attribute(name: String, operation: ComparisonOperator?, value: PredicateValue?)
        case child(name: String, operation: ComparisonOperator, value: PredicateValue)
        case position(PositionPredicate)
        case containsText(String)
    }

    enum PositionPredicate {
        case index(Int)
        case last
        case comparison(ComparisonOperator, Int)
    }

    struct Step {
        let name: String?
        let predicate: Predicate?
    }

    let axis: Axis
    let steps: [Step]
    let attributeSelection: String?

    init?(expression: String) {
        let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("//") {
            axis = .descendant
        } else if trimmed.hasPrefix("/") {
            axis = .absolute
        } else {
            return nil
        }

        let prefixLength = axis == .descendant ? 2 : 1
        let path = String(trimmed.dropFirst(prefixLength))
        var attributeSelection: String?

        if path.hasPrefix("@") {
            self.steps = []
            self.attributeSelection = String(path.dropFirst())
            return
        }

        let components = Self.splitPath(path)
        guard !components.isEmpty else {
            return nil
        }

        var mutableComponents = components
        if let last = mutableComponents.last, last.hasPrefix("@") {
            attributeSelection = String(last.dropFirst())
            mutableComponents.removeLast()
        }

        self.steps = mutableComponents.compactMap(Self.parseStep)
        self.attributeSelection = attributeSelection

        if self.steps.isEmpty && self.attributeSelection == nil {
            return nil
        }
    }

    func execute(on root: DataValue) -> [DataValue] {
        var current: [DataValue]

        if steps.isEmpty {
            switch axis {
            case .absolute:
                current = []
            case .descendant:
                current = allElementsAndDescendants(in: root)
            }
        } else {
            switch axis {
            case .absolute:
                let firstStep = steps[0]
                if matchesBasic(root, step: firstStep) {
                    current = applyPredicate(to: [root], predicate: firstStep.predicate)
                } else {
                    let rootChildren = root.childElements.filter { matchesBasic($0, step: firstStep) }
                    current = applyPredicate(to: rootChildren, predicate: firstStep.predicate)
                }
            case .descendant:
                let firstStep = steps[0]
                let candidates = allElementsAndDescendants(in: root).filter { matchesBasic($0, step: firstStep) }
                current = applyPredicate(to: candidates, predicate: firstStep.predicate)
            }

            for step in steps.dropFirst() {
                var next: [DataValue] = []
                for node in current {
                    let matches = node.childElements.filter { matchesBasic($0, step: step) }
                    next.append(contentsOf: applyPredicate(to: matches, predicate: step.predicate))
                }
                current = next
            }
        }

        if let attributeSelection {
            return current.compactMap { $0.attribute(attributeSelection) }
        }

        return current
    }

    private static func splitPath(_ path: String) -> [String] {
        var parts: [String] = []
        var current = ""
        var bracketDepth = 0
        var parenthesisDepth = 0
        var quote: Character?

        func flushCurrent() {
            let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                parts.append(trimmed)
            }
            current = ""
        }

        for character in path {
            if let activeQuote = quote {
                current.append(character)
                if character == activeQuote {
                    quote = nil
                }
                continue
            }

            switch character {
            case "\"", "'":
                quote = character
                current.append(character)

            case "[":
                bracketDepth += 1
                current.append(character)

            case "]":
                bracketDepth = max(0, bracketDepth - 1)
                current.append(character)

            case "(":
                parenthesisDepth += 1
                current.append(character)

            case ")":
                parenthesisDepth = max(0, parenthesisDepth - 1)
                current.append(character)

            case "/" where bracketDepth == 0 && parenthesisDepth == 0:
                flushCurrent()

            default:
                current.append(character)
            }
        }

        flushCurrent()
        return parts
    }

    private static func parseStep(_ token: String) -> Step? {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let name: String?
        let predicate: Predicate?

        if let bracketStart = trimmed.firstIndex(of: "["),
           trimmed.hasSuffix("]") {
            let namePart = String(trimmed[..<bracketStart]).trimmingCharacters(in: .whitespacesAndNewlines)
            name = namePart == "*" || namePart.isEmpty ? nil : namePart
            let predicateText = String(trimmed[trimmed.index(after: bracketStart)..<trimmed.index(before: trimmed.endIndex)])
            predicate = parsePredicate(predicateText)
        } else {
            name = trimmed == "*" ? nil : trimmed
            predicate = nil
        }

        return Step(name: name, predicate: predicate)
    }

    private static func parsePredicate(_ text: String) -> Predicate? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let exactIndex = Int(trimmed) {
            return .position(.index(max(0, exactIndex - 1)))
        }

        if trimmed == "last()" {
            return .position(.last)
        }

        if let match = trimmed.firstMatch(
            of: /^position\(\)\s*(<=|>=|=|<|>)\s*(\d+)$/
        ) {
            guard let position = Int(match.2) else {
                return nil
            }

            return .position(.comparison(parseOperator(String(match.1)), max(0, position - 1)))
        }

        if let match = trimmed.firstMatch(
            of: /^contains\(\s*text\(\)\s*,\s*['"](.*)['"]\s*\)$/
        ) {
            return .containsText(String(match.1))
        }

        if trimmed.hasPrefix("@") {
            return parseFieldPredicate(trimmed, attribute: true)
        }

        return parseFieldPredicate(trimmed, attribute: false)
    }

    private static func parseFieldPredicate(_ text: String, attribute: Bool) -> Predicate? {
        let normalized = attribute ? String(text.dropFirst()) : text

        if let match = normalized.firstMatch(
            of: /^([A-Za-z_][A-Za-z0-9_:\-]*)\s*(<=|>=|=|<|>)\s*(.+)$/
        ) {
            let field = String(match.1)
            let operation = parseOperator(String(match.2))
            guard let value = parsePredicateValue(String(match.3)) else {
                return nil
            }

            if attribute {
                return .attribute(name: field, operation: operation, value: value)
            }

            return .child(name: field, operation: operation, value: value)
        }

        if attribute {
            return .attribute(name: normalized, operation: nil, value: nil)
        }

        return nil
    }

    private static func parseOperator(_ raw: String) -> ComparisonOperator {
        switch raw {
        case ">":
            return .greaterThan
        case ">=":
            return .greaterThanOrEqual
        case "<":
            return .lessThan
        case "<=":
            return .lessThanOrEqual
        default:
            return .equal
        }
    }

    private static func parsePredicateValue(_ raw: String) -> PredicateValue? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("\"") || trimmed.hasPrefix("'") {
            return .string(trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\"'")))
        }

        if let number = Double(trimmed) {
            return .number(number)
        }

        return .string(trimmed)
    }

    private func matchesBasic(_ value: DataValue, step: Step) -> Bool {
        guard case .object(let object) = value,
              let nameValue = object["@name"],
              case .string(let elementName) = nameValue else {
            return false
        }

        guard let expectedName = step.name else {
            return true
        }

        return elementName.caseInsensitiveCompare(expectedName) == .orderedSame
    }

    private func applyPredicate(to matches: [DataValue], predicate: Predicate?) -> [DataValue] {
        guard let predicate else {
            return matches
        }

        switch predicate {
        case .position(let positionPredicate):
            return applyPositionPredicate(positionPredicate, to: matches)

        case .containsText(let expectedSubstring):
            return matches.filter { ($0.textContent ?? "").contains(expectedSubstring) }

        case .attribute(let name, let operation, let value):
            return matches.filter { element in
                guard let attribute = element.attribute(name) else {
                    return false
                }

                return compare(candidate: attribute, operation: operation, expected: value)
            }

        case .child(let name, let operation, let value):
            return matches.filter { element in
                let child = element[name]
                guard child != .null else {
                    return false
                }

                return compare(candidate: child, operation: operation, expected: value)
            }
        }
    }

    private func applyPositionPredicate(_ predicate: PositionPredicate, to matches: [DataValue]) -> [DataValue] {
        switch predicate {
        case .index(let index):
            guard matches.indices.contains(index) else {
                return []
            }
            return [matches[index]]

        case .last:
            guard let last = matches.last else {
                return []
            }
            return [last]

        case .comparison(let operation, let value):
            return matches.enumerated().compactMap { offset, element in
                comparePositions(position: offset, operation: operation, expected: value) ? element : nil
            }
        }
    }

    private func comparePositions(position: Int, operation: ComparisonOperator, expected: Int) -> Bool {
        switch operation {
        case .equal:
            return position == expected
        case .greaterThan:
            return position > expected
        case .greaterThanOrEqual:
            return position >= expected
        case .lessThan:
            return position < expected
        case .lessThanOrEqual:
            return position <= expected
        }
    }

    private func compare(
        candidate: DataValue,
        operation: ComparisonOperator?,
        expected: PredicateValue?
    ) -> Bool {
        guard let operation else {
            return true
        }
        guard let expected else {
            return false
        }

        switch expected {
        case .number(let numericExpected):
            guard let numericCandidate = candidate.doubleValue ?? candidate.textContent.flatMap(Double.init) else {
                return false
            }

            switch operation {
            case .equal:
                return numericCandidate == numericExpected
            case .greaterThan:
                return numericCandidate > numericExpected
            case .greaterThanOrEqual:
                return numericCandidate >= numericExpected
            case .lessThan:
                return numericCandidate < numericExpected
            case .lessThanOrEqual:
                return numericCandidate <= numericExpected
            }

        case .string(let stringExpected):
            let candidateString = candidate.textContent ?? candidate.stringValue

            switch operation {
            case .equal:
                return candidateString == stringExpected
            case .greaterThan:
                return candidateString > stringExpected
            case .greaterThanOrEqual:
                return candidateString >= stringExpected
            case .lessThan:
                return candidateString < stringExpected
            case .lessThanOrEqual:
                return candidateString <= stringExpected
            }
        }
    }

    private func allElementsAndDescendants(in value: DataValue) -> [DataValue] {
        var results: [DataValue] = []
        collectElementsAndDescendants(from: value, into: &results)
        return results
    }

    private func collectElementsAndDescendants(from value: DataValue, into results: inout [DataValue]) {
        switch value {
        case .object(let object):
            if object["@name"] != nil {
                results.append(value)
            }

            for child in value.childElements {
                collectElementsAndDescendants(from: child, into: &results)
            }

        case .array(let values):
            for item in values {
                collectElementsAndDescendants(from: item, into: &results)
            }

        default:
            break
        }
    }
}

// MARK: - DataValue Extensions for XML / HTML

extension DataValue {
    /// Get text content from an element
    public var textContent: String? {
        switch self {
        case .string(let str):
            return str

        case .object(let obj):
            if let text = obj["@text"] ?? obj["#text"] ?? obj["text"] {
                return text.stringValue
            }

            if let fullText = obj["@full_text"] {
                return fullText.stringValue
            }

            return nil

        default:
            return nil
        }
    }

    /// Get an attribute value using @ notation
    public func attribute(_ name: String) -> DataValue? {
        if case .object(let obj) = self,
           let attrs = obj["@attributes"],
           case .object(let attributes) = attrs {
            return attributes[name]
        }
        return nil
    }

    /// Get all child elements (excluding attributes and text)
    public var childElements: [DataValue] {
        guard case .object(let obj) = self else { return [] }

        var children: [DataValue] = []

        for (key, value) in obj {
            if !key.hasPrefix("@") && key != "#text" && key != "text" {
                switch value {
                case .array(let array):
                    children.append(contentsOf: array.map { Self.normalizedChildElement($0, named: key) })
                default:
                    children.append(Self.normalizedChildElement(value, named: key))
                }
            }
        }

        return children
    }

    /// Find elements by tag name
    public func getElementsByTagName(_ tagName: String) -> [DataValue] {
        var results: [DataValue] = []

        switch self {
        case .object(let obj):
            if let name = obj["@name"],
               case .string(let elementName) = name,
               elementName.lowercased() == tagName.lowercased() {
                results.append(self)
            }

            for (key, value) in obj where !key.hasPrefix("@") {
                results.append(contentsOf: value.getElementsByTagName(tagName))
            }

        case .array(let array):
            for item in array {
                results.append(contentsOf: item.getElementsByTagName(tagName))
            }

        default:
            break
        }

        return results
    }

    /// Return the first element matching a CSS selector.
    public func select(_ selector: String) -> DataValue {
        CSSSelector(selector: selector).selectAll(in: self).first ?? .null
    }

    /// Return all elements matching a CSS selector.
    public func selectAll(_ selector: String) -> DataValue {
        .array(CSSSelector(selector: selector).selectAll(in: self))
    }

    /// Execute the supported XPath subset on this value.
    public func xpath(_ query: String) -> DataValue {
        let results = XPathQuery(query).execute(on: self)
        if results.count == 1 {
            return results[0]
        }
        return .array(results)
    }

    private static func normalizedChildElement(_ value: DataValue, named name: String) -> DataValue {
        switch value {
        case .object(var object):
            if object["@name"] == nil {
                object["@name"] = .string(name)
            }
            return .object(object)

        case .array:
            return value

        default:
            return .object([
                "@name": .string(name),
                "@text": value
            ])
        }
    }
}
