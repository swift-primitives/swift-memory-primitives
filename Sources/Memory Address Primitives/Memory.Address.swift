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

import Affine_Primitives
import Cardinal_Primitives
public import Ordinal_Primitives
public import Tagged_Primitives

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

extension Tagged where Tag == Memory, Underlying == Ordinal {
    /// Creates an address from a non-null raw pointer.
    ///
    /// - Parameter pointer: A non-null raw pointer.
    @inlinable
    public init(_ pointer: UnsafeRawPointer) {
        self.init(_unchecked: Ordinal(UInt(bitPattern: pointer)))
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

extension Tagged where Tag == Memory, Underlying == Ordinal {
    /// Creates an address from an optional raw pointer.
    ///
    /// - Parameter pointer: An optional raw pointer.
    /// - Throws: `Error.null` if the pointer is nil.
    @inlinable
    public init(_ pointer: UnsafeRawPointer?) throws(Tagged.Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(pointer)
    }

    /// Creates an address from an optional typed pointer.
    ///
    /// - Parameter pointer: An optional typed pointer.
    /// - Throws: `Error.null` if the pointer is nil.
    @inlinable
    public init<T>(_ pointer: UnsafePointer<T>?) throws(Tagged.Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(pointer)
    }

    /// Creates an address from an optional mutable typed pointer.
    ///
    /// - Parameter pointer: An optional mutable typed pointer.
    /// - Throws: `Error.null` if the pointer is nil.
    @inlinable
    public init<T>(_ pointer: UnsafeMutablePointer<T>?) throws(Tagged.Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(pointer)
    }

    /// Creates an address from an optional mutable raw pointer.
    ///
    /// - Parameter pointer: An optional mutable raw pointer.
    /// - Throws: `Error.null` if the pointer is nil.
    @inlinable
    public init(_ pointer: UnsafeMutableRawPointer?) throws(Tagged.Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(pointer)
    }
}

// MARK: - Bit Pattern

extension Tagged where Tag == Memory, Underlying == Ordinal {
    /// The raw bit pattern of this address as a `UInt`.
    ///
    /// Use this for interop with stdlib APIs that require `UInt` (e.g.,
    /// `UnsafeRawPointer(bitPattern:)`). Prefer typed pointer conversions
    /// when possible.
    @inlinable
    public var bitPattern: UInt { underlying.rawValue }
}

// MARK: - UnsafeRawPointer Interop

extension UnsafeRawPointer {
    /// Creates a raw pointer from a memory address.
    @inlinable
    public init(_ address: Memory.Address) {
        // WHY: `UnsafeRawPointer(bitPattern:)` is nil only for a zero address; this
        // conversion presupposes (and traps on the absence of) a valid non-null address.
        // swift-format-ignore: NeverForceUnwrap
        unsafe self = UnsafeRawPointer(bitPattern: address.bitPattern)!
    }

    /// Creates a raw pointer from a tagged memory address.
    ///
    /// Unwraps the phantom type tag and delegates to the `Memory.Address` conversion.
    @inlinable
    public init<Tag: ~Copyable & ~Escapable>(_ address: Tagged<Tag, Memory.Address>) {
        unsafe self.init(address.underlying)
    }
}

extension UnsafeMutableRawPointer {
    /// Creates a mutable raw pointer from a memory address.
    @inlinable
    public init(_ address: Memory.Address) {
        // WHY: `UnsafeMutableRawPointer(bitPattern:)` is nil only for a zero address; this
        // conversion presupposes (and traps on the absence of) a valid non-null address.
        // swift-format-ignore: NeverForceUnwrap
        unsafe self = UnsafeMutableRawPointer(bitPattern: address.bitPattern)!
    }

    /// Creates a mutable raw pointer from a tagged memory address.
    @inlinable
    public init<Tag: ~Copyable & ~Escapable>(_ address: Tagged<Tag, Memory.Address>) {
        unsafe self.init(address.underlying)
    }
}

// MARK: - Pointer Accessors

extension Tagged where Tag == Memory, Underlying == Ordinal {
    /// The mutable raw pointer for syscall interop.
    ///
    /// Memory.Address is non-null by design; conversion is always safe.
    @inlinable
    public var mutablePointer: UnsafeMutableRawPointer {
        unsafe UnsafeMutableRawPointer(self)
    }

    /// The immutable raw pointer for syscall interop.
    ///
    /// Memory.Address is non-null by design; conversion is always safe.
    @inlinable
    public var pointer: UnsafeRawPointer {
        unsafe UnsafeRawPointer(self)
    }
}
