//
//  Index+UnsafeMutableRawBufferPointer.Store.swift
//  swift-index-primitives
//
//  Created by Coen ten Thije Boonkkamp on 27/01/2026.
//

import Property_Primitives
public import Memory_Primitives_Core

// MARK: - Tag Type

extension UnsafeMutableRawBufferPointer {
    /// Tag for store operations on raw buffer pointers.
    public enum Store {}
}

// MARK: - Accessor

extension UnsafeMutableRawBufferPointer {
    /// Namespace for store operations.
    ///
    /// Use this accessor for storing values as bytes:
    ///
    /// ```swift
    /// buffer.store.bytes(of: value, at: offset, as: Int.self)
    /// ```
    @inlinable
    public var store: Property_Primitives.Property<Store, Self> {
        unsafe Property_Primitives.Property(self)
    }
}

// MARK: - Property Extension

extension Property_Primitives.Property
where Tag == UnsafeMutableRawBufferPointer.Store, Base == UnsafeMutableRawBufferPointer {

    /// Stores a value's bytes at the specified offset.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - offset: The offset from the start of the buffer at which to store.
    ///   - type: The type of the value being stored.
    @inlinable
    public func bytes<T>(
        of value: T,
        at offset: Memory.Address.Offset,
        as type: T.Type
    ) {
        unsafe base.storeBytes(of: value, toByteOffset: offset.vector.rawValue, as: type)
    }
}
