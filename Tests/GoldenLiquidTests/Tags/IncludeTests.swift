//
//  IncludeTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: include", .serialized)
struct GoldenIncludeTests {

    @Test("tags, include, assign persists in outer scope", .timeLimit(.minutes(1)))
    func assignPersistsInOuterScope() async throws {
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
        try "{% include 'assign-outer-scope' %} {{ last_name }}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "Hello, Holly Smith")
    }

    @Test("tags, include, assign to a keyword argument", .timeLimit(.minutes(1)))
    func assignToAKeywordArgument() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ foo }}{% assign foo = 'goodbye' %} {{ foo }}".write(
            to: tempDir.appendingPathComponent("product-args.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% include 'product-args', foo: 'hello' %} {{ foo }}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "hello hello goodbye")
    }

    @Test("tags, include, bound array variable", .timeLimit(.minutes(1)))
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
        try "{% include 'prod' for collection.products %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "bikecar")
    }

    @Test("tags, include, bound variable", .timeLimit(.minutes(1)))
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
        try "{% include 'product-title' with collection.products[1] %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "car")
    }

    @Test("tags, include, bound variable does not exist", .timeLimit(.minutes(1)))
    func boundVariableDoesNotExist() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ product-title.title }}".write(
            to: tempDir.appendingPathComponent("product-title.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% include 'product-title' with no.such.thing %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "")
    }

    @Test("tags, include, bound variable with alias", .timeLimit(.minutes(1)))
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
        try "{% include 'product-alias' with collection.products[1] as product %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "car")
    }

    @Test("tags, include, break from include", .timeLimit(.minutes(1)))
    func breakFromInclude() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ tag | upcase }}{% break %}".write(
            to: tempDir.appendingPathComponent("tag-break.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% for tag in product.tags %}{% include 'tag-break' %}{% endfor %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "SPORTS")
    }

    @Test("tags, include, break from nested include", .timeLimit(.minutes(1)))
    func breakFromNestedInclude() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try " break!{% break %}".write(
            to: tempDir.appendingPathComponent("break.liquid"),
            atomically: true, encoding: .utf8)

        try "{{ tag | upcase }}{% include 'break' %}".write(
            to: tempDir.appendingPathComponent("tag.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% for tag in product.tags %}{% include 'tag' %}{% endfor %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "SPORTS break!")
    }

    @Test("tags, include, counter from outer scope", .timeLimit(.minutes(1)))
    func counterFromOuterScope() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{% increment foo %}".write(
            to: tempDir.appendingPathComponent("increment-outer-scope.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% increment foo %} {% include 'increment-outer-scope' %} {% increment foo %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "0 1 2")
    }

    @Test("tags, include, keyword arguments go out of scope", .timeLimit(.minutes(1)))
    func keywordArgumentsGoOutOfScope() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ foo }} {{ bar }}".write(
            to: tempDir.appendingPathComponent("product-args.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% include 'product-args', foo: 'hello', bar: 'there' %}{{ foo }}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "hello there")
    }

    @Test("tags, include, name from identifier", .timeLimit(.minutes(1)))
    func nameFromIdentifier() async throws {
        let ctx: [String: Any] = [
            "snippet": "product-hero",
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any),
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ product.title }}\n{% for tag in product.tags %}- {{ tag }}\n{% endfor %}".write(
            to: tempDir.appendingPathComponent("product-hero.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% include snippet %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "foo\n- sports\n- garden\n")
    }

    @Test("tags, include, some keyword arguments", .timeLimit(.minutes(1)))
    func someKeywordArguments() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ foo }} {{ bar }}".write(
            to: tempDir.appendingPathComponent("product-args.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% include 'product-args', foo: 'hello', bar: 'there' %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "hello there")
    }

    @Test("tags, include, some keyword arguments with float literals", .timeLimit(.minutes(1)))
    func someKeywordArgumentsWithFloatLiterals() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ foo }} {{ bar }}".write(
            to: tempDir.appendingPathComponent("product-args.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% include 'product-args' foo: 1.1, bar: 'there' %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "1.1 there")
    }

    @Test("tags, include, some keyword arguments with range literal", .timeLimit(.minutes(1)))
    func someKeywordArgumentsWithRangeLiteral() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ foo | join: '#' }} {{ bar }}".write(
            to: tempDir.appendingPathComponent("product-args.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% include 'product-args' foo: (1..3), bar: 'there' %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "1#2#3 there")
    }

    @Test("tags, include, some keyword arguments without leading comma", .timeLimit(.minutes(1)))
    func someKeywordArgumentsWithoutLeadingComma() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "{{ foo }} {{ bar }}".write(
            to: tempDir.appendingPathComponent("product-args.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% include 'product-args' foo: 'hello', bar: 'there' %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: [:],
            baseDirectory: tempDir)
        #expect(result == "hello there")
    }

    @Test("tags, include, string literal name", .timeLimit(.minutes(1)))
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

        try "{{ product.title }}\n{% for tag in product.tags %}- {{ tag }}\n{% endfor %}".write(
            to: tempDir.appendingPathComponent("product-hero.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% include 'product-hero' %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "foo\n- sports\n- garden\n")
    }

    @Test("tags, include, use globals from outer scope", .timeLimit(.minutes(1)))
    func useGlobalsFromOuterScope() async throws {
        let ctx: [String: Any] = [
            "customer": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("first_name", "Holly" as Any)
            ])
        ] as [String: Any]
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("golden_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try "Hello, {{ customer.first_name }}".write(
            to: tempDir.appendingPathComponent("outer-scope.liquid"),
            atomically: true, encoding: .utf8)

        let mainPath = tempDir.appendingPathComponent("_main_.liquid")
        try "{% include 'outer-scope' %}".write(
            to: mainPath, atomically: true, encoding: .utf8)

        let result = try await renderWithInheritanceTimeout(
            templatePath: mainPath.path, context: ctx,
            baseDirectory: tempDir)
        #expect(result == "Hello, Holly")
    }
}
