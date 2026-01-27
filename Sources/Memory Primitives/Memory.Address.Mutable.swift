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

public import Index_Primitives
public import Property_Primitives

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
            guard let pointer = unsafe pointer else { throw .null }
            unsafe self._rawPointer = unsafe pointer
        }

        /// Creates a mutable address from an optional mutable typed pointer.
        ///
        /// - Parameter pointer: An optional mutable typed pointer.
        /// - Throws: `Memory.Address.Error.null` if the pointer is nil.
        @inlinable
        public init<T>(_ pointer: UnsafeMutablePointer<T>?) throws(Memory.Address.Error) {
            guard let pointer = unsafe pointer else { throw .null }
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
    ///   - count: The number of bytes to allocate.
    ///   - alignment: The alignment of the allocated memory, in bytes.
    /// - Returns: A mutable address to the allocated memory.
    @inlinable
    public static func allocate(count: Index<UInt8>.Count, alignment: Index<UInt8>.Count) -> Self {
        unsafe Self(UnsafeMutableRawPointer.allocate(count: count, alignment: alignment))
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
    public func initialize<T>(
        as type: T.Type,
        repeating value: T,
        count: Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe _rawPointer.memory.initialize(as: type, repeating: value, count: count)
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
    public func initialize<T>(
        as type: T.Type,
        from source: UnsafePointer<T>,
        count: Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe _rawPointer.memory.initialize(as: type, from: source, count: count)
    }
}

// MARK: - Initialize Accessor

extension Memory.Address.Mutable {
    /// Tag type for initialization operations accessed via property accessor.
    public enum Initialize {}

    /// Property accessor for move-initialization operations.
    ///
    /// Use `.move(as:from:count:)` to initialize memory by moving values from a source.
    @inlinable
    public var initialize: Property<Initialize, Self> {
        Property(self)
    }
}

extension Property where Tag == Memory.Address.Mutable.Initialize, Base == Memory.Address.Mutable {
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
    public func move<T>(
        as type: T.Type,
        from source: UnsafeMutablePointer<T>,
        count: Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe base._rawPointer.memory.move.initialize(as: type, from: source, count: count)
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
    public func bind<T>(
        to type: T.Type,
        capacity: Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe _rawPointer.memory.bind(to: type, capacity: capacity)
    }
}

// MARK: - Assuming Accessor

extension Memory.Address.Mutable {
    /// Tag type for assumption-based operations accessed via property accessor.
    public enum Assuming {}

    /// Property accessor for assumption-based operations.
    ///
    /// Use `.bound(to:)` to get a typed pointer assuming the memory is already bound.
    @inlinable
    public var assuming: Property<Assuming, Self> {
        Property(self)
    }
}

extension Property where Tag == Memory.Address.Mutable.Assuming, Base == Memory.Address.Mutable {
    /// Returns a typed pointer assuming the memory is already bound to the specified type.
    ///
    /// - Parameter type: The type the memory is assumed to be bound to.
    /// - Returns: A typed pointer to the memory.
    @inlinable
    public func bound<T>(
        to type: T.Type
    ) -> UnsafeMutablePointer<T> {
        unsafe base._rawPointer.assumingMemoryBound(to: type)
    }
}

// MARK: - Pointer Arithmetic

extension Memory.Address.Mutable {
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
        lhs.advanced(by: Index<UInt8>.Offset(-rhs.rawValue))
    }

    /// Returns the byte distance between two addresses.
    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Index<UInt8>.Offset {
        lhs.distance(to: rhs)
    }
}

// MARK: - Read and Store

extension Memory.Address.Mutable {
    /// Reads a value of the specified type from memory.
    ///
    /// - Parameters:
    ///   - offset: The byte offset from which to read.
    ///   - type: The type of value to read.
    /// - Returns: The value read from memory.
    @inlinable
    public func read<T>(
        from offset: Index<UInt8>.Offset = .zero,
        as type: T.Type
    ) -> T {
        unsafe _rawPointer.load(fromByteOffset: offset.rawValue, as: type)
    }

    /// Stores a value of the specified type to memory.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - offset: The byte offset at which to store.
    ///   - type: The type of value to store.
    @inlinable
    public func store<T>(
        _ value: T,
        at offset: Index<UInt8>.Offset = .zero,
        as type: T.Type
    ) {
        unsafe _rawPointer.storeBytes(of: value, toByteOffset: offset.rawValue, as: type)
    }
}

// MARK: - Copy Operations

extension Memory.Address.Mutable {
    /// Copies bytes from a source address.
    ///
    /// - Parameters:
    ///   - source: The source address to copy from.
    ///   - count: The number of bytes to copy.
    @inlinable
    public func copy(
        from source: Memory.Address,
        count: Index<UInt8>.Count
    ) {
        unsafe _rawPointer.memory.copy(from: source._rawPointer, count: count)
    }

    /// Copies bytes from a source address (mutable variant).
    ///
    /// - Parameters:
    ///   - source: The source address to copy from.
    ///   - count: The number of bytes to copy.
    @inlinable
    public func copy(
        from source: Self,
        count: Index<UInt8>.Count
    ) {
        unsafe _rawPointer.memory.copy(
            from: UnsafeRawPointer(source._rawPointer),
            count: count
        )
    }
}
