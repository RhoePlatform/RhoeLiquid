//
//  IfchangedTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: ifchanged", .serialized)
struct GoldenIfchangedTests {

    @Test("tags, ifchanged, change from assign", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func changeFromAssign() async throws {
        let result = try await renderWithTimeout(template: "{% assign foo = 'hello' %}{% ifchanged %}{{ foo }}{% endifchanged %}{% ifchanged %}{{ foo }}{% endifchanged %}{% assign foo = 'goodbye' %}{% ifchanged %}{{ foo }}{% endifchanged %}", context: [:])
        #expect(result == "hellogoodbye")
    }

    @Test("tags, ifchanged, changed from initial state", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func changedFromInitialState() async throws {
        let result = try await renderWithTimeout(template: "{% ifchanged %}hello{% endifchanged %}", context: [:])
        #expect(result == "hello")
    }

    @Test("tags, ifchanged, no change from assign", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func noChangeFromAssign() async throws {
        let result = try await renderWithTimeout(template: "{% assign foo = 'hello' %}{% ifchanged %}{{ foo }}{% endifchanged %}{% ifchanged %}{{ foo }}{% endifchanged %}", context: [:])
        #expect(result == "hello")
    }

    @Test("tags, ifchanged, not changed from initial state", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func notChangedFromInitialState() async throws {
        let result = try await renderWithTimeout(template: "{% ifchanged %}{% endifchanged %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, ifchanged, within for loop", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func withinForLoop() async throws {
        let result = try await renderWithTimeout(template: "{% assign list = \"1,3,2,1,3,1,2\" | split: \",\" | sort %}{% for item in list -%}{%- ifchanged %} {{ item }}{% endifchanged -%}{%- endfor %}", context: [:])
        #expect(result == " 1 2 3")
    }
}
