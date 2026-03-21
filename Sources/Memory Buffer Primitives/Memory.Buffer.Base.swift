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

extension Memory.Buffer {
    /// Tag for the `base` property namespace.
    public enum Base {}
}

extension Memory.Buffer {
    /// Namespace for stdlib buffer pointer conversions.
    ///
    /// Provides two conversion modes for crossing to `UnsafeRawBufferPointer`:
    ///
    /// ```swift
    /// let buffer: Memory.Buffer = ...
    /// buffer.base.nullable  // nil base address for empty (stdlib convention)
    /// buffer.base.nonNull   // sentinel base address for empty (C interop)
    /// ```
    @inlinable
    public var base: Property<Base, Memory.Buffer> { .init(self) }
}

extension Property where Tag == Memory.Buffer.Base, Base == Memory.Buffer {
    /// The underlying stdlib buffer pointer (stdlib-normal form).
    ///
    /// For empty buffers, returns `(start: nil, count: 0)` per stdlib convention.
    /// Use this for idiomatic Swift stdlib interop.
    @inlinable
    public var nullable: UnsafeRawBufferPointer {
        if base.isEmpty {
            return unsafe UnsafeRawBufferPointer(start: nil, count: 0)
        }
        return unsafe UnsafeRawBufferPointer(
            start: UnsafeRawPointer(base._start),
            count: base.count
        )
    }

    /// The underlying stdlib buffer pointer with non-null start.
    ///
    /// For empty buffers, returns `(start: sentinel, count: 0)`.
    /// Use this for C APIs that reject null pointers even with count 0.
    @inlinable
    public var nonNull: UnsafeRawBufferPointer {
        unsafe UnsafeRawBufferPointer(
            start: UnsafeRawPointer(base._start),
            count: base.count
        )
    }
}
