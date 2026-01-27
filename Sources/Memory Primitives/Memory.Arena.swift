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
        internal var _buffer: Address.Buffer.Mutable

        /// Current allocation offset.
        @usableFromInline
        internal var _offset: Index<UInt8>.Offset

        /// Creates an arena with the specified capacity.
        ///
        /// - Parameter capacity: Total capacity in bytes. Must be > 0.
        /// - Precondition: `capacity.count.rawValue > 0`
        @inlinable
        public init(capacity: Index<UInt8>.Count) {
            precondition(capacity.count.rawValue > 0, "Arena capacity must be > 0")

            self._buffer = Address.Buffer.Mutable.allocate(
                count: capacity,
                alignment: Index<UInt8>.Count(UInt(MemoryLayout<Int>.alignment))
            )
            self._offset = .zero
        }

        deinit {
            _buffer.deallocate()
        }

        /// The total capacity in bytes.
        @inlinable
        public var capacity: Index<UInt8>.Count { _buffer.count }

        /// The number of bytes currently allocated.
        @inlinable
        public var allocated: Index<UInt8>.Count {
            Index<UInt8>.Count(UInt(_offset.vector.rawValue))
        }

        /// The number of bytes remaining.
        @inlinable
        public var remaining: Index<UInt8>.Count {
            Index<UInt8>.Count(UInt(Int(capacity.count.rawValue) - _offset.vector.rawValue))
        }

        /// Resets the arena, invalidating all previous allocations.
        ///
        /// - Warning: All pointers from this arena become invalid.
        @inlinable
        public mutating func reset() {
            _offset = .zero
        }

        /// Allocates memory from the arena.
        ///
        /// - Parameters:
        ///   - count: Number of bytes to allocate.
        ///   - alignment: Required alignment (must be power of 2).
        /// - Returns: Address to allocated memory, or nil if insufficient space.
        @inlinable
        public mutating func allocate(
            count: Index<UInt8>.Count,
            alignment: Index<UInt8>.Count
        ) -> Address.Mutable? {
            // Alignment must be power of 2
            let alignValue = Int(alignment.count.rawValue)
            precondition(alignValue > 0 && (alignValue & (alignValue - 1)) == 0,
                         "Alignment must be power of 2")

            // Align the current offset
            let alignMask = alignValue - 1
            let alignedOffset = (_offset.vector.rawValue + alignMask) & ~alignMask

            // Check if allocation fits
            let endOffset = alignedOffset + Int(count.count.rawValue)
            guard endOffset <= Int(capacity.count.rawValue) else {
                return nil
            }

            // Bump the pointer
            _offset = Index<UInt8>.Offset(endOffset)

            // Return the allocated address (_buffer.start is guaranteed non-null)
            return _buffer.start.advanced(by: Index<UInt8>.Offset(alignedOffset))
        }
    }
}

extension Memory.Arena: @unchecked Sendable {}
