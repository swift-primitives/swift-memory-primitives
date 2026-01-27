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

extension Memory.Address.Buffer {
    /// A non-null mutable raw buffer pointer to a contiguous region of bytes.
    ///
    /// `Memory.Address.Buffer.Mutable` wraps `Swift.UnsafeMutableRawBufferPointer`,
    /// providing a primitives-ecosystem type for read-write raw buffer access
    /// with a **non-null guarantee**.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var buffer: Memory.Address.Buffer.Mutable = .allocate(byteCount: 100, alignment: 8)
    /// buffer.copyMemory(from: source)
    /// buffer.deallocate()
    /// ```
    ///
    /// ## Converting to Immutable
    ///
    /// ```swift
    /// let mutableBuffer: Memory.Address.Buffer.Mutable = ...
    /// let immutableBuffer: Memory.Address.Buffer = mutableBuffer.immutable
    /// ```
    @safe
    public struct Mutable: Hashable, @unchecked Sendable {

        // MARK: - Stored Properties

        /// The underlying Swift stdlib mutable buffer pointer, guaranteed non-null.
        @usableFromInline
        internal let _base: UnsafeMutableRawBufferPointer

        /// The underlying stdlib mutable buffer pointer.
        @inlinable
        public var base: UnsafeMutableRawBufferPointer { unsafe _base }

        // MARK: - Initialization

        /// Creates a mutable buffer from an UnsafeMutableRawBufferPointer.
        @inlinable
        public init(_ buffer: UnsafeMutableRawBufferPointer) {
            unsafe self._base = unsafe buffer
        }

        /// Creates a mutable buffer from a start address and byte count.
        ///
        /// - Parameters:
        ///   - start: The base address of the buffer.
        ///   - count: The number of bytes in the buffer.
        @inlinable
        public init(start: Memory.Address.Mutable, count: Index<UInt8>.Count) {
            unsafe self._base = unsafe UnsafeMutableRawBufferPointer(start: start._rawPointer, count: count)
        }
    }
}



// MARK: - Properties

