//
//  IfTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: if", .serialized)
struct GoldenIfTests {

    @Test("tags, if, 0.0 is truthy", .timeLimit(.minutes(1)))
    func test00istruthy() async throws {
        let result = try await renderWithTimeout(template: "{% if 0.0 %}Hello{% else %}Goodbye{% endif %}", context: [:])
        #expect(result == "Hello")
    }

    @Test("tags, if, alternate not equal condition", .timeLimit(.minutes(1)))
    func alternateNotEqualCondition() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if product.title <> 'foo' %}baz{% endif %}", context: ctx)
        #expect(result == "")
    }

    @Test("tags, if, array contains false", .timeLimit(.minutes(1)))
    func arrayContainsFalse() async throws {
        let ctx: [String: Any] = [
            "a": [1, 2, 3, false] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if a contains false %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "FALSE")
    }

    @Test("tags, if, array contains nil", .timeLimit(.minutes(1)))
    func arrayContainsNil() async throws {
        let ctx: [String: Any] = [
            "a": [1, 2, NSNull()] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if a contains nil %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "FALSE")
    }

    @Test("tags, if, array contains undefined", .timeLimit(.minutes(1)))
    func arrayContainsUndefined() async throws {
        let ctx: [String: Any] = [
            "a": [1, 2, 3, NSNull()] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if a contains nosuchthing %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "FALSE")
    }

    @Test("tags, if, array is equal to array", .timeLimit(.minutes(1)))
    func arrayIsEqualToArray() async throws {
        let result = try await renderWithTimeout(template: "{% assign x = 'a,b,c' | split: ',' %}{% assign y = 'a,b,c' | split: ',' %}{% if x == y %}true{% else %}false{% endif %}", context: [:])
        #expect(result == "true")
    }

    @Test("tags, if, array is equal to array from context", .timeLimit(.minutes(1)))
    func arrayIsEqualToArrayFromContext() async throws {
        let ctx: [String: Any] = [
            "x": ["a", "b", "c"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign y = 'a,b,c' | split: ',' %}{% if x == y %}true{% else %}false{% endif %}", context: ctx)
        #expect(result == "true")
    }

    @Test("tags, if, blocks that contain only whitespace and comments are not rendered", .timeLimit(.minutes(1)))
    func blocksThatContainOnlyWhitespaceAndCommentsAreNotRendered() async throws {
        let result = try await renderWithTimeout(template: "{% if true %} {% comment %} this is blank {% endcomment %} {% endif %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, if, blocks that contain only whitespace are not rendered", .timeLimit(.minutes(1)))
    func blocksThatContainOnlyWhitespaceAreNotRendered() async throws {
        let result = try await renderWithTimeout(template: "{% if true %}  {% elsif false %} {% else %} {% endif %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, if, condition with conditional alternative", .timeLimit(.minutes(1)))
    func conditionWithConditionalAlternative() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if product.title == 'hello' %}foo{% elsif product.title == 'foo' %}bar{% endif %}", context: ctx)
        #expect(result == "bar")
    }

    @Test("tags, if, condition with conditional alternative and final alternative", .timeLimit(.minutes(1)))
    func conditionWithConditionalAlternativeAndFinalAlternative() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if product.title == 'hello' %}foo{% elsif product.title == 'goodbye' %}bar{% else %}baz{% endif %}", context: ctx)
        #expect(result == "baz")
    }

    @Test("tags, if, condition with literal consequence", .timeLimit(.minutes(1)))
    func conditionWithLiteralConsequence() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if product.title == 'foo' %}bar{% endif %}", context: ctx)
        #expect(result == "bar")
    }

    @Test("tags, if, condition with literal consequence and literal alternative", .timeLimit(.minutes(1)))
    func conditionWithLiteralConsequenceAndLiteralAlternative() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if product.title == 'hello' %}bar{% else %}baz{% endif %}", context: ctx)
        #expect(result == "baz")
    }

    @Test("tags, if, conditional alternative with default", .timeLimit(.minutes(1)))
    func conditionalAlternativeWithDefault() async throws {
        let result = try await renderWithTimeout(template: "{% if false %}foo{% elsif false %}bar{% else %}hello{% endif %}", context: [:])
        #expect(result == "hello")
    }

    @Test("tags, if, contains condition", .timeLimit(.minutes(1)))
    func containsCondition() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if product.tags contains 'garden' %}baz{% endif %}", context: ctx)
        #expect(result == "baz")
    }

    @Test("tags, if, context string contains string from context", .timeLimit(.minutes(1)))
    func contextStringContainsStringFromContext() async throws {
        let ctx: [String: Any] = [
            "s": "llo",
            "t": "hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if t contains s %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "TRUE")
    }

    @Test("tags, if, else tag expressions are ignored", .timeLimit(.minutes(1)))
    func elseTagExpressionsAreIgnored() async throws {
        let result = try await renderWithTimeout(template: "{% if false %}1{% else nonsense %}2{% endif %}", context: [:])
        #expect(result == "2")
    }

    @Test("tags, if, empty array equals special empty", .timeLimit(.minutes(1)))
    func emptyArrayEqualsSpecialEmpty() async throws {
        let ctx: [String: Any] = [
            "x": [Any]()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if x == empty %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "TRUE")
    }

    @Test("tags, if, empty array is truthy", .timeLimit(.minutes(1)))
    func emptyArrayIsTruthy() async throws {
        let ctx: [String: Any] = [
            "x": [Any]()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if x %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "TRUE")
    }

    @Test("tags, if, empty object equals special empty", .timeLimit(.minutes(1)))
    func emptyObjectEqualsSpecialEmpty() async throws {
        let ctx: [String: Any] = [
            "x": OrderedDictionary<String, Any>()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if x == empty %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "TRUE")
    }

    @Test("tags, if, empty object is truthy", .timeLimit(.minutes(1)))
    func emptyObjectIsTruthy() async throws {
        let ctx: [String: Any] = [
            "x": OrderedDictionary<String, Any>()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if x %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "TRUE")
    }

    @Test("tags, if, empty string is truthy", .timeLimit(.minutes(1)))
    func emptyStringIsTruthy() async throws {
        let result = try await renderWithTimeout(template: "{% if '' %}TRUE{% else %}FALSE{% endif %}", context: [:])
        #expect(result == "TRUE")
    }

    @Test("tags, if, endswith is not a valid operator", .timeLimit(.minutes(1)))
    func endswithIsNotAValidOperator() async throws {
        let ctx: [String: Any] = [
            "s": "hello",
            "t": "lo"
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{% if s endswith t %}TRUE{% else %}FALSE{% endif %}", context: ctx)
            Issue.record("Expected error for \"tags, if, endswith is not a valid operator\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, if, extra else blocks are ignored", .timeLimit(.minutes(1)))
    func extraElseBlocksAreIgnored() async throws {
        let result = try await renderWithTimeout(template: "{% if false %}1{% else %}2{% else %}3{% endif %}", context: [:])
        #expect(result == "2")
    }

    @Test("tags, if, extra elsif blocks are ignored", .timeLimit(.minutes(1)))
    func extraElsifBlocksAreIgnored() async throws {
        let result = try await renderWithTimeout(template: "{% if false %}1{% else %}2{% elsif true %}3{% endif %}", context: [:])
        #expect(result == "2")
    }

    @Test("tags, if, haskey is not a valid operator", .timeLimit(.minutes(1)))
    func haskeyIsNotAValidOperator() async throws {
        let ctx: [String: Any] = [
            "obj": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("foo", "bar" as Any)
            ]),
            "x": "foo"
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{% if obj haskey x %}TRUE{% else %}FALSE{% endif %}", context: ctx)
            Issue.record("Expected error for \"tags, if, haskey is not a valid operator\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, if, in is not a valid operator", .timeLimit(.minutes(1)))
    func inIsNotAValidOperator() async throws {
        let ctx: [String: Any] = [
            "s": "hello",
            "t": "lo"
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{% if t in s %}TRUE{% else %}FALSE{% endif %}", context: ctx)
            Issue.record("Expected error for \"tags, if, in is not a valid operator\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, if, int does not equal string", .timeLimit(.minutes(1)))
    func intDoesNotEqualString() async throws {
        let result = try await renderWithTimeout(template: "{% if 1 == '1' %}true{% else %}false{% endif %}", context: [:])
        #expect(result == "false")
    }

    @Test("tags, if, int equals float", .timeLimit(.minutes(1)))
    func intEqualsFloat() async throws {
        let result = try await renderWithTimeout(template: "{% if 1 == 1.0 %}true{% else %}false{% endif %}", context: [:])
        #expect(result == "true")
    }

    @Test("tags, if, literal false condition", .timeLimit(.minutes(1)))
    func literalFalseCondition() async throws {
        let result = try await renderWithTimeout(template: "{% if false %}{% endif %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, if, literal nil is falsy", .timeLimit(.minutes(1)))
    func literalNilIsFalsy() async throws {
        let result = try await renderWithTimeout(template: "{% if nil %}bar{% else %}foo{% endif %}", context: [:])
        #expect(result == "foo")
    }

    @Test("tags, if, logical operators are right associative", .timeLimit(.minutes(1)))
    func logicalOperatorsAreRightAssociative() async throws {
        let result = try await renderWithTimeout(template: "{% if true and false and false or true %}hello{% endif %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, if, nested condition in the consequence block", .timeLimit(.minutes(1)))
    func nestedConditionInTheConsequenceBlock() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ]),
            "title": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if product %}{% if title == 'Hello' %}baz{% endif %}{% endif %}", context: ctx)
        #expect(result == "baz")
    }

    @Test("tags, if, nested condition, alternative in the consequence block", .timeLimit(.minutes(1)))
    func nestedConditionAlternativeInTheConsequenceBlock() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ]),
            "title": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if product %}{% if title == 'goodbye' %}baz{% else %}hello{% endif %}{% endif %}", context: ctx)
        #expect(result == "hello")
    }

    @Test("tags, if, non-empty hash is truthy", .timeLimit(.minutes(1)))
    func nonEmptyHashIsTruthy() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if product %}bar{% else %}foo{% endif %}", context: ctx)
        #expect(result == "bar")
    }

    @Test("tags, if, not equal condition", .timeLimit(.minutes(1)))
    func notEqualCondition() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if product.title != 'foo' %}baz{% endif %}", context: ctx)
        #expect(result == "")
    }

    @Test("tags, if, not is not a valid operator", .timeLimit(.minutes(1)))
    func notIsNotAValidOperator() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% if not false %}TRUE{% else %}FALSE{% endif %}", context: [:])
            Issue.record("Expected error for \"tags, if, not is not a valid operator\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, if, object contains nil", .timeLimit(.minutes(1)))
    func objectContainsNil() async throws {
        let ctx: [String: Any] = [
            "obj": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("foo", "bar" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if obj contains nosuchthing %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "FALSE")
    }

    @Test("tags, if, object contains undefined", .timeLimit(.minutes(1)))
    func objectContainsUndefined() async throws {
        let ctx: [String: Any] = [
            "obj": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("foo", "bar" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if obj contains nosuchthing %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "FALSE")
    }

    @Test("tags, if, one is not equal to true", .timeLimit(.minutes(1)))
    func oneIsNotEqualToTrue() async throws {
        let result = try await renderWithTimeout(template: "{% if 1 == true %}Hello{% else %}Goodbye{% endif %}", context: [:])
        #expect(result == "Goodbye")
    }

    @Test("tags, if, range equals range", .timeLimit(.minutes(1)))
    func rangeEqualsRange() async throws {
        let result = try await renderWithTimeout(template: "{% assign foo = (1..3) %}{% if foo == (1..3) %}true{% else %}false{% endif %}", context: [:])
        #expect(result == "true")
    }

    @Test("tags, if, startswith is not a valid operator", .timeLimit(.minutes(1)))
    func startswithIsNotAValidOperator() async throws {
        let ctx: [String: Any] = [
            "s": "hello",
            "t": "hell"
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{% if s startswith t %}TRUE{% else %}FALSE{% endif %}", context: ctx)
            Issue.record("Expected error for \"tags, if, startswith is not a valid operator\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, if, string contains int", .timeLimit(.minutes(1)))
    func stringContainsInt() async throws {
        let result = try await renderWithTimeout(template: "{% if 'hel9lo' contains 9 %}TRUE{% else %}FALSE{% endif %}", context: [:])
        #expect(result == "TRUE")
    }

    @Test("tags, if, string contains nil", .timeLimit(.minutes(1)))
    func stringContainsNil() async throws {
        let ctx: [String: Any] = [
            "s": "hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if s contains nil %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "FALSE")
    }

    @Test("tags, if, string contains string", .timeLimit(.minutes(1)))
    func stringContainsString() async throws {
        let result = try await renderWithTimeout(template: "{% if 'hello' contains 'llo' %}TRUE{% else %}FALSE{% endif %}", context: [:])
        #expect(result == "TRUE")
    }

    @Test("tags, if, string contains string from context", .timeLimit(.minutes(1)))
    func stringContainsStringFromContext() async throws {
        let ctx: [String: Any] = [
            "s": "llo"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if 'hello' contains s %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "TRUE")
    }

    @Test("tags, if, string contains undefined", .timeLimit(.minutes(1)))
    func stringContainsUndefined() async throws {
        let ctx: [String: Any] = [
            "s": "hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if s contains nosuchthing %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "FALSE")
    }

    @Test("tags, if, string does not equal int", .timeLimit(.minutes(1)))
    func stringDoesNotEqualInt() async throws {
        let result = try await renderWithTimeout(template: "{% if '1' == 1 %}true{% else %}false{% endif %}", context: [:])
        #expect(result == "false")
    }

    @Test("tags, if, string greater than int", .timeLimit(.minutes(1)))
    func stringGreaterThanInt() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% if '2' > 1 %}true{% else %}false{% endif %}", context: [:])
            Issue.record("Expected error for \"tags, if, string greater than int\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, if, string is greater than or equal to string", .timeLimit(.minutes(1)))
    func stringIsGreaterThanOrEqualToString() async throws {
        let result = try await renderWithTimeout(template: "{% if 'abc' >= 'acb' %}true{% else %}false{% endif %}", context: [:])
        #expect(result == "false")
    }

    @Test("tags, if, string is greater than string", .timeLimit(.minutes(1)))
    func stringIsGreaterThanString() async throws {
        let result = try await renderWithTimeout(template: "{% if 'abc' > 'acb' %}true{% else %}false{% endif %}", context: [:])
        #expect(result == "false")
    }

    @Test("tags, if, string is less than or equal to string", .timeLimit(.minutes(1)))
    func stringIsLessThanOrEqualToString() async throws {
        let result = try await renderWithTimeout(template: "{% if 'abc' <= 'acb' %}true{% else %}false{% endif %}", context: [:])
        #expect(result == "true")
    }

    @Test("tags, if, string is less than string", .timeLimit(.minutes(1)))
    func stringIsLessThanString() async throws {
        let result = try await renderWithTimeout(template: "{% if 'abc' < 'acb' %}true{% else %}false{% endif %}", context: [:])
        #expect(result == "true")
    }

    @Test("tags, if, string is not greater than or equal to string", .timeLimit(.minutes(1)))
    func stringIsNotGreaterThanOrEqualToString() async throws {
        let result = try await renderWithTimeout(template: "{% if 'bbb' >= 'aaa' %}true{% else %}false{% endif %}", context: [:])
        #expect(result == "true")
    }

    @Test("tags, if, string is not greater than string", .timeLimit(.minutes(1)))
    func stringIsNotGreaterThanString() async throws {
        let result = try await renderWithTimeout(template: "{% if 'bbb' > 'aaa' %}true{% else %}false{% endif %}", context: [:])
        #expect(result == "true")
    }

    @Test("tags, if, string is not less than or equal to string", .timeLimit(.minutes(1)))
    func stringIsNotLessThanOrEqualToString() async throws {
        let result = try await renderWithTimeout(template: "{% if 'bbb' <= 'aaa' %}true{% else %}false{% endif %}", context: [:])
        #expect(result == "false")
    }

    @Test("tags, if, string is not less than string", .timeLimit(.minutes(1)))
    func stringIsNotLessThanString() async throws {
        let result = try await renderWithTimeout(template: "{% if 'bbb' < 'aaa' %}true{% else %}false{% endif %}", context: [:])
        #expect(result == "false")
    }

    @Test("tags, if, undefined contains array", .timeLimit(.minutes(1)))
    func undefinedContainsArray() async throws {
        let ctx: [String: Any] = [
            "a": [1, 2, 3]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if undefined contains a %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "FALSE")
    }

    @Test("tags, if, undefined contains object", .timeLimit(.minutes(1)))
    func undefinedContainsObject() async throws {
        let ctx: [String: Any] = [
            "obj": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("foo", "bar" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if undefined contains obj %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "FALSE")
    }

    @Test("tags, if, undefined contains string", .timeLimit(.minutes(1)))
    func undefinedContainsString() async throws {
        let ctx: [String: Any] = [
            "s": "hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% if undefined contains s %}TRUE{% else %}FALSE{% endif %}", context: ctx)
        #expect(result == "FALSE")
    }

    @Test("tags, if, undefined contains undefined", .timeLimit(.minutes(1)))
    func undefinedContainsUndefined() async throws {
        let result = try await renderWithTimeout(template: "{% if undefined contains thing %}TRUE{% else %}FALSE{% endif %}", context: [:])
        #expect(result == "FALSE")
    }

    @Test("tags, if, undefined is equal to nil", .timeLimit(.minutes(1)))
    func undefinedIsEqualToNil() async throws {
        let result = try await renderWithTimeout(template: "{% if nosuchthing == nil %}TRUE{% else %}FALSE{% endif %}", context: [:])
        #expect(result == "TRUE")
    }

    @Test("tags, if, undefined is equal to null", .timeLimit(.minutes(1)))
    func undefinedIsEqualToNull() async throws {
        let result = try await renderWithTimeout(template: "{% if nosuchthing == null %}TRUE{% else %}FALSE{% endif %}", context: [:])
        #expect(result == "TRUE")
    }

    @Test("tags, if, undefined variables are falsy", .timeLimit(.minutes(1)))
    func undefinedVariablesAreFalsy() async throws {
        let result = try await renderWithTimeout(template: "{% if nosuchthing %}bar{% else %}foo{% endif %}", context: [:])
        #expect(result == "foo")
    }

    @Test("tags, if, zero is not equal to false", .timeLimit(.minutes(1)))
    func zeroIsNotEqualToFalse() async throws {
        let result = try await renderWithTimeout(template: "{% if 0 == false %}Hello{% else %}Goodbye{% endif %}", context: [:])
        #expect(result == "Goodbye")
    }

    @Test("tags, if, zero is truthy", .timeLimit(.minutes(1)))
    func zeroIsTruthy() async throws {
        let result = try await renderWithTimeout(template: "{% if 0 %}Hello{% else %}Goodbye{% endif %}", context: [:])
        #expect(result == "Hello")
    }
}
