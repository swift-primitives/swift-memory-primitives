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

extension Memory.Unique {
    /// The copy-on-write uniqueness capability: a value-type façade that can check
    /// whether it solely owns its (potentially shared) backing and, when shared,
    /// restore value semantics by deep-copying its live extent.
    ///
    /// Conformed by the SHARING memory leaves only — `Memory.Heap` (ARC class
    /// backing) where its elements are `Copyable`. Value-type leaves never share and
    /// do NOT conform; `~Copyable`-element leaves are statically unique and have no
    /// CoW surface. `Storage.Contiguous` forwards the capability conditionally
    /// (`where Substrate: Memory.Unique.`Protocol``). The deep-copy reads the
    /// leaf-private initialization ledger, preserving disjoint (`.two`) ring extents.
    public protocol `Protocol` {
        /// Whether this façade is the sole owner of its backing.
        var isUnique: Bool { mutating get }

        /// Ensures sole ownership, deep-copying the initialized extent into a fresh
        /// backing when shared. Returns whether a copy was made.
        @discardableResult
        mutating func ensureUnique() -> Bool
    }
}
