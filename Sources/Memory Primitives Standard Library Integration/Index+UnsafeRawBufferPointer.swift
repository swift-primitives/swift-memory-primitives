//
//  File.swift
//  swift-index-primitives
//
//  Created by Coen ten Thije Boonkkamp on 27/01/2026.
//

// MARK: - UnsafeRawBufferPointer + Index

extension UnsafeRawBufferPointer {
    /// Creates a buffer pointer from a start address and typed count.
    ///
    /// Disfavored so stdlib's `init(start:count:)` is preferred when `.zero` is used.
    @inlinable
    @_disfavoredOverload
    public init(
        start: UnsafeRawPointer?,
        count: Index_Primitives_Core.Index<UInt8>.Count
    ) {
        unsafe try! self.init(
            start: start,
            count: Int(count.count)
        )
    }

    /// Accesses the byte at the given typed index.
    @inlinable
    public subscript(
        _ index: Index_Primitives_Core.Index<UInt8>
    ) -> UInt8 {
        unsafe try! self[Int(index.position)]
    }

    /// Returns a new instance of the given type, read from the specified offset.
    ///
    /// - Parameters:
    ///   - offset: The offset from the start of the buffer at which to read.
    ///   - type: The type of the value to read.
    /// - Returns: A new instance of the given type.
    @inlinable
    public func load<T>(
        fromByteOffset offset: Index_Primitives_Core.Index<UInt8>.Offset,
        as type: T.Type
    ) -> T {
        unsafe self.load(fromByteOffset: offset.vector.rawValue, as: type)
    }
}
