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
    /// - `_buffer.start` is always non-null (sentinel-backed)
    @safe
    public struct Arena: ~Copyable {
        /// The backing storage.
        @usableFromInline
        internal var _buffer: Buffer.Mutable

        /// Bytes currently allocated from the buffer.
        @usableFromInline
        internal var _allocated: Memory.Address.Count

        /// Creates an arena with the specified capacity.
        ///
        /// - Parameter capacity: Total capacity in bytes. Must be > 0.
        /// - Precondition: `capacity > .zero`
        @inlinable
        public init(capacity: Memory.Address.Count) {
            precondition(capacity > .zero, "Arena capacity must be > 0")

            self._buffer = Buffer.Mutable.allocate(
                count: capacity,
                alignment: Memory.Address.Count(UInt(MemoryLayout<Int>.alignment))
            )
            self._allocated = .zero
        }

        deinit {
            _buffer.deallocate()
        }
    }
}

// MARK: - Properties

extension Memory.Arena {
    /// The total capacity in bytes.
    @inlinable
    public var capacity: Memory.Address.Count { _buffer.count }

    /// The number of bytes currently allocated.
    @inlinable
    public var allocated: Memory.Address.Count { _allocated }

    /// The number of bytes remaining.
    @inlinable
    public var remaining: Memory.Address.Count {
        Memory.Address.Count(capacity.count.subtract.saturating(_allocated.count))
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
    ///   - alignment: Required alignment (must be power of 2).
    /// - Returns: Address to allocated memory, or nil if insufficient space.
    @inlinable
    public mutating func allocate(
        count: Memory.Address.Count,
        alignment: Memory.Address.Count
    ) -> Memory.Mutable.Address? {
        // Use rawValue (UInt) for bitwise alignment operations
        let alignValue = alignment.count.rawValue
        precondition(alignValue > 0 && (alignValue & (alignValue - 1)) == 0,
                     "Alignment must be power of 2")

        // Round up allocated to alignment boundary
        let alignMask = alignValue &- 1
        let alignedAllocated = (_allocated.count.rawValue &+ alignMask) & ~alignMask

        // Check if allocation fits (overflow-safe: use saturating add then compare)
        let (endAllocated, overflow) = alignedAllocated.addingReportingOverflow(count.count.rawValue)
        guard !overflow, endAllocated <= capacity.count.rawValue else {
            return nil
        }

        // Update allocated count
        _allocated = Memory.Address.Count(Cardinal(endAllocated))

        // Return the allocated address
        // Convert Count to Offset at boundary for pointer arithmetic
        return _buffer.start + .init(alignedAllocated)
    }
}

// MARK: - Sendable

extension Memory.Arena: @unchecked Sendable {}
