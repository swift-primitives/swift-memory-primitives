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
    /// A fixed-slot allocator with O(1) allocate and deallocate via in-band free list.
    ///
    /// Pool allocation provides:
    /// - O(1) allocation (pop from free list)
    /// - O(1) deallocation (push to free list)
    /// - Per-slot reuse (unlike Arena, which only supports bulk reset)
    /// - Zero fragmentation (all slots are the same size)
    ///
    /// ## Invariants
    ///
    /// - Slot size ≥ `MemoryLayout<Int>.size` (in-band free list storage)
    /// - Slot alignment is power of 2
    /// - Capacity is fixed at construction, immutable
    /// - `0 ≤ allocated ≤ capacity`
    /// - Free list is acyclic and contained within `[0, capacity)`
    /// - Every address returned by `allocate()` belongs to this pool's backing buffer
    ///
    /// ## Free List Design
    ///
    /// Free slots store the index of the next free slot in-band (at the slot's own
    /// memory location). This is the canonical Bonwick slab allocator technique:
    /// zero auxiliary storage overhead. A separate `Bit.Vector` tracks which slots
    /// are allocated, enabling correct double-free detection even when consumers
    /// store typed content in allocated slots.
    ///
    /// ## Typed Access
    ///
    /// Pool operates on untyped bytes. Typed access is composed at the call site:
    ///
    /// ```swift
    /// var pool = try Memory.Pool(slotSize: ..., slotAlignment: ..., capacity: 1024)
    /// let address = try pool.allocate()
    /// let pointer = address.assumingMemoryBound(to: Node.self)
    /// pointer.initialize(to: node)
    /// // ... use ...
    /// _ = pointer.move()
    /// try pool.deallocate(address)
    /// ```
    @safe
    public struct Pool: ~Copyable {
        /// Backing storage for all slots.
        @usableFromInline
        internal let _storage: UnsafeMutableRawPointer

        /// Number of bytes per slot (stride-aligned).
        @usableFromInline
        internal let _slotStride: Int

        /// Total number of slots.
        @usableFromInline
        internal let _capacity: Int

        /// Number of currently allocated (in-use) slots.
        @usableFromInline
        internal var _allocated: Int

        /// Index of the first free slot, or `-1` if exhausted.
        @usableFromInline
        internal var _freeHead: Int

        /// Tracks which slots are currently allocated for double-free detection.
        @usableFromInline
        internal var _allocationBits: Bit.Vector

        /// Creates a pool with the specified slot geometry and capacity.
        ///
        /// - Parameters:
        ///   - slotSize: Size of each slot in bytes. Must be ≥ `MemoryLayout<Int>.size`.
        ///   - slotAlignment: Required alignment per slot.
        ///   - capacity: Number of slots. Must be > 0.
        /// - Throws: `Pool.Error` if parameters are invalid.
        @inlinable
        public init(
            slotSize: Memory.Address.Count,
            slotAlignment: Memory.Alignment,
            capacity: Int
        ) throws(Pool.Error) {
            guard capacity > 0 else {
                throw .invalidCapacity
            }

            let minimumSlotSize = MemoryLayout<Int>.size
            guard Int(bitPattern: slotSize.count) >= minimumSlotSize else {
                throw .slotSizeTooSmall(
                    requested: Int(bitPattern: slotSize.count),
                    minimum: minimumSlotSize
                )
            }

            // Compute stride: round slotSize up to alignment boundary
            let stride = Int(bitPattern: slotAlignment.align.up(slotSize).count)

            self._slotStride = stride
            self._capacity = capacity
            self._allocated = 0
            self._allocationBits = Bit.Vector(
                capacity: Bit.Index.Count(Cardinal(UInt(capacity)))
            )

            // Allocate backing storage
            let totalBytes = stride &* capacity
            let storage = UnsafeMutableRawPointer.allocate(
                byteCount: totalBytes,
                alignment: slotAlignment.magnitude()
            )
            unsafe self._storage = storage

            // Initialize free list: each slot stores the index of the next free slot.
            // Slot 0 → 1, Slot 1 → 2, ..., Slot (N-2) → (N-1), Slot (N-1) → -1 (end).
            for i in 0..<capacity {
                let slotPointer = unsafe storage.advanced(by: i &* stride)
                let nextFree = (i &+ 1 < capacity) ? (i &+ 1) : -1
                unsafe slotPointer.storeBytes(of: nextFree, as: Int.self)
            }
            self._freeHead = 0
        }

        deinit {
            unsafe _storage.deallocate()
        }
    }
}

// MARK: - Properties

extension Memory.Pool {
    /// Total number of slots.
    @inlinable
    public var capacity: Int { _capacity }

    /// Number of currently allocated (in-use) slots.
    @inlinable
    public var allocated: Int { _allocated }

    /// Number of free slots remaining.
    @inlinable
    public var available: Int { _capacity &- _allocated }

