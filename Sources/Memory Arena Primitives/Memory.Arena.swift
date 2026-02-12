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
    /// A bump allocator for batch allocations.
    ///
    /// Arena allocation provides:
    /// - O(1) allocation (bump pointer)
    /// - No individual deallocation overhead
    /// - Single bulk deallocation via `reset()`
    ///
    /// ## Invariants
    ///
    /// - Capacity is always > 0 (enforced at construction)
    /// - `_storage` is always non-null
    @safe
    public struct Arena: ~Copyable {
        /// The backing storage.
        @usableFromInline
        internal let _storage: UnsafeMutableRawPointer

        /// Total capacity in bytes.
        @usableFromInline
        internal let _capacity: Memory.Address.Count

        /// Bytes currently allocated from the buffer.
        @usableFromInline
        internal var _allocated: Memory.Address.Count

        /// Creates an arena with the specified capacity.
        ///
        /// - Parameter capacity: Total capacity in bytes. Must be > 0.
        /// - Precondition: `capacity > .zero`
        @inlinable
        public init(capacity: Memory.Address.Count) {
            unsafe self._storage = UnsafeMutableRawPointer.allocate(
                count: capacity,
                alignment: .`8`
            )
            self._capacity = capacity
            self._allocated = .zero
        }

        deinit {
            unsafe _storage.deallocate()
        }
    }
}

// MARK: - Properties

extension Memory.Arena {
    /// The start address of the arena's backing storage.
    ///
    /// Storage.Arena uses this to compute typed pointers from slot indices.
    @inlinable
    public var start: UnsafeMutableRawPointer { unsafe _storage }

    /// The base address of the arena's backing storage.
    @available(*, deprecated, renamed: "start")
    @inlinable
    public var baseAddress: UnsafeMutableRawPointer { unsafe _storage }

    /// The total capacity in bytes.
    @inlinable
    public var capacity: Memory.Address.Count { _capacity }

    /// The number of bytes currently allocated.
    @inlinable
    public var allocated: Memory.Address.Count { _allocated }

    /// The number of bytes remaining.
    @inlinable
    public var remaining: Memory.Address.Count {
        _capacity.subtract.saturating(_allocated)
    }
}

// MARK: - Operations

extension Memory.Arena {
    /// Resets the arena, invalidating all previous allocations.
    ///
    /// - Warning: All pointers from this arena become invalid.
    @inlinable
    public mutating func reset() {
        _allocated = .zero
    }

    /// Allocates memory from the arena.
    ///
    /// - Parameters:
    ///   - count: Number of bytes to allocate.
    ///   - alignment: Required alignment (power of 2).
    /// - Returns: Address to allocated memory, or nil if insufficient space.
    @inlinable
    public mutating func allocate(
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) -> Memory.Address? {
        // Round up allocated to alignment boundary
        let alignedAllocated = alignment.align.up(_allocated)

        // Check if allocation fits (overflow-safe)
        guard let endAllocated = try? alignedAllocated.add.exact(count),
              endAllocated <= _capacity else {
            return nil
        }

        // Update allocated count
        _allocated = endAllocated

        // Return the allocated address
        return unsafe Memory.Address(
            _storage.advanced(by: Memory.Address.Offset(alignedAllocated))
        )
    }
}

// MARK: - Sendable

extension Memory.Arena: @unchecked Sendable {}
