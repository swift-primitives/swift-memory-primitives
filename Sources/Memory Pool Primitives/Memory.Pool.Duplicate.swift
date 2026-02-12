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
    /// Creates a deep copy of this pool's backing storage.
    ///
    /// Iterates slots below `_nextUnused`:
    /// - Allocated slots: calls `copySlotContents` with (source, destination) raw pointers
    /// - Freed slots: raw-copies the in-band free list link bytes
    ///
    /// The caller is responsible for performing type-correct copies via the closure.
    ///
    /// - Parameter copySlotContents: Closure called for each allocated slot.
    ///   Receives (source, destination) raw pointers. The closure must copy
    ///   the typed content from source to destination.
    /// - Returns: A new pool with identical slot layout and allocation state.
    @inlinable
    public func duplicate(
        copySlotContents: (
            _ source: UnsafeMutableRawPointer,
            _ destination: UnsafeMutableRawPointer
        ) -> Void
    ) -> Memory.Pool {
        // Allocate new backing storage with same geometry.
        let newStorage = unsafe UnsafeMutableRawPointer.allocate(
            count: _capacity * _slotStride,
            alignment: _slotAlignment
        )

        // Copy used region (bounded by virgin cursor).
        var slot: Index<Slot> = .zero
        while slot < _nextUnused {
            let srcPointer = unsafe _pointer(at: slot)
            let dstPointer = unsafe newStorage.advanced(
                by: Index<Slot>.Offset(fromZero: slot) * _slotStride
            )

            if _allocationBits[slot.retag(Bit.self)] {
                // Allocated slot: call closure for type-correct copy.
                unsafe copySlotContents(srcPointer, dstPointer)
            } else {
                // Freed slot: raw-copy the in-band free list link.
                unsafe dstPointer.storeBytes(
                    of: srcPointer.load(as: Index<Slot>.self),
                    as: Index<Slot>.self
                )
            }
            slot = slot + .one
        }

        // Duplicate allocation bits.
        let newBits = Bit.Vector(capacity: _capacity.retag(Bit.self))
        unsafe _allocationBits.withUnsafeWords { srcWords in
            unsafe newBits.withUnsafeMutableWords { dstWords in
                for i in 0..<srcWords.count {
                    unsafe dstWords[i] = srcWords[i]
                }
            }
        }

        return unsafe Memory.Pool(
            _copying: newStorage,
            slotStride: _slotStride,
            slotAlignment: _slotAlignment,
            capacity: _capacity,
            allocated: _allocated,
            freeHead: _freeHead,
            nextUnused: _nextUnused,
            allocationBits: newBits
        )
    }
}
