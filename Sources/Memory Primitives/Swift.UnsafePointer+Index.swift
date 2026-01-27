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
public import Range_Primitives

// MARK: - UnsafeRawBufferPointer + Index

extension UnsafeRawBufferPointer {
    /// Creates a buffer pointer from a start address and typed count.
    @inlinable
    public init(start: UnsafeRawPointer?, count: Index_Primitives.Index<UInt8>.Count) {
        unsafe self.init(start: start, count: Int(count.rawValue))
    }

    /// Creates a buffer pointer from a start address and range count.
    @inlinable
    public init(start: UnsafeRawPointer?, count: Range.Index.Count) {
        unsafe self.init(start: start, count: Int(count.rawValue))
    }

    /// Accesses the byte at the given typed index.
    @inlinable
    public subscript(_ index: Index_Primitives.Index<UInt8>) -> UInt8 {
        unsafe self[Int(index.position.rawValue)]
    }
}

// MARK: - UnsafeMutableRawBufferPointer + Index

extension UnsafeMutableRawBufferPointer {
    /// Creates a mutable buffer pointer from a start address and typed count.
    @inlinable
    public init(start: UnsafeMutableRawPointer?, count: Index_Primitives.Index<UInt8>.Count) {
        unsafe self.init(start: start, count: Int(count.rawValue))
    }

    /// Creates a mutable buffer pointer from a start address and range count.
    @inlinable
    public init(start: UnsafeMutableRawPointer?, count: Range.Index.Count) {
        unsafe self.init(start: start, count: Int(count.rawValue))
    }

    /// Allocates uninitialized memory with typed count and alignment.
    @inlinable
    public static func allocate(
        count: Index_Primitives.Index<UInt8>.Count,
        alignment: Index_Primitives.Index<UInt8>.Count
    ) -> Self {
        Self.allocate(byteCount: Int(count.rawValue), alignment: Int(alignment.rawValue))
    }

    /// Accesses the byte at the given typed index.
    @inlinable
    public subscript(_ index: Index_Primitives.Index<UInt8>) -> UInt8 {
        get { unsafe self[Int(index.position.rawValue)] }
        nonmutating set { unsafe self[Int(index.position.rawValue)] = newValue }
    }
}

// MARK: - UnsafeMutableRawPointer + Index

extension UnsafeMutableRawPointer {
    /// Allocates uninitialized memory with typed count and alignment.
    @inlinable
    public static func allocate(
        count: Index_Primitives.Index<UInt8>.Count,
        alignment: Index_Primitives.Index<UInt8>.Count
    ) -> Self {
        Self.allocate(byteCount: Int(count.rawValue), alignment: Int(alignment.rawValue))
    }

    /// Initializes memory as the specified type with a repeated value.
    @inlinable
    @discardableResult
    public func initializeMemory<T>(
        as type: T.Type,
        repeating value: T,
        count: Index_Primitives.Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe self.initializeMemory(as: type, repeating: value, count: Int(count.rawValue))
    }

    /// Initializes memory as the specified type from a source buffer.
    @inlinable
    @discardableResult
    public func initializeMemory<T>(
        as type: T.Type,
        from source: UnsafePointer<T>,
        count: Index_Primitives.Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe self.initializeMemory(as: type, from: source, count: Int(count.rawValue))
    }

    /// Initializes memory by moving values from a source.
    @inlinable
    @discardableResult
    public func moveInitializeMemory<T>(
        as type: T.Type,
        from source: UnsafeMutablePointer<T>,
        count: Index_Primitives.Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe self.moveInitializeMemory(as: type, from: source, count: Int(count.rawValue))
    }

    /// Binds the memory to the specified type with a typed capacity.
    @inlinable
    @discardableResult
    public func bindMemory<T>(
        to type: T.Type,
        capacity: Index_Primitives.Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe self.bindMemory(to: type, capacity: Int(capacity.rawValue))
    }

    /// Returns a pointer offset by the specified typed byte offset.
    @inlinable
    public func advanced(by offset: Index_Primitives.Index<UInt8>.Offset) -> Self {
        unsafe self.advanced(by: offset.rawValue)
    }

    /// Copies bytes from a source with a typed byte count.
    @inlinable
    public func copyMemory(from source: UnsafeRawPointer, count: Index_Primitives.Index<UInt8>.Count) {
        unsafe self.copyMemory(from: source, byteCount: Int(count.rawValue))
    }
}

// MARK: - UnsafeRawPointer + Index

extension UnsafeRawPointer {
    /// Returns a pointer offset by the specified typed byte offset.
    @inlinable
    public func advanced(by offset: Index_Primitives.Index<UInt8>.Offset) -> Self {
        unsafe self.advanced(by: offset.rawValue)
    }

    /// Returns a pointer offset by the specified range index position.
    @inlinable
    public func advanced(by index: Range.Index) -> Self {
        unsafe self.advanced(by: Int(index.position.rawValue))
    }
}

// MARK: - UnsafeMutableRawPointer + Range.Index

extension UnsafeMutableRawPointer {
    /// Returns a pointer offset by the specified range index position.
    @inlinable
    public func advanced(by index: Range.Index) -> Self {
        unsafe self.advanced(by: Int(index.position.rawValue))
    }
}
