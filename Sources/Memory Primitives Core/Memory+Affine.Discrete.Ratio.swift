// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// MARK: - Memory Layout Ratio

extension Affine.Discrete.Ratio where From: ~Copyable, To == Memory {
    /// The byte stride of `From` — bytes between consecutive elements in memory.
    ///
    /// Wraps `MemoryLayout<From>.stride` as a typed ratio, enabling
    /// element-to-byte offset conversion via the `*` operator.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let elementOffset = Index<Int>.Offset(fromZero: slot)
    /// let byteOffset = elementOffset * .stride  // Memory.Address.Offset
    /// ```
    @inlinable
    public static var stride: Self { .init(MemoryLayout<From>.stride) }
}
