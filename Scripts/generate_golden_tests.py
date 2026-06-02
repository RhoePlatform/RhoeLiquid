#!/usr/bin/env python3
"""
Generate Swift Testing test files from golden_liquid.json fixture.

Each test category (filter/tag/feature) gets its own Swift file with
individual @Test functions, shared engine, and per-test timeout.

Usage:
    cd /path/to/RhoeLiquid
    python3 Scripts/generate_golden_tests.py
"""

import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

# --- Configuration ---

FIXTURE_PATH = "Tests/GoldenLiquidTests/Fixtures/golden_liquid.json"
OUTPUT_BASE = "Tests/GoldenLiquidTests"
TIMEOUT_SECONDS = 2.0

# Tags for features not yet implemented — generated with .disabled trait
UNSUPPORTED_TAGS = {"ifchanged tag", "doc tag", "strict2"}

# Swift reserved words that can't be function names
SWIFT_KEYWORDS = {
    "break", "case", "continue", "default", "defer", "do", "else", "fallthrough",
    "for", "guard", "if", "in", "repeat", "return", "switch", "where", "while",
    "as", "catch", "false", "is", "nil", "rethrows", "super", "self", "Self",
    "throw", "throws", "true", "try", "class", "deinit", "enum", "extension",
    "func", "import", "init", "inout", "internal", "let", "open", "operator",
    "private", "precedencegroup", "protocol", "public", "static", "struct",
    "subscript", "typealias", "var",
}

# --- Helpers ---

def to_camel_case(name: str) -> str:
    """Convert test name to camelCase Swift function name."""
    # Remove special chars, keep alphanumeric and spaces
    cleaned = re.sub(r'[^a-zA-Z0-9\s]', ' ', name)
    words = cleaned.split()
    if not words:
        return "unnamed"
    result = words[0].lower() + ''.join(w.capitalize() for w in words[1:])
    # Ensure it starts with a letter
    if result and not result[0].isalpha():
        result = "test" + result.capitalize()
    # Handle Swift keywords
    if result in SWIFT_KEYWORDS:
        result += "Test"
    return result


def escape_swift_string(s: str) -> str:
    """Escape a string for use as a Swift string literal."""
    s = s.replace("\\", "\\\\")
    s = s.replace('"', '\\"')
    s = s.replace("\n", "\\n")
    s = s.replace("\r", "\\r")
    s = s.replace("\t", "\\t")
    s = s.replace("\0", "\\0")
    return s


def json_value_to_swift(value, indent=8, top_level=False) -> str:
    """Convert a JSON value to a Swift literal expression.

    top_level=True uses [String: Any] for the outermost dict (API compatibility).
    Nested dicts use OrderedDictionary to preserve insertion order.
    """
    if value is None:
        return "NSNull()"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if value == int(value) and abs(value) < 1e15:
            return f"{value}"  # Keep as float like 5.0
        return str(value)
    if isinstance(value, str):
        return f'"{escape_swift_string(value)}"'
    if isinstance(value, list):
        if not value:
            return "[Any]()"
        items = [json_value_to_swift(v, indent + 4) for v in value]
        if all(isinstance(v, str) for v in value):
            return "[" + ", ".join(items) + "]"
        if all(isinstance(v, (int, float)) and not isinstance(v, bool) for v in value):
            return "[" + ", ".join(items) + "]"
        return "[" + ", ".join(items) + "] as [Any]"
    if isinstance(value, dict):
        if not value:
            if top_level:
                return "[String: Any]()"
            return "OrderedDictionary<String, Any>()"
        pad = " " * indent
        if top_level:
            # Top-level context: use [String: Any] for API compatibility
            entries = []
            for k, v in value.items():
                swift_val = json_value_to_swift(v, indent + 4)
                entries.append(f'{pad}    "{escape_swift_string(k)}": {swift_val}')
            inner = ",\n".join(entries)
            return f"[\n{inner}\n{pad}] as [String: Any]"
        else:
            # Nested dict: use OrderedDictionary to preserve insertion order
            entries = []
            for k, v in value.items():
                swift_val = json_value_to_swift(v, indent + 4)
                entries.append(f'{pad}    ("{escape_swift_string(k)}", {swift_val} as Any)')
            inner = ",\n".join(entries)
            return f"OrderedDictionary<String, Any>(uniqueKeysWithValues: [\n{inner}\n{pad}])"
    return f'"{escape_swift_string(str(value))}"'


