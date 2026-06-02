//
//  FilterRegistry.swift
//  LiquidFilters
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation
import LiquidCore

/// Registry for built-in and custom filters
///
/// `FilterRegistry` stores registry-backed filters that are injected through
/// ``LiquidEngine`` at runtime. Core hot-path filters remain implemented directly
/// inside `Renderer`, while this registry handles caller-provided filters and
/// supplemental filters that do not justify a dedicated fast path.
public actor FilterRegistry {
    private var filters: [String: any CustomFilter]

    public init(filters: [String: any CustomFilter] = [:]) {
        self.filters = filters
    }

    /// Register or replace a filter by name.
    public func register(name: String, filter: any CustomFilter) {
        filters[name] = filter
    }

    /// Remove a registered filter.
    public func unregister(name: String) {
        filters.removeValue(forKey: name)
    }

    /// Returns `true` when the registry contains the named filter.
    public func hasFilter(_ name: String) -> Bool {
        filters[name] != nil
    }

    /// Look up a filter by name.
    public func getFilter(_ name: String) -> (any CustomFilter)? {
        filters[name]
    }

    /// Get all registry-backed filters.
    public func getAllFilters() -> [String: any CustomFilter] {
        filters
    }
}
