# Architecture Notes

The canonical architecture guide for the active package lives in:

- `../Sources/RhoeLiquid/Documentation.docc/Architecture.md`

## Short Version

`RhoeLiquid` is organized around a focused pipeline:

1. `LiquidLexer` tokenizes template source.
2. `LiquidParser` builds AST nodes and expressions.
3. `LiquidRenderer` executes the AST.
4. `OptimizedRenderer` layers compiled-template reuse, renderer pooling, and cache statistics on top.
5. `LiquidEngine` coordinates caching, data loader registration, memory-pressure handling, and the public API.

## Current Architectural Watchpoints

- the live custom-tag surface now runs end-to-end through `LiquidTags`, but the older `LiquidCore` custom-tag protocols still need cleanup or deprecation planning

See `../README.md` for the current repo boundary and downstream integration notes.
