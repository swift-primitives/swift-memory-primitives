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

public import Memory_Address_Primitives

// MARK: - UnsafeRawPointer + Index

extension UnsafeRawPointer {
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
