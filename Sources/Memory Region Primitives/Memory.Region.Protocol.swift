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

public import Memory_Primitive
public import Memory_Address_Primitives

extension Memory.Region {
    /// The minimal raw-region seam: a stable base address + a byte capacity.
    ///
    /// A conformer is an element-free, `~Copyable` raw byte resource that an allocator carves
    /// within. `base` is valid for the conformer's lifetime; `byteCapacity` is its size in bytes.
    /// Element typing begins one tier up, at Storage — the region itself is untyped raw bytes.
    public protocol `Protocol`: ~Copyable {
        /// The stable base address of the region's first byte. Valid for the region's lifetime.
        var base: Memory.Address { get }

        /// The region's capacity in bytes.
        var byteCapacity: Memory.Address.Count { get }
    }
}
