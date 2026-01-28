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
public import Cardinal_Primitives
public import Affine_Primitives
public import Identity_Primitives

extension Memory {
    /// A non-null memory address.
    ///
    /// An address is an ordinal position in byte-addressable memory. The backing
    /// `Ordinal` stores the pointer's bit pattern as `UInt`.
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
        let bits = UInt(bitPattern: pointer)
        self.init(__unchecked: (), Ordinal(bits))
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

// MARK: - Pointer Access

extension Tagged where Tag == Memory, RawValue == Ordinal {
    /// The raw pointer value.
    ///
    /// Always succeeds because addresses are non-zero (non-null guarantee).
    @inlinable
    public var rawPointer: UnsafeRawPointer {
        unsafe UnsafeRawPointer(bitPattern: rawValue.rawValue)!
    }

    /// The mutable raw pointer value.
    ///
    /// Always succeeds because addresses are non-zero (non-null guarantee).
    @inlinable
    public var mutableRawPointer: UnsafeMutableRawPointer {
        unsafe UnsafeMutableRawPointer(bitPattern: rawValue.rawValue)!
    }
}

// MARK: - UnsafeRawPointer Interop

extension UnsafeRawPointer {
    /// Creates a raw pointer from a memory address.
    @inlinable
    public init(_ address: Memory.Address) {
        unsafe self = address.rawPointer
    }
}

// MARK: - Type Aliases

extension Tagged where Tag == Memory, RawValue == Ordinal {
    /// Byte offset type (displacement in address space).
    ///
    /// This is `Tagged<Memory, Affine.Discrete.Vector>`.
    public typealias Offset = Tagged<Memory, Affine.Discrete.Vector>

    /// Byte count type (cardinality in address space).
    ///
    /// This is `Tagged<Memory, Cardinal>`.
    public typealias Count = Tagged<Memory, Cardinal>
}

// MARK: - Pointer Arithmetic
//
// Note: The affine arithmetic operators (+, -) are inherited from
// Tagged<Tag, Ordinal> extensions in Affine_Primitives.
//
// However, those operators use `throws` for overflow checking.
// For convenience, we provide non-throwing versions using Memory.Address.Offset
// which is the common case for memory operations.

extension Tagged where Tag == Memory, RawValue == Ordinal {
    /// Returns an address offset by the specified number of bytes.
    ///
    /// - Parameter offset: The byte offset.
    /// - Returns: A new address offset by the given bytes.
    @inlinable
    public func advanced(by offset: Memory.Address.Offset) -> Self {
        unsafe Self(rawPointer.advanced(by: offset.rawValue.rawValue))
    }

    /// Returns the distance in bytes from this address to another.
    ///
    /// - Parameter other: The target address.
    /// - Returns: The byte offset between this address and `other`.
    @inlinable
    public func distance(to other: Self) -> Memory.Address.Offset {
        unsafe Memory.Address.Offset(rawPointer.distance(to: other.rawPointer))
    }

    /// Adds a byte offset to an address.
    @inlinable
    public static func + (lhs: Self, rhs: Memory.Address.Offset) -> Self {
        lhs.advanced(by: rhs)
    }

    /// Adds a byte offset to an address.
    @inlinable
    public static func + (lhs: Memory.Address.Offset, rhs: Self) -> Self {
        rhs.advanced(by: lhs)
    }

    /// Subtracts a byte offset from an address.
    @inlinable
    public static func - (lhs: Self, rhs: Memory.Address.Offset) -> Self {
        lhs.advanced(by: -rhs)
    }

    /// Returns the byte distance between two addresses.
    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Memory.Address.Offset {
        rhs.distance(to: lhs)
    }
}