    /// Size of each slot in bytes (stride-aligned).
    @inlinable
    public var slotStride: Int { _slotStride }

    /// Whether all slots are allocated (no free slots remain).
    @inlinable
    public var isExhausted: Bool { _freeHead == -1 }
}

// MARK: - Operations

extension Memory.Pool {
    /// Allocates a slot and returns a pointer to its memory.
    ///
    /// The returned pointer addresses `slotStride` bytes of uninitialized memory.
    /// The caller is responsible for initializing the memory before use and
    /// deinitializing it before calling `deallocate`.
    ///
    /// - Returns: Mutable raw pointer to the allocated slot.
    /// - Throws: `.exhausted` if no free slots remain.
    /// - Complexity: O(1)
    @inlinable
    public mutating func allocate() throws(Memory.Pool.Error) -> UnsafeMutableRawPointer {
        guard _freeHead != -1 else {
            throw .exhausted(capacity: _capacity)
        }

        let slotIndex = _freeHead
        let slotPointer = unsafe _storage.advanced(by: slotIndex &* _slotStride)

        // Read next-free from this slot before we hand it to the consumer.
        let nextFree = unsafe slotPointer.load(as: Int.self)
        _freeHead = nextFree

        // Mark slot as allocated in the bitset.
        _allocationBits[Bit.Index(Ordinal(UInt(slotIndex)))] = true

        _allocated &+= 1

        return unsafe slotPointer
    }

    /// Returns a slot to the free list.
    ///
    /// The caller MUST deinitialize any typed content stored in the slot
    /// before calling this method.
    ///
    /// - Parameter pointer: A pointer previously returned by `allocate()`.
    /// - Throws: `.foreignPointer` if the pointer does not belong to this pool.
    ///           `.doubleFree` if the slot is already free.
    /// - Complexity: O(1)
    @inlinable
    public mutating func deallocate(
        _ pointer: UnsafeMutableRawPointer
    ) throws(Memory.Pool.Error) {
        // Validate: pointer must be within our backing storage range.
        let offset = unsafe pointer - _storage
        guard offset >= 0 else {
            throw .foreignPointer
        }

        let totalBytes = _slotStride &* _capacity
        guard offset < totalBytes else {
            throw .foreignPointer
        }

        // Validate: pointer must be slot-aligned (exact slot boundary).
        guard offset % _slotStride == 0 else {
            throw .foreignPointer
        }

        // Double-free detection via allocation bitset.
        let slotIndex = offset / _slotStride
        let bitIndex = Bit.Index(Ordinal(UInt(slotIndex)))
        guard _allocationBits[bitIndex] else {
            throw .doubleFree
        }

        // Mark slot as free in the bitset.
        _allocationBits[bitIndex] = false

        // Push onto free list: store current head, then update head.
        unsafe pointer.storeBytes(of: _freeHead, as: Int.self)
        _freeHead = slotIndex

        _allocated &-= 1
    }

    /// Returns all slots to the free list.
    ///
    /// - Warning: All previously returned pointers become invalid.
    ///   The caller MUST deinitialize any typed content in all allocated
    ///   slots before calling this method.
    /// - Complexity: O(n) where n is capacity.
    @inlinable
    public mutating func reset() {
        for i in 0..<_capacity {
            let slotPointer = unsafe _storage.advanced(by: i &* _slotStride)
            let nextFree = (i &+ 1 < _capacity) ? (i &+ 1) : -1
            unsafe slotPointer.storeBytes(of: nextFree, as: Int.self)
        }
        _freeHead = 0
        _allocated = 0
        _allocationBits.clear.all()
    }
}

// MARK: - Slot Address Queries

extension Memory.Pool {
    /// Returns the pointer to the slot at the given index.
    ///
    /// - Parameter index: Slot index in `0..<capacity`.
    /// - Returns: Pointer to the slot's memory.
    /// - Precondition: `index >= 0 && index < capacity`
    @inlinable
    public func pointer(at index: Int) -> UnsafeMutableRawPointer {
        precondition(index >= 0 && index < _capacity, "Slot index out of bounds")
        return unsafe _storage.advanced(by: index &* _slotStride)
    }

    /// Returns the slot index for a pointer previously returned by `allocate()`.
    ///
    /// - Parameter pointer: A pointer belonging to this pool.
    /// - Returns: The slot index, or `nil` if the pointer is foreign.
    @inlinable
    public func slotIndex(for pointer: UnsafeMutableRawPointer) -> Int? {
        let offset = unsafe pointer - _storage
        guard offset >= 0, offset < _slotStride &* _capacity else {
            return nil
        }
        guard offset % _slotStride == 0 else {
            return nil
        }
        return offset / _slotStride
    }
}

// MARK: - Sendable

extension Memory.Pool: @unchecked Sendable {}
