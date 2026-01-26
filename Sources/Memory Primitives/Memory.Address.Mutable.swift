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

extension Memory.Address {
    /// A non-null mutable memory address.
    ///
    /// Represents a mutable physical memory location. The address is stored as
    /// `UnsafeMutableRawPointer` internally with a non-null guarantee.
    ///
    /// This is the mutable raw address type. For typed pointer access, use
    /// `Pointer<Pointee>.Mutable` which combines `Memory.Address.Mutable` with phantom typing.
    @safe
    public struct Mutable: Hashable, @unchecked Sendable {
        /// The raw pointer value, guaranteed non-null.
        @usableFromInline
        internal let _rawPointer: UnsafeMutableRawPointer

        // MARK: - Non-Optional Initializers

        /// Creates a mutable address from a mutable raw pointer.
        ///
        /// - Parameter pointer: A non-null mutable raw pointer.
        @inlinable
        public init(_ pointer: UnsafeMutableRawPointer) {
            unsafe self._rawPointer = unsafe pointer
        }

        /// Creates a mutable address from a mutable typed pointer.
        @inlinable
        public init<T>(_ pointer: UnsafeMutablePointer<T>) {
            unsafe self._rawPointer = UnsafeMutableRawPointer(pointer)
        }

        // MARK: - Optional Initializers (Throwing)

        /// Creates a mutable address from an optional mutable raw pointer.
        ///
        /// - Parameter pointer: An optional mutable raw pointer.
        /// - Throws: `Memory.Address.Error.null` if the pointer is nil.
        @inlinable
        public init(_ pointer: UnsafeMutableRawPointer?) throws(Memory.Address.Error) {
            guard let pointer else { throw .null }
            unsafe self._rawPointer = unsafe pointer
        }

        /// Creates a mutable address from an optional mutable typed pointer.
        ///
        /// - Parameter pointer: An optional mutable typed pointer.
        /// - Throws: `Memory.Address.Error.null` if the pointer is nil.
        @inlinable
        public init<T>(_ pointer: UnsafeMutablePointer<T>?) throws(Memory.Address.Error) {
            guard let pointer else { throw .null }
            unsafe self._rawPointer = UnsafeMutableRawPointer(pointer)
        }

        // MARK: - Properties

        /// The mutable raw pointer value.
        @inlinable
        public var rawPointer: UnsafeMutableRawPointer {
            unsafe _rawPointer
        }

        /// Returns an immutable view of this address.
        @inlinable
        public var immutable: Memory.Address {
            unsafe Memory.Address(UnsafeRawPointer(_rawPointer))
        }
    }
}

// MARK: - Allocation

extension Memory.Address.Mutable {
    /// Allocates uninitialized memory with the specified size and alignment.
    ///
    /// - Parameters:
    ///   - byteCount: The number of bytes to allocate.
    ///   - alignment: The alignment of the allocated memory, in bytes.
    /// - Returns: A mutable address to the allocated memory.
    @inlinable
    public static func allocate(byteCount: Int, alignment: Int) -> Self {
        unsafe Self(UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: alignment))
    }

    /// Deallocates the memory referenced by this address.
    @inlinable
    public func deallocate() {
        unsafe _rawPointer.deallocate()
    }
}

// MARK: - Initialization

extension Memory.Address.Mutable {
    /// Initializes memory as the specified type with the given value.
    ///
    /// - Parameters:
    ///   - type: The type to initialize the memory as.
    ///   - repeating: The value to copy into each element.
    ///   - count: The number of elements to initialize.
    /// - Returns: A typed pointer to the initialized memory.
    @inlinable
    @discardableResult
    public func initializeMemory<T>(as type: T.Type, repeating value: T, count: Int) -> UnsafeMutablePointer<T> {
        unsafe _rawPointer.initializeMemory(as: type, repeating: value, count: count)
    }

    /// Initializes memory as the specified type from a source buffer.
    ///
    /// - Parameters:
    ///   - type: The type to initialize the memory as.
    ///   - source: A pointer to the source values.
    ///   - count: The number of elements to copy.
    /// - Returns: A typed pointer to the initialized memory.
    @inlinable
    @discardableResult
    public func initializeMemory<T>(as type: T.Type, from source: UnsafePointer<T>, count: Int) -> UnsafeMutablePointer<T> {
        unsafe _rawPointer.initializeMemory(as: type, from: source, count: count)
    }
}