def categorize_test(test: dict) -> tuple:
    """Return (category, directory) for a test based on its tags."""
    tags = test.get("tags", [])
    name = test["name"]

    # Primary category from test name prefix
    parts = name.split(", ")
    if len(parts) >= 2:
        group = parts[0]  # e.g., "filters", "tags", "range"
        feature = parts[1]  # e.g., "abs", "for", "comment"
    else:
        group = "misc"
        feature = parts[0]

    # Map to directory and category
    if group == "filters":
        return (feature, "Filters")
    elif group == "tags":
        return (feature, "Tags")
    else:
        return (group, "Misc")


def category_to_filename(category: str) -> str:
    """Convert category name to PascalCase filename."""
    # Handle underscores and spaces
    words = re.sub(r'[^a-zA-Z0-9]', ' ', category).split()
    pascal = ''.join(w.capitalize() for w in words)
    return f"{pascal}Tests.swift"


def category_to_struct(category: str) -> str:
    """Convert category name to PascalCase struct name."""
    words = re.sub(r'[^a-zA-Z0-9]', ' ', category).split()
    return "Golden" + ''.join(w.capitalize() for w in words) + "Tests"


def is_unsupported(test: dict) -> bool:
    """Check if test uses unsupported features."""
    tags = set(test.get("tags", []))
    return bool(tags & UNSUPPORTED_TAGS)


def generate_test_method(test: dict, func_name: str) -> str:
    """Generate a single @Test method for a golden test case."""
    lines = []
    test_name = escape_swift_string(test["name"])
    is_invalid = test.get("invalid", False)
    has_templates = test.get("templates") is not None
    has_multi_results = test.get("results") is not None
    disabled = is_unsupported(test)

    # Build trait list
    traits = [f'"{test_name}"']
    traits.append(".timeLimit(.minutes(1))")
    if disabled:
        traits.append('.disabled("Feature not yet implemented in RhoeLiquid")')
    trait_str = ", ".join(traits)

    lines.append(f"    @Test({trait_str})")
    lines.append(f"    func {func_name}() async throws {{")

    # Context dictionary
    data = test.get("data")
    if data and isinstance(data, dict) and data:
        ctx_swift = json_value_to_swift(data, indent=8, top_level=True)
        lines.append(f"        let ctx: [String: Any] = {ctx_swift}")
        ctx_var = "ctx"
    else:
        ctx_var = "[:]"

    template = escape_swift_string(test["template"])

    if is_invalid:
        # Error-expecting test
        lines.append("        do {")
        lines.append(f'            _ = try await renderWithTimeout(template: "{template}", context: {ctx_var})')
        lines.append(f'            Issue.record("Expected error for \\"{test_name}\\" but rendering succeeded")')
        lines.append("        } catch is GoldenTestTimeoutError {")
        lines.append(f"            throw GoldenTestTimeoutError(seconds: {TIMEOUT_SECONDS})")
        lines.append("        } catch {")
        lines.append("            // Expected error")
        lines.append("        }")

    elif has_templates:
        # Mock filesystem test (include/render)
        templates = test["templates"]
        lines.append("        let tempDir = FileManager.default.temporaryDirectory")
        lines.append('            .appendingPathComponent("golden_\\(UUID().uuidString)")')
        lines.append("        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)")
        lines.append("        defer { try? FileManager.default.removeItem(at: tempDir) }")
        lines.append("")

        # Write mock template files
        for tpl_name, tpl_content in sorted(templates.items()):
            escaped_content = escape_swift_string(tpl_content)
            escaped_name = escape_swift_string(tpl_name)
            lines.append(f'        try "{escaped_content}".write(')
            lines.append(f'            to: tempDir.appendingPathComponent("{escaped_name}.liquid"),')
            lines.append('            atomically: true, encoding: .utf8)')
            lines.append("")

        # Write main template
        lines.append(f'        let mainPath = tempDir.appendingPathComponent("_main_.liquid")')
        lines.append(f'        try "{template}".write(')
        lines.append('            to: mainPath, atomically: true, encoding: .utf8)')
        lines.append("")

        lines.append(f"        let result = try await renderWithInheritanceTimeout(")
        lines.append(f"            templatePath: mainPath.path, context: {ctx_var},")
        lines.append(f"            baseDirectory: tempDir)")

        if has_multi_results:
            results_swift = "[" + ", ".join(f'"{escape_swift_string(r)}"' for r in test["results"]) + "]"
            lines.append(f"        let validResults: [String] = {results_swift}")
            lines.append(f'        #expect(validResults.contains(result), "Got \\(result)")')
        elif test.get("result") is not None:
            expected = escape_swift_string(test["result"])
            lines.append(f'        #expect(result == "{expected}")')

    else:
        # Normal render + compare
        lines.append(f'        let result = try await renderWithTimeout(template: "{template}", context: {ctx_var})')

        if has_multi_results:
            results_swift = "[" + ", ".join(f'"{escape_swift_string(r)}"' for r in test["results"]) + "]"
            lines.append(f"        let validResults: [String] = {results_swift}")
            lines.append(f'        #expect(validResults.contains(result), "Got \\(result)")')
        elif test.get("result") is not None:
            expected = escape_swift_string(test["result"])
            lines.append(f'        #expect(result == "{expected}")')

    lines.append("    }")
    return "\n".join(lines)


