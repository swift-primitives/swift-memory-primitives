// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-memory-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-memory-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Memory_Primitive
public import Store_Initialization_Primitives
public import Store_Protocol_Primitives

extension Memory.Tracked {
    /// The tracked-leaf ledger capability: a `Store.`Protocol`` element store that
    /// also maintains a leaf-private `Store.Initialization` ledger its OWN teardown
    /// (the cleanup oracle) honors.
    ///
    /// Narrow replacement for the eliminated universal `Store.Tracked.`Protocol``
    /// (capability elimination, seat D1-B 2026-06-05). The ledger requirement lives
    /// at the memory leaf, NOT as a universal store-tier refinement: only the
    /// self-cleaning leaves (`Memory.Heap` / `Memory.Inline` / `Memory.Small`) conform.
    /// `Storage.Contiguous` does NOT conform — it forwards the ledger conditionally
    /// (`extension Storage.Contiguous where Substrate: Memory.Tracked.`Protocol``).
    public protocol `Protocol`: Store.`Protocol`, ~Copyable {
        /// The range-tracked initialization view the leaf's OWN teardown honors.
        ///
        /// Disciplines composed above SYNC this (`storage.initialization = …`) before
        /// release; the leaf's `deinit` (the cleanup oracle) HONORS it. Stores whose
        /// teardown is not range-driven vend an explicit `.empty`.
        var initialization: Store.Initialization<Element> { get set }
    }
}
