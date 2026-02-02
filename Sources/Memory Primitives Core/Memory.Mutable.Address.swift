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

extension Memory.Mutable {
    /// A mutable memory address.
    ///
    /// `Memory.Mutable.Address` has the same underlying representation as
    /// `Memory.Address` (an ordinal position in memory), but carries type-level
    /// information that permits mutation operations.
    ///
    /// For operations that read or write memory, use this type. For operations
    /// that only need a position (e.g., arithmetic), use `Memory.Address`.
    public typealias Address = Tagged<Memory.Mutable, Ordinal>
}
