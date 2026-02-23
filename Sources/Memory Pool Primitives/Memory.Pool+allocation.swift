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

// MARK: - Allocation Property Accessor

extension Memory.Pool {
    /// Read-only allocation-level properties.
    ///
    /// Provides namespaced access to allocation state:
    /// - `pool.allocation.indices` — indices of all currently allocated slots
    @inlinable
    public var allocation: Property<Allocation, Self>.View.Read {
        _read {
            yield Property<Allocation, Self>.View.Read(
                borrowing: self
            )
        }
    }
}

// MARK: - Allocation Property.View.Read Extensions

extension Property.View.Read where Tag == Memory.Pool.Allocation, Base == Memory.Pool {
    /// Indices of all currently allocated slots.
    @inlinable
    public var indices: Bit.Vector.Ones.View {
        unsafe base.pointee._allocationBits.ones
    }
}
