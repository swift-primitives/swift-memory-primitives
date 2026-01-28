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

extension Memory {
    /// A non-null memory address.
    ///
    /// Represents a physical memory location. The address is stored as
    /// `UnsafeRawPointer` internally with a non-null guarantee.
    ///
    /// This is the raw address type. For typed pointer access, use
    /// `Pointer<Pointee>` which combines `Memory.Address` with phantom typing.
    @safe
    public struct Address: Hashable, @unchecked Sendable {
        /// The raw pointer value, guaranteed non-null.
        @usableFromInline
        internal let _rawPointer: UnsafeRawPointer

        // MARK: - Non-Optional Initializers

        /// Creates an address from a raw pointer.
        ///
        /// - Parameter pointer: A non-null raw pointer.
        @inlinable
        public init(_ pointer: UnsafeRawPointer) {
            unsafe self._rawPointer = unsafe pointer
        }

        /// Creates an address from a typed pointer.
        @inlinable
        public init<T>(_ pointer: UnsafePointer<T>) {
            unsafe self._rawPointer = UnsafeRawPointer(pointer)
        }

        /// Creates an address from a mutable typed pointer.
        @inlinable
        public init<T>(_ pointer: UnsafeMutablePointer<T>) {
            unsafe self._rawPointer = UnsafeRawPointer(pointer)
        }

        // MARK: - Optional Initializers (Throwing)

        /// Creates an address from an optional raw pointer.
        ///
        /// - Parameter pointer: An optional raw pointer.
        /// - Throws: `Error.null` if the pointer is nil.
        @inlinable
        public init(_ pointer: UnsafeRawPointer?) throws(Error) {
            guard let pointer = unsafe pointer else { throw .null }
            unsafe self._rawPointer = unsafe pointer
        }

        /// Creates an address from an optional typed pointer.
        ///
        /// - Parameter pointer: An optional typed pointer.
        /// - Throws: `Error.null` if the pointer is nil.
        @inlinable
        public init<T>(_ pointer: UnsafePointer<T>?) throws(Error) {
            guard let pointer = unsafe pointer else { throw .null }
            unsafe self._rawPointer = UnsafeRawPointer(pointer)
        }

        /// Creates an address from an optional mutable typed pointer.
        ///
        /// - Parameter pointer: An optional mutable typed pointer.
        /// - Throws: `Error.null` if the pointer is nil.
        @inlinable
        public init<T>(_ pointer: UnsafeMutablePointer<T>?) throws(Error) {
            guard let pointer = unsafe pointer else { throw .null }
            unsafe self._rawPointer = UnsafeRawPointer(pointer)
        }
    }
}

extension UnsafeRawPointer {
    public init(
        _ address: Memory.Address
    ){
        unsafe self = unsafe address._rawPointer
    }
}

// MARK: - Properties

extension Memory.Address {
    /// The raw pointer value.
    @inlinable
    public var rawPointer: UnsafeRawPointer {
        unsafe _rawPointer
    }
}

// MARK: - Pointer Arithmetic

extension Memory.Address {
    /// Returns an address offset by the specified number of bytes.
    ///
    /// - Parameter offset: The byte offset.
    /// - Returns: A new address offset by the given bytes.
    @inlinable
    public func advanced(
        by offset: Index<UInt8>.Offset
    ) -> Self {
        unsafe Self(_rawPointer.advanced(by: offset))
    }

    /// Returns the distance in bytes from this address to another.
    ///
    /// - Parameter other: The target address.
    /// - Returns: The byte offset between this address and `other`.
    @inlinable
    public func distance(
        to other: Self
    ) -> Index<UInt8>.Offset {
        unsafe Index<UInt8>.Offset(_rawPointer.distance(to: other._rawPointer))
    }

    /// Adds a byte offset to an address.
    @inlinable
    public static func + (lhs: Self, rhs: Index<UInt8>.Offset) -> Self {
        lhs.advanced(by: rhs)
    }

    /// Adds a byte offset to an address.
    @inlinable
    public static func + (lhs: Index<UInt8>.Offset, rhs: Self) -> Self {
        rhs.advanced(by: lhs)
    }

    /// Subtracts a byte offset from an address.
    @inlinable
    public static func - (lhs: Self, rhs: Index<UInt8>.Offset) -> Self {
        lhs.advanced(by: -rhs)
    }

    /// Returns the byte distance between two addresses.
    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Index<UInt8>.Offset {
        lhs.distance(to: rhs)
    }
}
