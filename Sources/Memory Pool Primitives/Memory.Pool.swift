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
    /// - Slot size ≥ `MemoryLayout<Index<Slot>>.size` (in-band free list storage)
    /// - Slot alignment is power of 2
    /// - Capacity is fixed at construction, immutable
    /// - `0 ≤ allocated ≤ capacity`
    /// - Free list is acyclic and contained within `[0, capacity)`
    /// - Every address returned by `allocate()` belongs to this pool's backing buffer
    ///
    /// ## Free List Design
    ///
    /// Free slots store the `Index<Slot>` of the next free slot in-band (at the
    /// slot's own memory location) via `storeBytes(of:as:)` / `load(as:)`. The
    /// sentinel value `_sentinel` (one-past-last, analogous to `endIndex`) marks
    /// end-of-list. No raw value extraction is needed — the typed index flows
    /// directly through memory operations.
    ///
    /// A separate `Bit.Vector` tracks which slots are allocated, enabling correct
    /// double-free detection even when consumers store typed content in allocated
    /// slots.
    ///
    /// ## Typed Access
    ///
    /// Pool operates on untyped bytes. Typed access is composed at the call site:
    ///
    /// ```swift
    /// var pool = try Memory.Pool(slotSize: ..., slotAlignment: ..., capacity: ...)
    /// let address = try pool.allocate()
    /// let pointer = address.assumingMemoryBound(to: Node.self)
    /// pointer.initialize(to: node)
    /// // ... use ...
    /// _ = pointer.move()
    /// try pool.deallocate(address)
    /// ```
    @safe
    public struct Pool: ~Copyable {

        // MARK: - Phantom Type

        /// Phantom type for slot-level indexing within a pool.
        public enum Slot {}

        // MARK: - Stored Properties

        /// Backing storage for all slots.
        @usableFromInline
        internal let _storage: UnsafeMutableRawPointer

        /// Scaling factor from slot domain to byte domain.
        @usableFromInline
        internal let _slotStride: Affine.Discrete.Ratio<Slot, Memory>

        /// Total number of slots.
        @usableFromInline
        internal let _capacity: Index<Slot>.Count

        /// Number of currently allocated (in-use) slots.
        @usableFromInline
        internal var _allocated: Index<Slot>.Count

        /// Head of the free list. Equal to `_sentinel` when exhausted.
        ///
        /// This is a typed `Index<Slot>`, not an Optional. The sentinel
        /// value (`_capacity.map(Ordinal.init)`, one-past-last) represents
        /// end-of-list — analogous to `endIndex` in Swift collections.
        @usableFromInline
        internal var _freeHead: Index<Slot>

        /// Tracks which slots are currently allocated for double-free detection.
        @usableFromInline
        internal var _allocationBits: Bit.Vector

        /// Creates a pool with the specified slot geometry and capacity.
        ///
        /// - Parameters:
        ///   - slotSize: Size of each slot in bytes. Must be ≥ `MemoryLayout<Index<Slot>>.size`.
        ///   - slotAlignment: Required alignment per slot.
        ///   - capacity: Number of slots. Must be > 0.
        /// - Throws: `Pool.Error` if parameters are invalid.
        @inlinable
        public init(
            slotSize: Memory.Address.Count,
            slotAlignment: Memory.Alignment,
            capacity: Index<Slot>.Count
        ) throws(Pool.Error) {
            guard capacity > .zero else {
                throw .invalidCapacity
            }

            let minimumSlotSize = Memory.Address.Count(UInt(MemoryLayout<UInt>.size))
            guard slotSize >= minimumSlotSize else {
                throw .slotSizeTooSmall(
                    requested: slotSize,
                    minimum: minimumSlotSize
                )
            }

            // Compute stride: round slotSize up to alignment boundary
            let alignedSize = slotAlignment.align.up(slotSize)
            let stride = Affine.Discrete.Ratio<Slot, Memory>(alignedSize)

            self._slotStride = stride
            self._capacity = capacity
            self._allocated = .zero
            self._allocationBits = Bit.Vector(
                capacity: capacity.retag(Bit.self)
            )

            // Allocate backing storage
            let totalBytes = capacity * stride
            let storage = unsafe UnsafeMutableRawPointer.allocate(
                count: totalBytes,
                alignment: slotAlignment
            )
            unsafe self._storage = storage

            // All properties initialized — build the free list.
            let sentinel = capacity.map(Ordinal.init)
            self._freeHead = .zero
            var slot: Index<Slot> = .zero
            while slot < sentinel {
                let next = slot + .one
                unsafe _pointer(at: slot).storeBytes(
                    of: (next < sentinel) ? next : sentinel,
                    as: Index<Slot>.self
                )
                slot += .one
            }
        }

        deinit {
            unsafe _storage.deallocate()
        }
    }
}

