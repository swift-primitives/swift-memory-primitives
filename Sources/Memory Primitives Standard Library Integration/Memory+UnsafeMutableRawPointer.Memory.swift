//
//  Index+UnsafeMutableRawPointer.Memory.swift
//  swift-index-primitives
//
//  Created by Coen ten Thije Boonkkamp on 27/01/2026.
//

import Property_Primitives
import Memory_Primitives_Core


// MARK: - Accessor

extension UnsafeMutableRawPointer {
    /// Namespace for memory initialization and binding operations.
    ///
    /// Use this accessor for type-safe memory operations:
    ///
    /// ```swift
    /// pointer.memory.initialize(as: Int.self, repeating: 0, count: count)
    /// pointer.memory.bind(to: Int.self, capacity: count)
    /// pointer.memory.copy(from: source, count: byteCount)
    /// pointer.memory.move.initialize(as: Int.self, from: source, count: count)
    /// ```
    @inlinable
    public var memory: Property_Primitives.Property<Memory, Self> {
        unsafe Property_Primitives.Property(self)
    }
}

// MARK: - Property Extension

extension Property_Primitives.Property
where Tag == Memory, Base == UnsafeMutableRawPointer {

    /// Initializes memory as the specified type with a repeated value.
    ///
    /// - Parameters:
    ///   - type: The type to initialize memory as.
    ///   - value: The value to repeat.
    ///   - count: The number of instances to initialize.
    /// - Returns: A typed pointer to the initialized memory.
    @inlinable
    @discardableResult
    public func initialize<T>(
        as type: T.Type,
        repeating value: T,
        count: Index_Primitives_Core.Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe base.initializeMemory(as: type, repeating: value, count: Int(bitPattern: count.count))
    }

    /// Initializes memory as the specified type from a source buffer.
    ///
    /// - Parameters:
    ///   - type: The type to initialize memory as.
    ///   - source: A pointer to the values to copy.
    ///   - count: The number of instances to initialize.
    /// - Returns: A typed pointer to the initialized memory.
    @inlinable
    @discardableResult
    public func initialize<T>(
        as type: T.Type,
        from source: UnsafePointer<T>,
        count: Index_Primitives_Core.Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe base.initializeMemory(as: type, from: source, count: Int(bitPattern: count.count))
    }

    /// Binds the memory to the specified type with a typed capacity.
    ///
    /// - Parameters:
    ///   - type: The type to bind memory to.
    ///   - capacity: The capacity in elements.
    /// - Returns: A typed pointer to the bound memory.
    @inlinable
    @discardableResult
    public func bind<T: ~Copyable>(
        to type: T.Type,
        capacity: Index_Primitives_Core.Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe base.bindMemory(to: type, capacity: Int(bitPattern: capacity.count))
    }

    /// Copies bytes from a source with a typed byte count.
    ///
    /// - Parameters:
    ///   - source: A pointer to the bytes to copy.
    ///   - count: The number of bytes to copy.
    @inlinable
    public func copy(
        from source: UnsafeRawPointer,
        count: Memory.Address.Count
    ) {
        unsafe base.copyMemory(from: source, byteCount: Int(bitPattern: count.count))
    }

    /// Namespace for move operations.
    @inlinable
    public var move: Property_Primitives.Property<Memory.Move, Base> {
        unsafe Property_Primitives.Property(base)
    }
}