def generate_file(category: str, directory: str, tests: list) -> str:
    """Generate a complete Swift test file for a category."""
    struct_name = category_to_struct(category)
    suite_name = f"Golden: {category}"

    lines = []
    lines.append("//")
    lines.append(f"//  {category_to_filename(category)}")
    lines.append("//  GoldenLiquidTests")
    lines.append("//")
    lines.append("//  Auto-generated from golden_liquid.json — do not edit manually")
    lines.append("//  A high-performance Swift implementation of the Liquid template language")
    lines.append("//")
    lines.append("")
    lines.append("import Foundation")
    lines.append("import OrderedCollections")
    lines.append("import Testing")
    lines.append("@testable import RhoeLiquid")
    lines.append("")
    lines.append(f'@Suite("{suite_name}", .serialized)')
    lines.append(f"struct {struct_name} {{")

    # Track function names for dedup
    used_names = set()

    for test in tests:
        # Generate unique function name
        base_name = to_camel_case(test["name"].split(", ", 2)[-1] if ", " in test["name"] else test["name"])
        func_name = base_name
        counter = 2
        while func_name in used_names:
            func_name = f"{base_name}{counter}"
            counter += 1
        used_names.add(func_name)

        lines.append("")
        lines.append(generate_test_method(test, func_name))

    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def main():
    # Find project root
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    fixture_path = project_root / FIXTURE_PATH
    output_base = project_root / OUTPUT_BASE

    if not fixture_path.exists():
        print(f"Error: Fixture not found at {fixture_path}", file=sys.stderr)
        sys.exit(1)

    # Load fixture
    with open(fixture_path) as f:
        suite = json.load(f)

    tests = suite["tests"]
    print(f"Loaded {len(tests)} tests from {fixture_path.name}")

    # Group by category
    categories = defaultdict(list)
    for test in tests:
        category, directory = categorize_test(test)
        categories[(category, directory)].append(test)

    print(f"Found {len(categories)} categories")

    # Clean up old disabled files
    for subdir in ["Filters", "Tags", "Misc"]:
        dirpath = output_base / subdir
        if dirpath.exists():
            for f in dirpath.iterdir():
                if f.suffix in (".swift", ".disabled"):
                    f.unlink()

    # Generate files
    total_tests = 0
    for (category, directory), cat_tests in sorted(categories.items()):
        # Ensure directory exists
        dir_path = output_base / directory
        dir_path.mkdir(parents=True, exist_ok=True)

        # Generate file
        filename = category_to_filename(category)
        content = generate_file(category, directory, cat_tests)

        filepath = dir_path / filename
        filepath.write_text(content)

        total_tests += len(cat_tests)
        print(f"  {directory}/{filename}: {len(cat_tests)} tests")

    print(f"\nGenerated {len(categories)} files with {total_tests} tests total")


if __name__ == "__main__":
    main()