// MARK: - Move Operations

extension Memory.Address.Mutable {
    /// Initializes memory as the specified type by moving values from a source.
    ///
    /// The source memory becomes uninitialized after this operation.
    ///
    /// - Parameters:
    ///   - type: The type to initialize the memory as.
    ///   - source: A pointer to the source values (will be left uninitialized).
    ///   - count: The number of elements to move.
    /// - Returns: A typed pointer to the initialized memory.
    @inlinable
    @discardableResult
    public func moveInitializeMemory<T>(as type: T.Type, from source: UnsafeMutablePointer<T>, count: Int) -> UnsafeMutablePointer<T> {
        unsafe _rawPointer.moveInitializeMemory(as: type, from: source, count: count)
    }
}

// MARK: - Memory Binding

extension Memory.Address.Mutable {
    /// Binds the memory to the specified type and returns a typed pointer.
    ///
    /// - Parameters:
    ///   - type: The type to bind the memory to.
    ///   - capacity: The number of instances of `type` that fit in the bound memory.
    /// - Returns: A typed pointer to the bound memory.
    @inlinable
    @discardableResult
    public func bindMemory<T>(to type: T.Type, capacity: Int) -> UnsafeMutablePointer<T> {
        unsafe _rawPointer.bindMemory(to: type, capacity: capacity)
    }

    /// Returns a typed pointer assuming the memory is already bound to the specified type.
    ///
    /// - Parameter type: The type the memory is assumed to be bound to.
    /// - Returns: A typed pointer to the memory.
    @inlinable
    public func assumingMemoryBound<T>(to type: T.Type) -> UnsafeMutablePointer<T> {
        unsafe _rawPointer.assumingMemoryBound(to: type)
    }
}

// MARK: - Pointer Arithmetic

extension Memory.Address.Mutable {
    /// Returns an address offset by the specified number of bytes.
    ///
    /// - Parameter n: The number of bytes to offset.
    /// - Returns: A new address offset by `n` bytes.
    @inlinable
    public func advanced(by n: Int) -> Self {
        unsafe Self(_rawPointer.advanced(by: n))
    }

    /// Returns the distance in bytes from this address to another.
    ///
    /// - Parameter other: The target address.
    /// - Returns: The number of bytes between this address and `other`.
    @inlinable
    public func distance(to other: Self) -> Int {
        unsafe _rawPointer.distance(to: other._rawPointer)
    }
}

// MARK: - Load and Store

extension Memory.Address.Mutable {
    /// Reads a value of the specified type from memory.
    ///
    /// - Parameters:
    ///   - offset: The offset in bytes from which to read.
    ///   - type: The type of value to read.
    /// - Returns: The value read from memory.
    @inlinable
    public func load<T>(fromByteOffset offset: Int = 0, as type: T.Type) -> T {
        unsafe _rawPointer.load(fromByteOffset: offset, as: type)
    }

    /// Stores a value of the specified type to memory.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - offset: The offset in bytes at which to store.
    ///   - type: The type of value to store.
    @inlinable
    public func storeBytes<T>(of value: T, toByteOffset offset: Int = 0, as type: T.Type) {
        unsafe _rawPointer.storeBytes(of: value, toByteOffset: offset, as: type)
    }
}

// MARK: - Copy Operations

extension Memory.Address.Mutable {
    /// Copies bytes from a source address.
    ///
    /// - Parameters:
    ///   - source: The source address to copy from.
    ///   - byteCount: The number of bytes to copy.
    @inlinable
    public func copyMemory(from source: Memory.Address, byteCount: Int) {
        unsafe _rawPointer.copyMemory(from: source._rawPointer, byteCount: byteCount)
    }

    /// Copies bytes from a source address (mutable variant).
    ///
    /// - Parameters:
    ///   - source: The source address to copy from.
    ///   - byteCount: The number of bytes to copy.
    @inlinable
    public func copyMemory(from source: Self, byteCount: Int) {
        unsafe _rawPointer.copyMemory(from: UnsafeRawPointer(source._rawPointer), byteCount: byteCount)
    }
}
