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



// MARK: - UnsafePointer + Index Arithmetic

/// Advances a pointer by a typed index offset.
@_transparent
public func + <Pointee: ~Copyable>(
    lhs: UnsafePointer<Pointee>,
    rhs: Index<Pointee>
) -> UnsafePointer<Pointee> {
    unsafe lhs + Int(bitPattern: rhs.position)
}

/// Advances a pointer by a typed index offset.
@_transparent
public func + <Pointee: ~Copyable>(
    lhs: Index<Pointee>,
    rhs: UnsafePointer<Pointee>
) -> UnsafePointer<Pointee> {
    unsafe rhs + Int(bitPattern: lhs.position)
}

/// Subtracts a typed index offset from a pointer.
@_transparent
public func - <Pointee: ~Copyable>(
    lhs: UnsafePointer<Pointee>,
    rhs: Index<Pointee>
) -> UnsafePointer<Pointee> {
    unsafe lhs - Int(bitPattern: rhs.position)
}

// MARK: - UnsafePointer Subscript

extension UnsafePointer where Pointee: ~Copyable {
    /// Accesses the element at the given typed index.
    ///
    /// This subscript enables type-safe pointer access using `Index<Pointee>`:
    ///
    /// ```swift
    /// (0..<count).forEach { i in
    ///     print(elements[i])  // i is Index<Element>
    /// }
    /// ```
    ///
    /// - Parameter index: A typed index into the pointer's memory.
    /// - Returns: The element at the specified index.
    @inlinable @inline(__always)
    public subscript(index: Index<Pointee>) -> Pointee {
        @_transparent
        unsafeAddress {
            unsafe self + index
        }
    }
}