extension Memory.Address.Buffer.Mutable {
    /// The base address of the buffer.
    ///
    /// The returned address is guaranteed non-null since this buffer type
    /// enforces a non-null invariant.
    @inlinable
    public var baseAddress: Memory.Address.Mutable {
        unsafe Memory.Address.Mutable(_base.baseAddress.unsafelyUnwrapped)
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

// MARK: - Allocation

extension Memory.Address.Buffer.Mutable {
    /// Allocates uninitialized memory for the specified number of bytes.
    ///
    /// - Parameters:
    ///   - byteCount: The number of bytes to allocate.
    ///   - alignment: The alignment of the allocated memory, in bytes.
    /// - Returns: A buffer to the allocated memory (never null; allocation failure traps).
    @inlinable
    public static func allocate(
        count: Index<UInt8>.Count,
        alignment: Index<UInt8>.Count
    ) -> Self {
        unsafe Self(UnsafeMutableRawBufferPointer.allocate(count: count, alignment: alignment))
    }

    /// Deallocates the memory referenced by this buffer.
    @inlinable
    public func deallocate() {
        unsafe _base.deallocate()
    }
}

// MARK: - Element Access

extension Memory.Address.Buffer.Mutable {
    /// Accesses the byte at the given index.
    @inlinable
    public subscript(
        index: Index<UInt8>
    ) -> UInt8 {
        get { unsafe _base[index] }
        nonmutating set { unsafe _base[index] = newValue }
    }
}

// MARK: - Load and Store

extension Memory.Address.Buffer.Mutable {
    /// Reads a value of the specified type from the buffer.
    ///
    /// - Parameters:
    ///   - offset: The byte offset from which to read.
    ///   - type: The type of value to read.
    /// - Returns: The value read from memory.
    @inlinable
    public func load<T>(
        from offset: Index<UInt8>.Offset = .zero,
        as type: T.Type
    ) -> T {
        unsafe _base.load(fromByteOffset: offset.rawValue, as: type)
    }

    /// Stores a value of the specified type to the buffer.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - offset: The byte offset at which to store.
    ///   - type: The type of value to store.
    @inlinable
    public func storeBytes<T>(of value: T, toByteOffset offset: Index<UInt8>.Offset = .zero, as type: T.Type) {
        unsafe _base.storeBytes(of: value, toByteOffset: offset.rawValue, as: type)
    }
}

// MARK: - Initialization

extension Memory.Address.Buffer.Mutable {
    /// Initializes the buffer's memory as the specified type with a repeated value.
    ///
    /// - Parameters:
    ///   - type: The type to initialize the memory as.
    ///   - repeating: The value to copy into each element.
    /// - Returns: A typed buffer to the initialized memory.
    @inlinable
    @discardableResult
    public func initializeMemory<T>(as type: T.Type, repeating value: T) -> UnsafeMutableBufferPointer<T> {
        unsafe _base.initializeMemory(as: type, repeating: value)
    }

    /// Initializes the buffer's memory as the specified type from a source collection.
    ///
    /// - Parameters:
    ///   - type: The type to initialize the memory as.
    ///   - source: A collection of values to copy.
    /// - Returns: A tuple containing an iterator to remaining source elements and a typed buffer to initialized memory.
    @inlinable
    public func initializeMemory<S: Swift.Sequence>(as type: S.Element.Type, from source: S) -> (unwritten: S.Iterator, initialized: UnsafeMutableBufferPointer<S.Element>) {
        unsafe _base.initializeMemory(as: type, from: source)
    }
}

// MARK: - Copy Operations

extension Memory.Address.Buffer.Mutable {
    /// Copies bytes from a source buffer.
    ///
    /// - Parameter source: The source buffer to copy from.
    @inlinable
    public func copyMemory(from source: Memory.Address.Buffer) {
        unsafe _base.copyMemory(from: source._base)
    }

    /// Copies bytes from a raw buffer pointer.
    ///
    /// - Parameter source: The source buffer to copy from.
    @inlinable
    public func copyMemory(from source: UnsafeRawBufferPointer) {
        unsafe _base.copyMemory(from: source)
    }

    /// Copies bytes from a typed collection.
    ///
    /// - Parameter source: A collection of bytes to copy.
    @inlinable
    public func copyBytes<C: Collection>(from source: C) where C.Element == UInt8 {
        unsafe _base.copyBytes(from: source)
    }
}

// MARK: - Extraction (Slicing)

extension Memory.Address.Buffer.Mutable {
    /// Returns a mutable buffer over the bytes within the specified range.
    ///
    /// - Parameter bounds: A lazy range of byte indices specifying the subregion.
    /// - Returns: A mutable buffer over the specified range.
    @inlinable
    public func extracting(
        _ bounds: Range.Lazy<Index<UInt8>>
    ) -> Self {
        let startPtr = unsafe _base.baseAddress.unsafelyUnwrapped.advanced(by: bounds.start)
        return unsafe Self(UnsafeMutableRawBufferPointer(start: startPtr, count: bounds.count))
    }
}

// MARK: - Type Reinterpretation

extension Memory.Address.Buffer.Mutable {
    /// Executes a closure with the buffer's memory temporarily bound to a typed buffer.
    ///
    /// - Parameters:
    ///   - type: The type to temporarily bind the memory to.
    ///   - body: A closure that receives the typed mutable buffer.
    /// - Returns: The return value of the closure.
    @inlinable
    public func withMemoryRebound<T, Result>(
        to type: T.Type,
        _ body: (UnsafeMutableBufferPointer<T>) throws -> Result
    ) rethrows -> Result {
        try unsafe _base.withMemoryRebound(to: type) { typedBuffer in
            try unsafe body(typedBuffer)
        }
    }
}

// MARK: - Conversion

extension Memory.Address.Buffer.Mutable {
    /// Creates an immutable buffer from this mutable buffer.
    @inlinable
    public var immutable: Memory.Address.Buffer {
        unsafe Memory.Address.Buffer(UnsafeRawBufferPointer(_base))
    }
}

// MARK: - CustomStringConvertible

extension Memory.Address.Buffer.Mutable: CustomStringConvertible {
    public var description: String {
        unsafe "Memory.Address.Buffer.Mutable(baseAddress: \(_base.baseAddress.unsafelyUnwrapped), count: \(_base.count))"
    }
}

// MARK: - CustomDebugStringConvertible

extension Memory.Address.Buffer.Mutable: CustomDebugStringConvertible {
    public var debugDescription: String {
        unsafe "Memory.Address.Buffer.Mutable(base: \(_base))"
    }
}

// MARK: - Equatable

extension Memory.Address.Buffer.Mutable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        unsafe Int(bitPattern: lhs._base.baseAddress) == Int(bitPattern: rhs._base.baseAddress)
            && lhs._base.count == rhs._base.count
    }
}

// MARK: - Hashable

extension Memory.Address.Buffer.Mutable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(unsafe Int(bitPattern: _base.baseAddress))
        hasher.combine(unsafe _base.count)
    }
}
