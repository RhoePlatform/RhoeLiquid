# Language Surface Manifest

The machine-readable language reference lives at:

```text
Documentation/LanguageReference/rhoe-liquid-language-surface.json
```

## Purpose

The manifest is the drift guard for this reference. It lists the documented tags, filters, operators, types, runtime profiles, status labels, and DocC pages that make up the `0.1.0` public language surface.

The validator at `Scripts/CI/validate-language-reference.sh` checks that:

- every public status label uses the approved vocabulary;
- every manifest entry points at an existing DocC page;
- the root DocC catalog links to `<doc:LanguageReference>`;
- `builtInTagNames` and `builtInFilterNames` from `LiquidCore.swift` are represented;
- known default registry filters, data filters, archived tags, unsupported fixtures, and Rhoe extension tags are represented.

## Authoring Rule

When a tag, filter, operator, type, profile, or extension status changes, update three places in the same pull request:

1. the compiler/runtime implementation or tests;
2. the DocC reference page;
3. the language-surface manifest.

The release candidate should not pass if those three sources drift apart.
