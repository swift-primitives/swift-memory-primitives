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

        /// The raw pointer value.
        @inlinable
        public var rawPointer: UnsafeRawPointer {
            unsafe _rawPointer
        }
    }
}
