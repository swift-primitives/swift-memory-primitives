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

public import Ordinal_Primitives
import Cardinal_Primitives
import Affine_Primitives
public import Identity_Primitives

extension Memory {
    /// A non-null memory address.
    ///
    /// An address is an ordinal position in byte-addressable memory. The backing
    /// `Ordinal` stores the pointer's bit pattern as `UInt`.
    ///
    /// ## Provenance Model
    ///
    /// This type uses an integer-address model. When a pointer is converted to
    /// `Memory.Address`, it is stored as a raw integer bit pattern. Pointer
    /// provenance—the compiler's tracking of which allocation a pointer may
    /// access—is not preserved at this layer.
    ///
    /// This is a deliberate design choice. Integer addresses enable:
    /// - Typed arithmetic with affine operators
    /// - Cross-domain index scaling via `Affine.Discrete.Ratio`
    /// - Phantom type safety via `Tagged<Memory, Ordinal>`
    ///
    /// Higher layers (e.g., `Pointer<T>`) that need provenance-safe access
    /// should work with Swift's stdlib pointer types directly.
    ///
    /// ## Arithmetic
    ///
    /// Address arithmetic comes from `Tagged<Tag, Ordinal>` extensions in Affine_Primitives:
    /// - `Address + Offset → Address` (advance by bytes)
    /// - `Address - Offset → Address` (retreat by bytes)
    /// - `Address - Address → Offset` (displacement in bytes)
    ///
    /// ## Non-Null Guarantee
    ///
    /// Construction from a non-null pointer yields a non-zero `Ordinal`.
    /// Conversion back to pointer is always safe (non-zero → non-null).
    ///
    /// ## Typed Pointers
    ///
    /// For typed pointer access, use `Pointer<Pointee>` from pointer-primitives,
    /// which combines `Memory.Address` with phantom typing.
    public typealias Address = Tagged<Memory, Ordinal>
}

// MARK: - Pointer Conversion (Non-Optional)

extension Tagged where Tag == Memory, RawValue == Ordinal {
    /// Creates an address from a non-null raw pointer.
    ///
    /// - Parameter pointer: A non-null raw pointer.
    @inlinable
    public init(_ pointer: UnsafeRawPointer) {
        self.init(__unchecked: (), Ordinal(UInt(bitPattern: pointer)))
    }

    /// Creates an address from a non-null typed pointer.
    @inlinable
    public init<T>(_ pointer: UnsafePointer<T>) {
        unsafe self.init(UnsafeRawPointer(pointer))
    }

    /// Creates an address from a non-null mutable typed pointer.
    @inlinable
    public init<T>(_ pointer: UnsafeMutablePointer<T>) {
        unsafe self.init(UnsafeRawPointer(pointer))
    }

    /// Creates an address from a non-null mutable raw pointer.
    @inlinable
    public init(_ pointer: UnsafeMutableRawPointer) {
        unsafe self.init(UnsafeRawPointer(pointer))
    }
}

// MARK: - Pointer Conversion (Optional, Throwing)

extension Tagged where Tag == Memory, RawValue == Ordinal {
    /// Creates an address from an optional raw pointer.
    ///
    /// - Parameter pointer: An optional raw pointer.
    /// - Throws: `Error.null` if the pointer is nil.
    @inlinable
    public init(_ pointer: UnsafeRawPointer?) throws(Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(pointer)
    }

    /// Creates an address from an optional typed pointer.
    ///
    /// - Parameter pointer: An optional typed pointer.
    /// - Throws: `Error.null` if the pointer is nil.
    @inlinable
    public init<T>(_ pointer: UnsafePointer<T>?) throws(Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(pointer)
    }

    /// Creates an address from an optional mutable typed pointer.
    ///
    /// - Parameter pointer: An optional mutable typed pointer.
    /// - Throws: `Error.null` if the pointer is nil.
    @inlinable
    public init<T>(_ pointer: UnsafeMutablePointer<T>?) throws(Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(pointer)
    }

    /// Creates an address from an optional mutable raw pointer.
    ///
    /// - Parameter pointer: An optional mutable raw pointer.
    /// - Throws: `Error.null` if the pointer is nil.
    @inlinable
    public init(_ pointer: UnsafeMutableRawPointer?) throws(Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(pointer)
    }
}


// MARK: - UnsafeRawPointer Interop

extension UnsafeRawPointer {
    /// Creates a raw pointer from a memory address.
    @inlinable
    public init(_ address: Memory.Address) {
        unsafe self = UnsafeRawPointer(bitPattern: address.rawValue.rawValue)!
    }
}

extension UnsafeMutableRawPointer {
    /// Creates a mutable raw pointer from a memory address.
    @inlinable
    public init(_ address: Memory.Address) {
        unsafe self = UnsafeMutableRawPointer(bitPattern: address.rawValue.rawValue)!
    }
}

