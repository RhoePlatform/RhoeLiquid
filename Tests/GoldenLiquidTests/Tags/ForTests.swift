//
//  ForTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: for", .serialized)
struct GoldenForTests {

    @Test("tags, for, access parentloop", .timeLimit(.minutes(1)))
    func accessParentloop() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (1..2)%}{% for j in (1..2) %}{{ i }} {{j}} {{ forloop.parentloop.index }} {{ forloop.index }} {% endfor %}{% endfor %}", context: [:])
        #expect(result == "1 1 1 1 1 2 1 2 2 1 2 1 2 2 2 2 ")
    }

    @Test("tags, for, assign inside loop", .timeLimit(.minutes(1)))
    func assignInsideLoop() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{% assign x = tag %}{% endfor %}{{ x }}", context: ctx)
        #expect(result == "garden")
    }

    @Test("tags, for, blank empty loops", .timeLimit(.minutes(1)))
    func blankEmptyLoops() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (0..10) %}  {% endfor %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, for, break", .timeLimit(.minutes(1)))
    func breakTest() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{% if tag == 'sports' %}{% break %}{% else %}{{ tag }} {% endif %}{% else %}no images{% endfor %}", context: ctx)
        #expect(result == "")
    }

    @Test("tags, for, comma separated arguments", .timeLimit(.minutes(1)))
    func commaSeparatedArguments() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (1..6), limit: 4, offset: 2 %}{{ i }} {% endfor %}", context: [:])
        #expect(result == "3 4 5 6 ")
    }

    @Test("tags, for, continue", .timeLimit(.minutes(1)))
    func continueTest() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{% if tag == 'sports' %}{% continue %}{% else %}{{ tag }} {% endif %}{% else %}no images{% endfor %}", context: ctx)
        #expect(result == "garden ")
    }

    @Test("tags, for, continue a loop", .timeLimit(.minutes(1)))
    func continueALoop() async throws {
        let ctx: [String: Any] = [
            "array": [1, 2, 3, 4, 5, 6]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for item in array limit: 3 %}a{{ item }} {% endfor %}{% for item in array offset: continue %}b{{ item }} {% endfor %}", context: ctx)
        #expect(result == "a1 a2 a3 b4 b5 b6 ")
    }

    @Test("tags, for, continue a loop over a changing array", .timeLimit(.minutes(1)))
    func continueALoopOverAChangingArray() async throws {
        let result = try await renderWithTimeout(template: "{% assign foo = '1,2,3,4,5,6' | split: ',' %}{% for item in foo limit: 3 %}{{ item }} {% endfor %}{% assign foo = 'u,v,w,x,y,z' | split: ',' %}{% for item in foo offset: continue %}{{ item }} {% endfor %}", context: [:])
        #expect(result == "1 2 3 x y z ")
    }

    @Test("tags, for, continue a loop over an assigned range", .timeLimit(.minutes(1)))
    func continueALoopOverAnAssignedRange() async throws {
        let result = try await renderWithTimeout(template: "{% assign nums = (1..5) %}{% for item in nums limit: 3 %}a{{ item }} {% endfor %}{% for item in nums offset: continue %}b{{ item }} {% endfor %}", context: [:])
        #expect(result == "a1 a2 a3 b4 b5 ")
    }

    @Test("tags, for, continue from a limit that is greater than length", .timeLimit(.minutes(1)))
    func continueFromALimitThatIsGreaterThanLength() async throws {
        let ctx: [String: Any] = [
            "array": [1, 2, 3, 4, 5, 6]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for item in array limit: 99 %}a{{ item }} {% endfor %}{% for item in array offset: continue %}b{{ item }} {% endfor %}", context: ctx)
        #expect(result == "a1 a2 a3 a4 a5 a6 ")
    }

    @Test("tags, for, continue from a range expression", .timeLimit(.minutes(1)))
    func continueFromARangeExpression() async throws {
        let ctx: [String: Any] = [
            "array": [1, 2, 3, 4, 5, 6]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for item in (1..6) limit: 3 %}a{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}b{{ item }} {% endfor %}", context: ctx)
        #expect(result == "a1 a2 a3 b4 b5 b6 ")
    }

    @Test("tags, for, continue with changing loop var", .timeLimit(.minutes(1)))
    func continueWithChangingLoopVar() async throws {
        let ctx: [String: Any] = [
            "array": [1, 2, 3, 4, 5, 6]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for foo in array limit: 3 %}{{ foo }} {% endfor %}{% for bar in array offset: continue %}{{ bar }} {% endfor %}", context: ctx)
        #expect(result == "1 2 3 1 2 3 4 5 6 ")
    }

    @Test("tags, for, empty array with default", .timeLimit(.minutes(1)))
    func emptyArrayWithDefault() async throws {
        let ctx: [String: Any] = [
            "emptythings": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("array", [Any]() as Any),
                ("map", OrderedDictionary<String, Any>() as Any),
                ("string", "" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for img in emptythings.array %}{{ img.url }} {% else %}no images{% endfor %}", context: ctx)
        #expect(result == "no images")
    }

    @Test("tags, for, first and last with an offset and limit", .timeLimit(.minutes(1)))
    func firstAndLastWithAnOffsetAndLimit() async throws {
        let ctx: [String: Any] = [
            "tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in tags limit: 2 offset: 1 %}{{ tag }} {{ forloop.first }} {{ forloop.last }} {% endfor %}", context: ctx)
        #expect(result == "garden true false home false true ")
    }

    @Test("tags, for, first and last with offset continue", .timeLimit(.minutes(1)))
    func firstAndLastWithOffsetContinue() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden", "home", "diy", "motoring", "fashion"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags limit: 1 %}{% endfor %}{% for tag in product.tags offset: continue %}{{ forloop.first }} {{ forloop.last }} {% endfor %}", context: ctx)
        #expect(result == "true false false false false false false false false true ")
    }

    @Test("tags, for, forloop goes out of scope", .timeLimit(.minutes(1)))
    func forloopGoesOutOfScope() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{{ forloop.length }} {% endfor %}{{ forloop.length }}", context: ctx)
        #expect(result == "2 2 ")
    }

    @Test("tags, for, forloop length", .timeLimit(.minutes(1)))
    func forloopLength() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{{ forloop.length }} {% endfor %}", context: ctx)
        #expect(result == "2 2 ")
    }

    @Test("tags, for, forloop length with limit", .timeLimit(.minutes(1)))
    func forloopLengthWithLimit() async throws {
        let ctx: [String: Any] = [
            "tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in tags limit:3 %}{{ forloop.length }} {% endfor %}", context: ctx)
        #expect(result == "3 3 3 ")
    }

    @Test("tags, for, forloop length with offset", .timeLimit(.minutes(1)))
    func forloopLengthWithOffset() async throws {
        let ctx: [String: Any] = [
            "tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in tags offset:3 %}{{ forloop.length }} {% endfor %}", context: ctx)
        #expect(result == "3 3 3 ")
    }

    @Test("tags, for, forloop name", .timeLimit(.minutes(1)))
    func forloopName() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags limit:1 %}{{ forloop.name }}{% endfor %}", context: ctx)
        #expect(result == "tag-product.tags")
    }

    @Test("tags, for, forloop name of a range", .timeLimit(.minutes(1)))
    func forloopNameOfARange() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (1..3) limit:1 %}{{ forloop.name }}{% endfor %}", context: [:])
        #expect(result == "i-(1..3)")
    }

    @Test("tags, for, forloop no such attribute", .timeLimit(.minutes(1)))
    func forloopNoSuchAttribute() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{{ forloop.nosuchthing }}{% endfor %}", context: ctx)
        #expect(result == "")
    }

    @Test("tags, for, forloop.first", .timeLimit(.minutes(1)))
    func forloopFirst() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{{ forloop.first }} {% endfor %}", context: ctx)
        #expect(result == "true false ")
    }

    @Test("tags, for, forloop.index", .timeLimit(.minutes(1)))
    func forloopIndex() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{{ forloop.index }} {% endfor %}", context: ctx)
        #expect(result == "1 2 ")
    }

    @Test("tags, for, forloop.index0", .timeLimit(.minutes(1)))
    func forloopIndex0() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{{ forloop.index0 }} {% endfor %}", context: ctx)
        #expect(result == "0 1 ")
    }

    @Test("tags, for, forloop.last", .timeLimit(.minutes(1)))
    func forloopLast() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{{ forloop.last }} {% endfor %}", context: ctx)
        #expect(result == "false true ")
    }

    @Test("tags, for, forloop.rindex", .timeLimit(.minutes(1)))
    func forloopRindex() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{{ forloop.rindex }} {% endfor %}", context: ctx)
        #expect(result == "2 1 ")
    }

    @Test("tags, for, forloop.rindex0", .timeLimit(.minutes(1)))
    func forloopRindex0() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{{ forloop.rindex0 }} {% endfor %}", context: ctx)
        #expect(result == "1 0 ")
    }

    @Test("tags, for, iterate an empty array", .timeLimit(.minutes(1)))
    func iterateAnEmptyArray() async throws {
        let ctx: [String: Any] = [
            "emptythings": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("array", [Any]() as Any),
                ("map", OrderedDictionary<String, Any>() as Any),
                ("string", "" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for item in emptythings.array %}{{ item }}{% endfor %}", context: ctx)
        #expect(result == "")
    }

    @Test("tags, for, iterate an empty array with default", .timeLimit(.minutes(1)))
    func iterateAnEmptyArrayWithDefault() async throws {
        let ctx: [String: Any] = [
            "emptythings": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("array", [Any]() as Any),
                ("map", OrderedDictionary<String, Any>() as Any),
                ("string", "" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for item in emptythings.array %}{{ item }}{% else %}foo{% endfor %}", context: ctx)
        #expect(result == "foo")
    }

    @Test("tags, for, limit", .timeLimit(.minutes(1)))
    func limit() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags limit:1 %}{{ tag }} {% endfor %}", context: ctx)
        #expect(result == "sports ")
    }

    @Test("tags, for, limit is a non-number string", .timeLimit(.minutes(1)))
    func limitIsANonNumberString() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% for i in (1..4) limit: 'foo' %}{{ i }} {% endfor %}", context: [:])
            Issue.record("Expected error for \"tags, for, limit is a non-number string\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, for, limit is a string", .timeLimit(.minutes(1)))
    func limitIsAString() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (1..4) limit: '2' %}{{ i }} {% endfor %}", context: [:])
        #expect(result == "1 2 ")
    }

    @Test("tags, for, limit is not a string or number", .timeLimit(.minutes(1)))
    func limitIsNotAStringOrNumber() async throws {
        let ctx: [String: Any] = [
            "foo": [1, 2, 3]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{% for i in (1..4) limit: foo %}{{ i }} {% endfor %}", context: ctx)
            Issue.record("Expected error for \"tags, for, limit is not a string or number\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, for, lookup a filter from an outer context", .timeLimit(.minutes(1)))
    func lookupAFilterFromAnOuterContext() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{{ tag | upcase }} {% endfor %}", context: ctx)
        #expect(result == "SPORTS GARDEN ")
    }

    @Test("tags, for, loop over a non-iterable object", .timeLimit(.minutes(1)))
    func loopOverANonIterableObject() async throws {
        let ctx: [String: Any] = [
            "x": true
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for i in x %}{{ i }} {% endfor %}", context: ctx)
        #expect(result == "")
    }

    @Test("tags, for, loop over a string literal", .timeLimit(.minutes(1)))
    func loopOverAStringLiteral() async throws {
        let result = try await renderWithTimeout(template: "{% for i in 'hello' %}{{ i }} {% endfor %}", context: [:])
        #expect(result == "hello ")
    }

    @Test("tags, for, loop over a string variable", .timeLimit(.minutes(1)))
    func loopOverAStringVariable() async throws {
        let ctx: [String: Any] = [
            "foo": "hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for i in foo %}{{ i }} {% endfor %}", context: ctx)
        #expect(result == "hello ")
    }

    @Test("tags, for, loop over an array in reverse", .timeLimit(.minutes(1)))
    func loopOverAnArrayInReverse() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags reversed %}{{ tag }} {% endfor %}", context: ctx)
        #expect(result == "garden sports ")
    }

    @Test("tags, for, loop over an empty string", .timeLimit(.minutes(1)))
    func loopOverAnEmptyString() async throws {
        let result = try await renderWithTimeout(template: "{% for i in '' %}{{ i }} {% endfor %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, for, loop over an existing range object", .timeLimit(.minutes(1)))
    func loopOverAnExistingRangeObject() async throws {
        let result = try await renderWithTimeout(template: "{% assign foo = (1..3) %}{{ foo | join: '#' }}{% for i in foo %}{{ i }}{% endfor %}{% for i in foo %}{{ i }}{% endfor %}", context: [:])
        #expect(result == "1#2#3123123")
    }

    @Test("tags, for, loop over nested and chained object from context with trailing identifier", .timeLimit(.minutes(1)))
    func loopOverNestedAndChainedObjectFromContextWithTrailingIdentifier() async throws {
        let ctx: [String: Any] = [
            "linklists": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("main", OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("links", ["1", "2"] as Any)
                ]) as Any)
            ]),
            "section": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("settings", OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("menu", "main" as Any)
                ]) as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for link in linklists[section.settings.menu].links %}{{ link }} {% endfor %}", context: ctx)
        #expect(result == "1 2 ")
    }

    @Test("tags, for, loop over range with float start", .timeLimit(.minutes(1)))
    func loopOverRangeWithFloatStart() async throws {
        let result = try await renderWithTimeout(template: "{% assign x = (2.4..5) %}{% for i in x %}{{ i }}{% endfor %}", context: [:])
        #expect(result == "2345")
    }

    @Test("tags, for, loop over undefined", .timeLimit(.minutes(1)))
    func loopOverUndefined() async throws {
        let result = try await renderWithTimeout(template: "{% for tag in nosuchthing %}{{ tag }}{% endfor %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, for, nothing to continue from", .timeLimit(.minutes(1)))
    func nothingToContinueFrom() async throws {
        let ctx: [String: Any] = [
            "array": [1, 2, 3, 4, 5, 6]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for item in array %}a{{ item }} {% endfor %}{% for item in array offset: continue %}b{{ item }} {% endfor %}", context: ctx)
        #expect(result == "a1 a2 a3 a4 a5 a6 ")
    }

    @Test("tags, for, offset", .timeLimit(.minutes(1)))
    func offset() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags offset:1 %}{{ tag }} {% endfor %}", context: ctx)
        #expect(result == "garden ")
    }

    @Test("tags, for, offset and limit", .timeLimit(.minutes(1)))
    func offsetAndLimit() async throws {
        let ctx: [String: Any] = [
            "tags": ["sports", "garden", "home", "diy", "motoring", "fashion"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in tags limit: 3 offset: 1 %}{{ tag }} {% endfor %}", context: ctx)
        #expect(result == "garden home diy ")
    }

    @Test("tags, for, offset continue forloop length", .timeLimit(.minutes(1)))
    func offsetContinueForloopLength() async throws {
        let result = try await renderWithTimeout(template: "{% for item in (1..6) limit: 2 %}a{{ item }} - {{ forloop.length }}, {% endfor %}{% for item in (1..6) offset: continue %}b{{ item }} - {{ forloop.length }}, {% endfor %}", context: [:])
        #expect(result == "a1 - 2, a2 - 2, b3 - 4, b4 - 4, b5 - 4, b6 - 4, ")
    }

    @Test("tags, for, offset continue from a broken loop", .timeLimit(.minutes(1)))
    func offsetContinueFromABrokenLoop() async throws {
        let result = try await renderWithTimeout(template: "{% for item in (1..6) limit: 4 %}{% if item == 3 %}{% break %}{% endif %}a{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}b{{ item }} {% endfor %}", context: [:])
        #expect(result == "a1 a2 b5 b6 ")
    }

    @Test("tags, for, offset continue from a broken loop with preceding limit", .timeLimit(.minutes(1)))
    func offsetContinueFromABrokenLoopWithPrecedingLimit() async throws {
        let result = try await renderWithTimeout(template: "{% for item in (1..6) limit: 3 %}a{{ item }} {% endfor %}{% for item in (1..6) %}{% if item == 3 %}{% break %}{% endif %}b{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}c{{ item }} {% endfor %}", context: [:])
        #expect(result == "a1 a2 a3 b1 b2 ")
    }

    @Test("tags, for, offset continue twice with changing limit", .timeLimit(.minutes(1)))
    func offsetContinueTwiceWithChangingLimit() async throws {
        let result = try await renderWithTimeout(template: "{% for item in (1..6) limit: 2 %}a{{ item }} {% endfor %}{% for item in (1..6) limit: 3 offset: continue %}b{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}c{{ item }} {% endfor %}", context: [:])
        #expect(result == "a1 a2 b3 b4 b5 c6 ")
    }

    @Test("tags, for, offset continue twice with limit", .timeLimit(.minutes(1)))
    func offsetContinueTwiceWithLimit() async throws {
        let result = try await renderWithTimeout(template: "{% for item in (1..6) limit: 2 %}a{{ item }} {% endfor %}{% for item in (1..6) limit: 2 offset: continue %}b{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}c{{ item }} {% endfor %}", context: [:])
        #expect(result == "a1 a2 b3 b4 c5 c6 ")
    }

    @Test("tags, for, offset continue twice with no second limit", .timeLimit(.minutes(1)))
    func offsetContinueTwiceWithNoSecondLimit() async throws {
        let result = try await renderWithTimeout(template: "{% for item in (1..6) limit: 2 %}a{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}b{{ item }} {% endfor %}{% for item in (1..6) offset: continue %}c{{ item }} {% endfor %}", context: [:])
        #expect(result == "a1 a2 b3 b4 b5 b6 ")
    }

    @Test("tags, for, offset continue without preceding loop", .timeLimit(.minutes(1)))
    func offsetContinueWithoutPrecedingLoop() async throws {
        let ctx: [String: Any] = [
            "array": [1, 2, 3, 4, 5, 6]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for item in array offset: continue %}{{ item }} {% endfor %}", context: ctx)
        #expect(result == "1 2 3 4 5 6 ")
    }

    @Test("tags, for, offset is a non-number string", .timeLimit(.minutes(1)))
    func offsetIsANonNumberString() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% for i in (1..4) offset: 'foo' %}{{ i }} {% endfor %}", context: [:])
            Issue.record("Expected error for \"tags, for, offset is a non-number string\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, for, offset is a string", .timeLimit(.minutes(1)))
    func offsetIsAString() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (1..4) offset: '2' %}{{ i }} {% endfor %}", context: [:])
        #expect(result == "3 4 ")
    }

    @Test("tags, for, offset is not a string or number", .timeLimit(.minutes(1)))
    func offsetIsNotAStringOrNumber() async throws {
        let ctx: [String: Any] = [
            "foo": [1, 2, 3]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{% for i in (1..4) offset: foo %}{{ i }} {% endfor %}", context: ctx)
            Issue.record("Expected error for \"tags, for, offset is not a string or number\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, for, parent's parentloop", .timeLimit(.minutes(1)))
    func parentSParentloop() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (1..2) %}{% for j in (1..2) %}{% for k in (1..2) %}i={{ forloop.parentloop.parentloop.index }} j={{ forloop.parentloop.index }} k={{ forloop.index }} {% endfor %}{% endfor %}{% endfor %}", context: [:])
        #expect(result == "i=1 j=1 k=1 i=1 j=1 k=2 i=1 j=2 k=1 i=1 j=2 k=2 i=2 j=1 k=1 i=2 j=1 k=2 i=2 j=2 k=1 i=2 j=2 k=2 ")
    }

    @Test("tags, for, parentloop goes out of scope", .timeLimit(.minutes(1)))
    func parentloopGoesOutOfScope() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (1..2)%}{% for j in (1..2) %}{{ i }} {{ j }} {% endfor %}{{ forloop.parentloop.index }}{% endfor %}", context: [:])
        #expect(result == "1 1 1 2 2 1 2 2 ")
    }

    @Test("tags, for, parentloop is normally undefined", .timeLimit(.minutes(1)))
    func parentloopIsNormallyUndefined() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (1..2)%}{{ forloop.parentloop.index }}{% endfor %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, for, range loop using identifier", .timeLimit(.minutes(1)))
    func rangeLoopUsingIdentifier() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any),
                ("end_range", 1 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for i in (0..product.end_range) %}{{ i }} - {{ product.tags[i] }} {% endfor %}", context: ctx)
        #expect(result == "0 - sports 1 - garden ")
    }

    @Test("tags, for, range start and stop are the same", .timeLimit(.minutes(1)))
    func rangeStartAndStopAreTheSame() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (1..1) %}{{ i }} {% endfor %}", context: [:])
        #expect(result == "1 ")
    }

    @Test("tags, for, range start and stop are zero", .timeLimit(.minutes(1)))
    func rangeStartAndStopAreZero() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (0..0) %}{{ i }} {% endfor %}", context: [:])
        #expect(result == "0 ")
    }

    @Test("tags, for, share outer scope", .timeLimit(.minutes(1)))
    func shareOuterScope() async throws {
        let result = try await renderWithTimeout(template: "{% assign foo = 'hello' %}{% for x in (1..3) %}{% assign foo = x %}{% endfor %}{{ foo }}", context: [:])
        #expect(result == "3")
    }

    @Test("tags, for, simple array loop", .timeLimit(.minutes(1)))
    func simpleArrayLoop() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for tag in product.tags %}{{ tag }} {% endfor %}", context: ctx)
        #expect(result == "sports garden ")
    }

    @Test("tags, for, simple hash loop", .timeLimit(.minutes(1)))
    func simpleHashLoop() async throws {
        let ctx: [String: Any] = [
            "collection": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any),
                ("description", "bar" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for c in collection %}{{ c[0] }} {{ c[1] }} {% endfor %}", context: ctx)
        #expect(result == "title foo description bar ")
    }

    @Test("tags, for, simple range loop", .timeLimit(.minutes(1)))
    func simpleRangeLoop() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (0..3) %}{{ i }} {% endfor %}", context: [:])
        #expect(result == "0 1 2 3 ")
    }

    @Test("tags, for, some comma separated arguments", .timeLimit(.minutes(1)))
    func someCommaSeparatedArguments() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (1..6) limit: 4, offset: 2, %}{{ i }} {% endfor %}", context: [:])
        #expect(result == "3 4 5 6 ")
    }
}
