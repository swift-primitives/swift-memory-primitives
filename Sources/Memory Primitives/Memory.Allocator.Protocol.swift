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

extension Memory.Allocator {
    /// Protocol for memory allocation strategies.
    ///
    /// Conforming types provide allocation and deallocation operations
    /// with customizable strategies (system, arena, pool, etc.).
    ///
    /// ## Alignment
    ///
    /// Both `allocate` and `deallocate` take alignment parameters.
    /// Some allocators need alignment info for deallocation (e.g., Windows `_aligned_free`).
    /// Allocators that don't need it can ignore the parameter.
    public protocol `Protocol`: ~Copyable {
        /// Error type for allocation failures.
        associatedtype Error: Swift.Error

        /// Allocates memory for the specified count and alignment.
        ///
        /// - Parameters:
        ///   - count: Number of bytes to allocate.
        ///   - alignment: Required alignment in bytes (must be power of 2).
        /// - Returns: A mutable address to the allocated memory.
        /// - Throws: `Error` if allocation fails.
        mutating func allocate(
            count: Memory.Address.Count,
            alignment: Memory.Address.Count
        ) throws(Error) -> Memory.Mutable.Address

        /// Deallocates previously allocated memory.
        ///
        /// - Parameters:
        ///   - address: The address to deallocate.
        ///   - count: The original allocation size.
        ///   - alignment: The original alignment (some allocators require this).
        mutating func deallocate(
            _ address: Memory.Mutable.Address,
            count: Memory.Address.Count,
            alignment: Memory.Address.Count
        )
    }
}
