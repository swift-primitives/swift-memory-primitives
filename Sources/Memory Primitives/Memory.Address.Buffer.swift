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

extension Memory.Address {
    /// A non-null raw buffer pointer to a contiguous region of bytes.
    ///
    /// `Memory.Address.Buffer` wraps `Swift.UnsafeRawBufferPointer`,
    /// providing a primitives-ecosystem type for read-only raw buffer access
    /// with a **non-null guarantee**.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// let buffer: Memory.Address.Buffer = ...
    /// let byte = buffer[Index<UInt8>(5)]
    /// let count = buffer.count
    /// ```
    ///
    /// ## Mutable Variant
    ///
    /// For read-write access, use `Memory.Address.Buffer.Mutable`:
    ///
    /// ```swift
    /// var mutableBuffer: Memory.Address.Buffer.Mutable = .allocate(byteCount: 100, alignment: 8)
    /// mutableBuffer.copyMemory(from: source)
    /// mutableBuffer.deallocate()
    /// ```
    @safe
    public struct Buffer: Hashable, @unchecked Sendable {

        // MARK: - Stored Properties

        /// The underlying Swift stdlib buffer pointer, guaranteed non-null.
        @usableFromInline
        internal let _base: UnsafeRawBufferPointer

        /// The underlying stdlib buffer pointer.
        @inlinable
        public var base: UnsafeRawBufferPointer { unsafe _base }

        // MARK: - Initialization

        /// Creates a buffer from an UnsafeRawBufferPointer.
        @inlinable
        public init(_ buffer: UnsafeRawBufferPointer) {
            unsafe self._base = unsafe buffer
        }

        /// Creates a buffer from a start address and byte count.
        ///
        /// - Parameters:
        ///   - start: The base address of the buffer.
        ///   - count: The number of bytes in the buffer.
        @inlinable
        public init(start: Memory.Address, count: Index<UInt8>.Count) {
            unsafe self._base = unsafe UnsafeRawBufferPointer(start: start._rawPointer, count: count)
        }
    }
}

// MARK: - Properties

extension Memory.Address.Buffer {
    /// The start address of the buffer.
    ///
    /// The returned address is guaranteed non-null since this buffer type
    /// enforces a non-null invariant.
    @inlinable
    public var start: Memory.Address {
        unsafe Memory.Address(_base.baseAddress.unsafelyUnwrapped)
    }

    /// The number of bytes in the buffer.
    @inlinable
    public var count: Index<UInt8>.Count {
        Index<UInt8>.Count(__unchecked: (), unsafe _base.count)
    }

    /// A Boolean value indicating whether the buffer is empty.
    @inlinable
    public var isEmpty: Bool {
        unsafe _base.isEmpty
    }
}

// MARK: - Element Access

extension Memory.Address.Buffer {
    /// Accesses the byte at the given index.
    @inlinable
    public subscript(index: Index<UInt8>) -> UInt8 {
        unsafe _base[index]
    }
}

// MARK: - Read

extension Memory.Address.Buffer {
    /// Reads a value of the specified type from the buffer.
    ///
    /// - Parameters:
    ///   - offset: The byte offset from which to read.
    ///   - type: The type of value to read.
    /// - Returns: The value read from memory.
    @inlinable
    public func read<T>(from offset: Index<UInt8>.Offset = .zero, as type: T.Type) -> T {
        unsafe _base.load(fromByteOffset: offset.rawValue, as: type)
    }
}

// MARK: - Extraction (Slicing)

extension Memory.Address.Buffer {
    /// Returns a buffer over the bytes within the specified range.
    ///
    /// - Parameter bounds: A lazy range of byte indices specifying the subregion.
    /// - Returns: A buffer over the specified range.
    @inlinable
    public func extracting(_ bounds: Range.Lazy<Index<UInt8>>) -> Self {
        let startPtr = unsafe _base.baseAddress.unsafelyUnwrapped.advanced(by: bounds.start)
        return unsafe Self(UnsafeRawBufferPointer(start: startPtr, count: bounds.count))
    }
}

// MARK: - Type Reinterpretation

extension Memory.Address.Buffer {
    /// Executes a closure with the buffer's memory temporarily bound to a typed buffer.
    ///
    /// - Parameters:
    ///   - type: The type to temporarily bind the memory to.
    ///   - body: A closure that receives the typed buffer.
    /// - Returns: The return value of the closure.
    @inlinable
    public func withRebound<T, Result>(
        to type: T.Type,
        _ body: (UnsafeBufferPointer<T>) throws -> Result
    ) rethrows -> Result {
        try unsafe _base.withMemoryRebound(to: type) { typedBuffer in
            try unsafe body(typedBuffer)
        }
    }
}

// MARK: - CustomStringConvertible

extension Memory.Address.Buffer: CustomStringConvertible {
    public var description: String {
        unsafe "Memory.Address.Buffer(baseAddress: \(_base.baseAddress.unsafelyUnwrapped), count: \(_base.count))"
    }
}

// MARK: - CustomDebugStringConvertible

extension Memory.Address.Buffer: CustomDebugStringConvertible {
    public var debugDescription: String {
        unsafe "Memory.Address.Buffer(base: \(_base))"
    }
}

// MARK: - Equatable

extension Memory.Address.Buffer {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        unsafe Int(bitPattern: lhs._base.baseAddress) == Int(bitPattern: rhs._base.baseAddress)
            && lhs._base.count == rhs._base.count
    }
}

// MARK: - Hashable

extension Memory.Address.Buffer {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(unsafe Int(bitPattern: _base.baseAddress))
        hasher.combine(unsafe _base.count)
    }
}
