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

extension Memory.Pool {
    /// Errors that can occur during pool operations.
    public enum Error: Swift.Error, Equatable, Sendable {
        /// No free slots remain.
        case exhausted(capacity: Index<Slot>.Count)

        /// The slot size is too small to hold the in-band free list pointer.
        case slotSizeTooSmall(requested: Memory.Address.Count, minimum: Memory.Address.Count)

        /// The requested capacity is invalid (must be > 0).
        case invalidCapacity

        /// The pointer does not belong to this pool.
        case foreignPointer

        /// The slot has already been deallocated (double free).
        case doubleFree
    }
}