// MARK: - Pointer Primitive

extension Memory.Pool {
    /// Returns the pointer to the slot at the given index (no bounds check).
    @inlinable
    internal func _pointer(at index: Index<Slot>) -> UnsafeMutableRawPointer {
        let byteOffset = Index<Slot>.Offset(fromZero: index) * _slotStride
        return unsafe _storage.advanced(by: byteOffset)
    }
}

// MARK: - Free List Sentinel

extension Memory.Pool {
    /// The end-of-list sentinel: one-past-last valid slot index.
    ///
    /// Analogous to `endIndex` in Swift collections. A free list link
    /// equal to the sentinel means "no next free slot." Derived from
    /// capacity — not an arbitrary magic constant.
    @inlinable
    internal var _sentinel: Index<Slot> { _capacity.map(Ordinal.init) }
}

// MARK: - Properties

extension Memory.Pool {
    /// Total number of slots.
    @inlinable
    public var capacity: Index<Slot>.Count { _capacity }

    /// Number of currently allocated (in-use) slots.
    @inlinable
    public var allocated: Index<Slot>.Count { _allocated }

    /// Number of free slots remaining.
    @inlinable
    public var available: Index<Slot>.Count {
        _capacity.subtract.saturating(_allocated)
    }

    /// Scaling factor from slot domain to byte domain (stride-aligned).
    @inlinable
    public var slotStride: Affine.Discrete.Ratio<Slot, Memory> { _slotStride }

    /// Whether all slots are allocated (no free slots remain).
    @inlinable
    public var isExhausted: Bool { _freeHead == _sentinel }
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
        guard _freeHead != _sentinel else {
            throw .exhausted(capacity: _capacity)
        }

        let head = _freeHead

        // Advance free list head: load the typed next-free index directly.
        _freeHead = unsafe _pointer(at: head).load(as: Index<Slot>.self)

        // Mark slot as allocated.
        _allocationBits[head.retag(Bit.self)] = true
        _allocated += .one

        return unsafe _pointer(at: head)
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
        guard let slot = unsafe slotIndex(for: pointer) else {
            throw .foreignPointer
        }

        // Double-free detection via allocation bitset.
        let bitIndex = slot.retag(Bit.self)
        guard _allocationBits[bitIndex] else {
            throw .doubleFree
        }

        // Push current head into this slot's memory, then make this slot the new head.
        _allocationBits[bitIndex] = false
        unsafe _pointer(at: slot).storeBytes(of: _freeHead, as: Index<Slot>.self)
        _freeHead = slot
        _allocated = _allocated.subtract.saturating(.one)
    }

    /// Returns all slots to the free list.
    ///
    /// - Warning: All previously returned pointers become invalid.
    ///   The caller MUST deinitialize any typed content in all allocated
    ///   slots before calling this method.
    /// - Complexity: O(n) where n is capacity.
    @inlinable
    public mutating func reset() {
        let sentinel = _sentinel
        var slot: Index<Slot> = .zero
        while slot < sentinel {
            let next = slot + .one
            unsafe _pointer(at: slot).storeBytes(
                of: (next < sentinel) ? next : sentinel,
                as: Index<Slot>.self
            )
            slot += .one
        }
        _freeHead = .zero
        _allocated = .zero
        _allocationBits.clear.all()
    }
}

// MARK: - Slot Address Queries

extension Memory.Pool {
    /// Returns the pointer to the slot at the given index.
    ///
    /// - Parameter index: A slot index. Must be < capacity.
    /// - Returns: Pointer to the slot's memory.
    /// - Precondition: `index < capacity`
    @inlinable
    public func pointer(at index: Index<Slot>) -> UnsafeMutableRawPointer {
        precondition(index < _capacity, "Slot index out of bounds")
        return unsafe _pointer(at: index)
    }

    /// Returns the slot index for a pointer previously returned by `allocate()`.
    ///
    /// - Parameter pointer: A pointer belonging to this pool.
    /// - Returns: The slot index, or `nil` if the pointer is foreign.
    @inlinable
    public func slotIndex(for pointer: UnsafeMutableRawPointer) -> Index<Slot>? {
        let rawOffset = unsafe pointer - _storage
        guard rawOffset >= 0 else { return nil }

        let byteCount = Memory.Address.Count(UInt(rawOffset))
        let totalBytes = _capacity * _slotStride
        guard byteCount < totalBytes else { return nil }

        let (slotCount, remainder) = _slotStride.quotientAndRemainder(dividing: byteCount)
        guard remainder == .zero else { return nil }

        return slotCount.map(Ordinal.init)
    }
}

// MARK: - Sendable

extension Memory.Pool: @unchecked Sendable {}
