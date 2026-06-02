//
//  Index+UnsafeMutableRawPointer.swift
//  swift-index-primitives
//
//  Created by Coen ten Thije Boonkkamp on 27/01/2026.
//

// MARK: - UnsafeMutableRawPointer + Index

public import Memory_Address_Primitives
public import Memory_Alignment_Primitives

extension UnsafeMutableRawPointer {
    /// Allocates uninitialized memory with typed count and alignment.
    @inlinable
    public static func allocate(
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) -> Self {
        Self.allocate(byteCount: Int(bitPattern: count), alignment: alignment.magnitude())
    }

    /// Returns a pointer offset by the specified typed byte offset.
    @inlinable
    public func advanced(
        by offset: Memory.Address.Offset
    ) -> Self {
        unsafe self.advanced(by: offset.vector.rawValue)
    }

    /// Returns a new instance of the given type, read from the specified offset.
    ///
    /// - Parameters:
    ///   - offset: The offset from this pointer at which to read a value.
    ///   - type: The type of the value to read.
    /// - Returns: A new instance of the given type.
    @inlinable
    public func load<T>(
        fromByteOffset offset: Memory.Address.Offset,
        as type: T.Type
    ) -> T {
        unsafe self.load(fromByteOffset: offset.vector.rawValue, as: type)
    }
}
