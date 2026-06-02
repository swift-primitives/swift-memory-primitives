//
//  Index+UnsafeMutableRawBufferPointer.swift
//  swift-index-primitives
//
//  Created by Coen ten Thije Boonkkamp on 27/01/2026.
//

// MARK: - UnsafeMutableRawBufferPointer + Index

public import Index_Primitives
public import Memory_Address_Primitives
public import Memory_Alignment_Primitives

extension UnsafeMutableRawBufferPointer {
    /// Creates a mutable buffer pointer from a start address and typed count.
    ///
    /// Disfavored so stdlib's `init(start:count:)` is preferred when `.zero` is used.
    @inlinable
    @_disfavoredOverload
    public init(
        start: UnsafeMutableRawPointer?,
        count: Memory.Address.Count
    ) {
        unsafe self.init(
            start: start,
            count: Int(bitPattern: count)
        )
    }

    /// Allocates uninitialized memory with typed count and alignment.
    ///
    /// Disfavored so stdlib's `allocate(byteCount:alignment:)` is preferred.
    @inlinable
    @_disfavoredOverload
    public static func allocate(
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) -> Self {
        Self.allocate(
            byteCount: Int(bitPattern: count),
            alignment: alignment.magnitude()
        )
    }

    /// Accesses the byte at the given typed index.
    @inlinable
    public subscript(
        _ index: Index_Primitives.Index<Memory>
    ) -> UInt8 {
        get {
            unsafe self[Int(bitPattern: index.position)]
        }
        nonmutating set {
            unsafe self[Int(bitPattern: index.position)] = newValue
        }
    }

    /// Returns a new instance of the given type, read from the specified offset.
    ///
    /// - Parameters:
    ///   - offset: The offset from the start of the buffer at which to read.
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
