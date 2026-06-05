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

public import Index_Primitives
public import Memory_Primitive
public import Memory_Tracked_Primitives

extension Memory.Allocatable {
    /// The allocatable-leaf capability: a `Memory.Tracked.`Protocol`` leaf backed by a
    /// single contiguous region it can ALLOCATE sized-to-request and BULK-RELOCATE.
    ///
    /// Leaf-tier replacement for `Store.Creatable.`Protocol`` (capability elimination,
    /// seat D2 2026-06-05). Because every conformer is a single contiguous region, the
    /// relocation witnesses are STATICALLY bulk — there is no element-wise fallback and
    /// no runtime override; a generic constrained `where M: Memory.Allocatable.`Protocol``
    /// selects the bulk path by construction.
    public protocol `Protocol`: Memory.Tracked.`Protocol`, ~Copyable {
        /// Allocates a leaf sized for at least `minimumCapacity` elements, empty.
        static func create(minimumCapacity: Index<Element>.Count) -> Self

        /// Bulk-relocates the initialized prefix `[0, count)` into `destination`,
        /// leaving the relocated source slots uninitialized.
        ///
        /// Correct for `~Copyable` elements (moves, not copies). The caller syncs the
        /// ledger.
        mutating func moveInitializePrefix(count: Index<Element>.Count, into destination: inout Self)

        /// Bulk-relocates the contiguous run `range` into `destination` starting at
        /// `destinationOffset` (linearizes a wrapped ring into a freshly grown peer).
        mutating func moveInitialize(
            range: Swift.Range<Index<Element>>,
            into destination: inout Self,
            at destinationOffset: Index<Element>
        )
    }
}
