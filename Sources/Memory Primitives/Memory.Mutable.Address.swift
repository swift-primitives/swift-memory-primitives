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

public import Index_Primitives
public import Property_Primitives

// MARK: - Pointer Conversion (Non-Optional)

extension Tagged where Tag == Memory.Mutable, RawValue == Ordinal {
    /// Creates a mutable address from a mutable raw pointer.
    ///
    /// - Parameter pointer: A non-null mutable raw pointer.
    @inlinable
    public init(_ pointer: UnsafeMutableRawPointer) {
        let bits = UInt(bitPattern: pointer)
        self.init(__unchecked: (), Ordinal(bits))
    }

    /// Creates a mutable address from a mutable typed pointer.
    @inlinable
    public init<T>(_ pointer: UnsafeMutablePointer<T>) {
        unsafe self.init(UnsafeMutableRawPointer(pointer))
    }
}

// MARK: - Pointer Conversion (Optional, Throwing)

extension Tagged where Tag == Memory.Mutable, RawValue == Ordinal {
    /// Creates a mutable address from an optional mutable raw pointer.
    ///
    /// - Parameter pointer: An optional mutable raw pointer.
    /// - Throws: `Memory.Address.Error.null` if the pointer is nil.
    @inlinable
    public init(_ pointer: UnsafeMutableRawPointer?) throws(Memory.Address.Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(pointer)
    }

    /// Creates a mutable address from an optional mutable typed pointer.
    ///
    /// - Parameter pointer: An optional mutable typed pointer.
    /// - Throws: `Memory.Address.Error.null` if the pointer is nil.
    @inlinable
    public init<T>(_ pointer: UnsafeMutablePointer<T>?) throws(Memory.Address.Error) {
        guard let pointer = unsafe pointer else { throw .null }
        unsafe self.init(UnsafeMutableRawPointer(pointer))
    }
}

// MARK: - Address Conversion

extension Tagged where Tag == Memory.Mutable, RawValue == Ordinal {
    /// Creates a mutable address from an immutable address.
    ///
    /// - Warning: The caller is responsible for ensuring that mutation through
    ///   the returned address is safe and permitted.
    /// - Parameter address: The immutable address to convert.
    @inlinable
    public init(_ address: Memory.Address) {
        self.init(__unchecked: (), address.rawValue)
    }
}

extension Tagged where Tag == Memory, RawValue == Ordinal {
    /// Creates an immutable address from a mutable address.
    ///
    /// - Parameter address: The mutable address to convert.
    @inlinable
    public init(_ address: Memory.Mutable.Address) {
        self.init(__unchecked: (), address.rawValue)
    }
}

// MARK: - Allocation

extension Tagged where Tag == Memory.Mutable, RawValue == Ordinal {
    /// Allocates uninitialized memory with the specified size and alignment.
    ///
    /// - Parameters:
    ///   - count: The number of bytes to allocate.
    ///   - alignment: The alignment of the allocated memory, in bytes.
    /// - Returns: A mutable address to the allocated memory.
    @inlinable
    public static func allocate(count: Memory.Address.Count, alignment: Memory.Address.Count) -> Self {
        unsafe Self(UnsafeMutableRawPointer.allocate(count: count, alignment: alignment))
    }

    /// Deallocates the memory referenced by this address.
    @inlinable
    public func deallocate() {
        unsafe UnsafeMutableRawPointer(self).deallocate()
    }
}

// MARK: - Initialization

extension Tagged where Tag == Memory.Mutable, RawValue == Ordinal {
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
        unsafe UnsafeMutableRawPointer(self).memory.initialize(as: type, repeating: value, count: count)
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
        unsafe UnsafeMutableRawPointer(self).memory.initialize(as: type, from: source, count: count)
    }
}

// MARK: - Initialize Accessor

extension Tagged where Tag == Memory.Mutable, RawValue == Ordinal {
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

extension Property where Tag == Memory.Mutable.Address.Initialize, Base == Memory.Mutable.Address {
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
        unsafe UnsafeMutableRawPointer(base).memory.move.initialize(as: type, from: source, count: count)
    }
}

// MARK: - Memory Binding

