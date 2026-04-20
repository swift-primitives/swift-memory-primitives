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

// MARK: - Slot Property Accessor

extension Memory.Pool {
    /// Read-only slot-level properties.
    ///
    /// Provides namespaced access to per-slot geometry:
    /// - `pool.slot.stride` — scaling factor from slot domain to byte domain
    /// - `pool.slot.alignment` — alignment requirement for each slot
    @inlinable
    public var slot: Property<Slot, Self>.View.Read {
        _read {
            yield Property<Slot, Self>.View.Read(self)
        }
    }
}

// MARK: - Slot Property.View.Read Extensions

extension Property.View.Read where Tag == Memory.Pool.Slot, Base == Memory.Pool {
    /// Scaling factor from slot domain to byte domain (stride-aligned).
    @inlinable
    public var stride: Affine.Discrete.Ratio<Memory.Pool.Slot, Memory> {
        unsafe base.pointee._slotStride
    }

    /// Alignment requirement for each slot.
    @inlinable
    public var alignment: Memory.Alignment {
        unsafe base.pointee._slotAlignment
    }
}
