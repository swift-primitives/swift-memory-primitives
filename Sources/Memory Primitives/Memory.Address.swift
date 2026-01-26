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
            guard let pointer else { throw .null }
            unsafe self._rawPointer = unsafe pointer
        }

        /// Creates an address from an optional typed pointer.
        ///
        /// - Parameter pointer: An optional typed pointer.
        /// - Throws: `Error.null` if the pointer is nil.
        @inlinable
        public init<T>(_ pointer: UnsafePointer<T>?) throws(Error) {
            guard let pointer else { throw .null }
            unsafe self._rawPointer = UnsafeRawPointer(pointer)
        }

        /// Creates an address from an optional mutable typed pointer.
        ///
        /// - Parameter pointer: An optional mutable typed pointer.
        /// - Throws: `Error.null` if the pointer is nil.
        @inlinable
        public init<T>(_ pointer: UnsafeMutablePointer<T>?) throws(Error) {
            guard let pointer else { throw .null }
            unsafe self._rawPointer = UnsafeRawPointer(pointer)
        }

        // MARK: - Properties

        /// The raw pointer value.
        @inlinable
        public var rawPointer: UnsafeRawPointer {
            unsafe _rawPointer
        }
    }
}

// MARK: - Error

extension Memory.Address {
    /// Errors that can occur when creating a memory address.
    public enum Error: Swift.Error, Equatable, Hashable, Sendable {
        /// The pointer was null.
        case null
    }
}