extension Tagged where Tag == Memory.Mutable, RawValue == Ordinal {
    /// Binds the memory to the specified type and returns a typed pointer.
    ///
    /// - Parameters:
    ///   - type: The type to bind the memory to.
    ///   - capacity: The number of instances of `type` that fit in the bound memory.
    /// - Returns: A typed pointer to the bound memory.
    @inlinable
    @discardableResult
    public func bind<T: ~Copyable>(
        to type: T.Type,
        capacity: Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe UnsafeMutableRawPointer(self).memory.bind(to: type, capacity: capacity)
    }
}

// MARK: - Assuming Accessor

extension Tagged where Tag == Memory.Mutable, RawValue == Ordinal {
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

extension Property where Tag == Memory.Mutable.Address.Assuming, Base == Memory.Mutable.Address {
    /// Returns a typed pointer assuming the memory is already bound to the specified type.
    ///
    /// - Parameter type: The type the memory is assumed to be bound to.
    /// - Returns: A typed pointer to the memory.
    @inlinable
    public func bound<T: ~Copyable>(
        to type: T.Type
    ) -> UnsafeMutablePointer<T> {
        unsafe UnsafeMutableRawPointer(base).assumingMemoryBound(to: type)
    }
}

// MARK: - Pointer Arithmetic

extension Tagged where Tag == Memory.Mutable, RawValue == Ordinal {
    /// Returns an address offset by the specified number of bytes.
    ///
    /// - Parameter offset: The byte offset.
    /// - Returns: A new address offset by the given bytes.
    @inlinable
    public func advanced(
        by offset: Memory.Address.Offset
    ) -> Self {
        // Use ordinal arithmetic: add offset to the raw bits
        let newBits = Int(bitPattern: rawValue.rawValue) &+ offset.rawValue.rawValue
        return Self(__unchecked: (), Ordinal(UInt(bitPattern: newBits)))
    }

    /// Returns the distance in bytes from this address to another.
    ///
    /// - Parameter other: The target address.
    /// - Returns: The byte offset between this address and `other`.
    @inlinable
    public func distance(
        to other: Self
    ) -> Memory.Address.Offset {
        // Compute signed distance between addresses
        let selfBits = Int(bitPattern: rawValue.rawValue)
        let otherBits = Int(bitPattern: other.rawValue.rawValue)
        return Memory.Address.Offset(otherBits &- selfBits)
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

// MARK: - Read and Store

extension Tagged where Tag == Memory.Mutable, RawValue == Ordinal {
    /// Reads a value of the specified type from memory.
    ///
    /// - Parameters:
    ///   - offset: The byte offset from which to read.
    ///   - type: The type of value to read.
    /// - Returns: The value read from memory.
    @inlinable
    public func read<T>(
        from offset: Memory.Address.Offset = .zero,
        as type: T.Type
    ) -> T {
        unsafe UnsafeMutableRawPointer(self).load(fromByteOffset: offset, as: type)
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
        at offset: Memory.Address.Offset = .zero,
        as type: T.Type
    ) {
        unsafe UnsafeMutableRawPointer(self).store.bytes(of: value, at: offset, as: type)
    }
}

// MARK: - Copy Operations

extension Tagged where Tag == Memory.Mutable, RawValue == Ordinal {
    /// Copies bytes from a source address.
    ///
    /// - Parameters:
    ///   - source: The source address to copy from.
    ///   - count: The number of bytes to copy.
    @inlinable
    public func copy(
        from source: Memory.Address,
        count: Memory.Address.Count
    ) {
        unsafe UnsafeMutableRawPointer(self).memory.copy(from: UnsafeRawPointer(source), count: count)
    }

    /// Copies bytes from a source address (mutable variant).
    ///
    /// - Parameters:
    ///   - source: The source address to copy from.
    ///   - count: The number of bytes to copy.
    @inlinable
    public func copy(
        from source: Self,
        count: Memory.Address.Count
    ) {
        unsafe UnsafeMutableRawPointer(self).memory.copy(
            from: UnsafeRawPointer(UnsafeMutableRawPointer(source)),
            count: count
        )
    }
}

// MARK: - UnsafeMutableRawPointer Interop

extension UnsafeMutableRawPointer {
    /// Creates a mutable raw pointer from a mutable memory address.
    @inlinable
    public init(_ address: Memory.Mutable.Address) {
        unsafe self = UnsafeMutableRawPointer(bitPattern: address.rawValue.rawValue)!
    }
}
