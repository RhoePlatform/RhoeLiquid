//
//  RenderTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: render", .serialized)
struct GoldenRenderTests {

    @Test("tags, render, assign to keyword argument", .timeLimit(.minutes(1)))
    func assignToKeywordArgument() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ foo }}{% assign foo='goodbye' %} {{ foo }}".write(
            to: tempDir.appendingPathComponent("product-args.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% render 'product-args', foo: 'hello' %}{{ foo }}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "hello goodbye")
    }

    @Test("tags, render, assigned variables do not leak into outer scope", .timeLimit(.minutes(1)))
    func assignedVariablesDoNotLeakIntoOuterScope() async throws {
        let ctx: [String: Any] = [
            "customer": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("first_name", "Holly" as Any)
            ])
        ] as [String: Any]
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "Hello, {{ customer.first_name }}{% assign last_name = 'Smith' %}".write(
            to: tempDir.appendingPathComponent("assign-outer-scope.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% render 'assign-outer-scope', customer: customer %} {{ last_name }}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "Hello, Holly ")
    }

    @Test("tags, render, bound array variable", .timeLimit(.minutes(1)))
    func boundArrayVariable() async throws {
        let ctx: [String: Any] = [
            "collection": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("products", [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "bike" as Any)
                    ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "car" as Any)
                    ])] as [Any] as Any)
            ])
        ] as [String: Any]
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ prod.title }}".write(
            to: tempDir.appendingPathComponent("prod.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% render 'prod' for collection.products %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "bikecar")
    }

    @Test("tags, render, bound variable", .timeLimit(.minutes(1)))
    func boundVariable() async throws {
        let ctx: [String: Any] = [
            "collection": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("products", [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "bike" as Any)
                    ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "car" as Any)
                    ])] as [Any] as Any)
            ])
        ] as [String: Any]
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ product-title.title }}".write(
            to: tempDir.appendingPathComponent("product-title.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% render 'product-title' with collection.products[1] %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "car")
    }

    @Test("tags, render, bound variable does not exist", .timeLimit(.minutes(1)))
    func boundVariableDoesNotExist() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ product-title.title }}".write(
            to: tempDir.appendingPathComponent("product-title.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% render 'product-title' with no.such.thing %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "")
    }

    @Test("tags, render, bound variable with alias", .timeLimit(.minutes(1)))
    func boundVariableWithAlias() async throws {
        let ctx: [String: Any] = [
            "collection": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("products", [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "bike" as Any)
                    ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "car" as Any)
                    ])] as [Any] as Any)
            ])
        ] as [String: Any]
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ product.title }}".write(
            to: tempDir.appendingPathComponent("product-alias.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% render 'product-alias' with collection.products[1] as product %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "car")
    }

    @Test("tags, render, decrement is isolated between renders", .timeLimit(.minutes(1)))
    func decrementIsIsolatedBetweenRenders() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{% decrement foo %}".write(
            to: tempDir.appendingPathComponent("decrement.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% decrement foo %} {% render 'decrement' %} {% decrement foo %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "-1 -1 -2")
    }

    @Test("tags, render, for loop variables go out of scope", .timeLimit(.minutes(1)))
    func forLoopVariablesGoOutOfScope() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ i }}".write(
            to: tempDir.appendingPathComponent("loop-scope.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% for i in (1..3) %}{{ i }}{% render 'loop-scope' %}{{ i }}{% endfor %}{{ i }}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "112233")
    }

    @Test("tags, render, forloop helper", .timeLimit(.minutes(1)))
    func forloopHelper() async throws {
        let ctx: [String: Any] = [
            "collection": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("products", [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "bike" as Any)
                    ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "car" as Any)
                    ])] as [Any] as Any)
            ])
        ] as [String: Any]
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "Product: {{ product.title }} {% if forloop.first %}first{% endif %}{% if forloop.last %}last{% endif %} index:{{ forloop.index }} ".write(
            to: tempDir.appendingPathComponent("product.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% render 'product' for collection.products %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "Product: bike first index:1 Product: car last index:2 ")
    }

    @Test("tags, render, increment is isolated between renders", .timeLimit(.minutes(1)))
    func incrementIsIsolatedBetweenRenders() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{% increment foo %}".write(
            to: tempDir.appendingPathComponent("increment.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% increment foo %} {% render 'increment' %} {% increment foo %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "0 0 1")
    }

    @Test("tags, render, parent variables go out of scope", .timeLimit(.minutes(1)))
    func parentVariablesGoOutOfScope() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ greeting }}".write(
            to: tempDir.appendingPathComponent("outer-scope.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% assign greeting = 'good morning' %}{{ greeting }} {% render 'outer-scope' %}{{ greeting }}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "good morning good morning")
    }

    @Test("tags, render, render loops can't access parentloop", .timeLimit(.minutes(1)))
    func renderLoopsCanTAccessParentloop() async throws {
        let ctx: [String: Any] = [
            "collection": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("products", [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "bike" as Any)
                    ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "car" as Any)
                    ])] as [Any] as Any)
            ])
        ] as [String: Any]
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ product.title }}-{{ forloop.index0 }} {{ forloop.parentloop.index0 }}".write(
            to: tempDir.appendingPathComponent("product.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% for x in (1..3) %}{% render 'product' for collection.products %}{% endfor %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "bike-0 car-1 bike-0 car-1 bike-0 car-1 ")
    }

    @Test("tags, render, render loops don't add parentloop", .timeLimit(.minutes(1)))
    func renderLoopsDonTAddParentloop() async throws {
        let ctx: [String: Any] = [
            "collection": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("products", [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "bike" as Any)
                    ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "car" as Any)
                    ])] as [Any] as Any)
            ])
        ] as [String: Any]
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ product.title }}-{{ forloop.index0 }} {% for x in (1..3) %}{{ forloop.index0 }}{{ forloop.parentloop.index0 }} {% endfor %}".write(
            to: tempDir.appendingPathComponent("product.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% render 'product' for collection.products %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "bike-0 0 1 2 car-1 0 1 2 ")
    }

    @Test("tags, render, some keyword arguments", .timeLimit(.minutes(1)))
    func someKeywordArguments() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ foo }} {{ bar }}".write(
            to: tempDir.appendingPathComponent("product-args.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% render 'product-args', foo: 'hello', bar: 'there' %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "hello there")
    }

    @Test("tags, render, some keyword arguments including a range literal", .timeLimit(.minutes(1)))
    func someKeywordArgumentsIncludingARangeLiteral() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ foo | join: '#' }} {{ bar }}".write(
            to: tempDir.appendingPathComponent("product-args.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% render 'product-args', foo: (1..3), bar: 'there' %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "1#2#3 there")
    }

    @Test("tags, render, some keyword arguments no leading coma", .timeLimit(.minutes(1)))
    func someKeywordArgumentsNoLeadingComa() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ foo }} {{ bar }}".write(
            to: tempDir.appendingPathComponent("product-args.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% render 'product-args' foo: 'hello', bar: 'there' %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "hello there")
    }

    @Test("tags, render, string literal name", .timeLimit(.minutes(1)))
    func stringLiteralName() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any),
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ product.title }}\n{% for tag in product.tags %}- {{ tag }} {% endfor %}".write(
            to: tempDir.appendingPathComponent("product-hero.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% render 'product-hero', product: product %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "foo\n- sports - garden ")
    }
}
