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

extension Memory {
    /// Namespace for allocator-related types.
    public struct Allocator: Memory.Allocator.`Protocol`, Sendable {
        /// Creates a system allocator.
        public init() {}

        /// Allocates a region of the given size and alignment.
        ///
        /// - Parameters:
        ///   - count: The number of bytes to allocate.
        ///   - alignment: The required alignment of the allocation.
        /// - Returns: The address of the newly allocated region.
        /// - Throws: Never; the system allocator traps on exhaustion.
        @inlinable
        public func allocate(
            count: Memory.Address.Count,
            alignment: Memory.Alignment
        ) throws(Never) -> Memory.Address {
            unsafe Memory.Address(
                UnsafeMutableRawPointer.allocate(count: count, alignment: alignment)
            )
        }

        /// Deallocates a region previously returned by `allocate(count:alignment:)`.
        ///
        /// - Parameters:
        ///   - address: The address of the region to deallocate.
        ///   - count: The number of bytes originally allocated.
        ///   - alignment: The alignment the region was allocated with.
        @inlinable
        public func deallocate(
            _ address: Memory.Address,
            count: Memory.Address.Count,
            alignment: Memory.Alignment
        ) {
            // System allocator doesn't need count/alignment for deallocation
            unsafe UnsafeMutableRawPointer(address).deallocate()
        }
    }
}
