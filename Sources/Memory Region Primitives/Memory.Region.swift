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

public import Memory_Address_Primitives
public import Memory_Primitive

extension Memory {
    /// The raw byte resource seam: a located run of raw bytes (`base` + `capacity` only).
    ///
    /// `Memory.Region` is **NOT** region-based allocation and **NOT** an arena; it is the *resource*
    /// that allocation disciplines (`Memory.Allocator<Resource>.Arena` / `.Pool`) operate over. It is
    /// the load-bearing constraint that lets one allocator body run over structurally-different raw
    /// regions — `Memory.Heap` (heap allocation) and `Memory.Inline` (fixed inline bytes) — both of
    /// which expose exactly a base address and a byte capacity.
    ///
    /// ## Invariant (load-bearing)
    ///
    /// A `Memory.Region` exposes `base` + `capacity` **only**. It MUST NOT expose an element
    /// type, slot identity, initialization state, collection count, storage layout, or any allocator
    /// discipline — those are higher-tier concerns (the allocator carves slot identity; Storage lifts
    /// typed `Index<Element>` and the initialization ledger). Keeping the seam to base + size keeps it
    /// at the Memory layer (Non-Collapse): typed/element concerns never leak down into the raw region.
    ///
    /// Conformers: `Memory.Heap`, `Memory.Inline`. Bound: `Memory.Allocator<Resource> where Resource:
    /// Memory.Region & ~Copyable`.
    public protocol Region: ~Copyable {
        /// The stable base address of the region's first byte.
        ///
        /// Valid for the region's lifetime.
        var base: Memory.Address { get }

        /// The region's capacity in bytes.
        var capacity: Memory.Address.Count { get }
    }
}
