//
//  Index+UnsafeMutableRawPointer.Store.swift
//  swift-index-primitives
//
//  Created by Coen ten Thije Boonkkamp on 27/01/2026.
//

import Property_Primitives

// MARK: - Tag Type

extension UnsafeMutableRawPointer {
    /// Tag for store operations on raw pointers.
    public enum Store {}
}

// MARK: - Accessor

extension UnsafeMutableRawPointer {
    /// Namespace for store operations.
    ///
    /// Use this accessor for storing values as bytes:
    ///
    /// ```swift
    /// pointer.store.bytes(of: value, at: offset, as: Int.self)
    /// ```
    @inlinable
    public var store: Property_Primitives.Property<Store, Self> {
        unsafe Property_Primitives.Property(self)
    }
}

// MARK: - Property Extension

extension Property_Primitives.Property
where Tag == UnsafeMutableRawPointer.Store, Base == UnsafeMutableRawPointer {

    /// Stores a value's bytes at the specified offset.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - offset: The offset from this pointer at which to store the value.
    ///   - type: The type of the value being stored.
    @inlinable
    public func bytes<T>(
        of value: T,
        at offset: Index_Primitives_Core.Index<UInt8>.Offset,
        as type: T.Type
    ) {
        unsafe base.storeBytes(of: value, toByteOffset: offset.vector.rawValue, as: type)
    }
}
