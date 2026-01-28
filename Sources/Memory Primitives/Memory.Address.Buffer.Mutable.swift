// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-memory-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-memory-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Index_Primitives
public import Range_Primitives

/// Mutable sentinel re-exported from Memory.Address.Buffer.swift.
///
/// Uses the canonical mutable sentinel directly—no cast needed.
/// See `_emptyBufferSentinelMutable` in Memory.Address.Buffer.swift for invariants.
@usableFromInline
nonisolated(unsafe) let _emptyMutableBufferSentinel: UnsafeMutableRawPointer =
    _emptyBufferSentinelMutable

extension Memory.Address.Buffer {
    /// A mutable raw buffer with guaranteed non-null start address.
    ///
    /// `Memory.Address.Buffer.Mutable` provides a primitives-ecosystem type for
    /// read-write raw buffer access with a **non-null guarantee**.
    ///
    /// ## Invariants
    ///
    /// - `start` is always non-null (even for empty buffers)
    /// - Memory is only valid to access within `0..<count`
    /// - For empty buffers, `start` points to a sentinel; do not dereference
    /// - Subscript access MUST be within bounds (undefined behavior otherwise)
    ///
    /// ## Usage
    ///
    /// ```swift
    /// var buffer: Memory.Address.Buffer.Mutable = .allocate(count: 100, alignment: 8)
    /// buffer.copy(from: source)
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

        /// Non-null start address. For empty buffers, points to sentinel.
        @usableFromInline
        internal let _start: Memory.Address.Mutable

        /// Byte count.
        @usableFromInline
        internal let _count: Index<UInt8>.Count

        // MARK: - Initialization

        /// Creates a mutable buffer from a start address and byte count.
        @inlinable
        public init(start: Memory.Address.Mutable, count: Index<UInt8>.Count) {
            self._start = start
            self._count = count
        }

        /// Creates an empty mutable buffer.
        @inlinable
        public init() {
            unsafe self._start = Memory.Address.Mutable(_emptyMutableBufferSentinel)
            self._count = .zero
        }

        /// Creates a mutable buffer from an UnsafeMutableRawBufferPointer.
        ///
        /// If the source buffer is empty (nil baseAddress), uses sentinel.
        @inlinable
        public init(_ buffer: UnsafeMutableRawBufferPointer) {
            if let baseAddress = buffer.baseAddress {
                unsafe self._start = Memory.Address.Mutable(baseAddress)
            } else {
                unsafe self._start = Memory.Address.Mutable(_emptyMutableBufferSentinel)
            }
            self._count = Index<UInt8>.Count(UInt(buffer.count))
        }
    }
}

// MARK: - Properties

extension Memory.Address.Buffer.Mutable {
    /// The start address of the buffer (guaranteed non-null).
    ///
    /// - Note: For empty buffers, this points to a sentinel address.
    ///   Only access memory within `0..<count`.
    @inlinable
    public var start: Memory.Address.Mutable { _start }

    /// The number of bytes in the buffer.
    @inlinable
    public var count: Index<UInt8>.Count { _count }

    /// A Boolean value indicating whether the buffer is empty.
    @inlinable
    public var isEmpty: Bool { _count == .zero }
}

// MARK: - Interop Views

extension Memory.Address.Buffer.Mutable {
    /// The underlying stdlib buffer pointer (stdlib-normal form).
    ///
    /// For empty buffers, returns `(start: nil, count: 0)` per stdlib convention.
    /// Use this for idiomatic Swift stdlib interop.
    @inlinable
    public var base: UnsafeMutableRawBufferPointer {
        if isEmpty {
            return unsafe UnsafeMutableRawBufferPointer(start: nil, count: 0)
        }
        return unsafe UnsafeMutableRawBufferPointer(
            start: _start._rawPointer,
            count: Int(_count.count)
        )
    }

    /// The underlying stdlib buffer pointer with non-null start.
    ///
    /// For empty buffers, returns `(start: sentinel, count: 0)`.
    /// Use this for C APIs that reject null pointers even with size 0.
    @inlinable
    public var baseNonNull: UnsafeMutableRawBufferPointer {
        unsafe UnsafeMutableRawBufferPointer(
            start: _start._rawPointer,
            count: Int(_count.count)
        )
    }
}

// MARK: - Allocation

extension Memory.Address.Buffer.Mutable {
    /// Allocates uninitialized memory for the specified number of bytes.
    ///
    /// - Parameters:
    ///   - count: The number of bytes to allocate.
    ///   - alignment: The alignment of the allocated memory, in bytes.
    /// - Returns: A buffer to the allocated memory (never null; allocation failure traps).
    @inlinable
    public static func allocate(
        count: Index<UInt8>.Count,
        alignment: Index<UInt8>.Count
    ) -> Self {
        let buffer = unsafe UnsafeMutableRawBufferPointer.allocate(
            count: count,
            alignment: alignment
        )
        return unsafe Self(buffer)
    }

    /// Deallocates the memory referenced by this buffer.
    @inlinable
    public func deallocate() {
        unsafe _start._rawPointer.deallocate()
    }
}

// MARK: - Element Access

extension Memory.Address.Buffer.Mutable {
    /// Accesses the byte at the given index.
    @inlinable
    public subscript(index: Index<UInt8>) -> UInt8 {
        get {
            unsafe _start._rawPointer.load(fromByteOffset: Int(index.position), as: UInt8.self)
        }
        nonmutating set {
            unsafe _start._rawPointer.storeBytes(of: newValue, toByteOffset: Int(index.position), as: UInt8.self)
        }
    }
}

// MARK: - Read and Store

extension Memory.Address.Buffer.Mutable {
    /// Reads a value of the specified type from the buffer.
    ///
    /// - Parameters:
    ///   - offset: The byte offset from which to read.
    ///   - type: The type of value to read.
    /// - Returns: The value read from memory.
    @inlinable
    public func read<T>(
        from offset: Index<UInt8>.Offset = .zero,
        as type: T.Type
    ) -> T {
        unsafe _start._rawPointer.load(fromByteOffset: offset.vector.rawValue, as: type)
    }

    /// Stores a value of the specified type to the buffer.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - offset: The byte offset at which to store.
    ///   - type: The type of value to store.
    @inlinable
    public func store<T>(_ value: T, at offset: Index<UInt8>.Offset = .zero, as type: T.Type) {
        unsafe _start._rawPointer.storeBytes(of: value, toByteOffset: offset.vector.rawValue, as: type)
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
    public func initialize<T>(as type: T.Type, repeating value: T) -> UnsafeMutableBufferPointer<T> {
        unsafe base.initializeMemory(as: type, repeating: value)
    }

    /// Initializes the buffer's memory as the specified type from a source collection.
    ///
    /// - Parameters:
    ///   - type: The type to initialize the memory as.
    ///   - source: A collection of values to copy.
    /// - Returns: A tuple containing an iterator to remaining source elements and a typed buffer to initialized memory.
    @inlinable
    public func initialize<S: Swift.Sequence>(as type: S.Element.Type, from source: S) -> (unwritten: S.Iterator, initialized: UnsafeMutableBufferPointer<S.Element>) {
        unsafe base.initializeMemory(as: type, from: source)
    }
}

// MARK: - Copy Operations

extension Memory.Address.Buffer.Mutable {
    /// Copies bytes from a source buffer.
    ///
    /// - Parameter source: The source buffer to copy from.
    @inlinable
    public func copy(from source: Memory.Address.Buffer) {
        unsafe base.copyMemory(from: source.base)
    }

    /// Copies bytes from a raw buffer pointer.
    ///
    /// - Parameter source: The source buffer to copy from.
    @inlinable
    public func copy(from source: UnsafeRawBufferPointer) {
        unsafe base.copyMemory(from: source)
    }

    /// Copies bytes from a typed collection.
    ///
    /// - Parameter source: A collection of bytes to copy.
    @inlinable
    public func copy<C: Collection>(bytes source: C) where C.Element == UInt8 {
        unsafe base.copyBytes(from: source)
    }
}

// MARK: - Extraction (Slicing)

extension Memory.Address.Buffer.Mutable {
    /// Returns a mutable buffer over the bytes within the specified range.
    ///
    /// - Parameter bounds: A lazy range of byte indices specifying the subregion.
    /// - Returns: A mutable buffer over the specified range.
    @inlinable
    public func extracting(_ bounds: Range.Lazy<Index<UInt8>>) -> Self {
        // _start is always non-null (sentinel-backed), so pointer arithmetic is safe
        let newStart = unsafe Memory.Address.Mutable(
            _start._rawPointer.advanced(by: Int(bounds.start.position))
        )
        let newCount = bounds.count.retag(UInt8.self)
        return Self(start: newStart, count: newCount)
    }
}

// MARK: - Safe Slicing

extension Memory.Address.Buffer.Mutable {
    /// Returns a mutable buffer slice if bounds are valid, nil otherwise.
    ///
    /// ## Bounds Validation
    ///
    /// - `start` must be a valid endpoint (`start <= count`)
    /// - `sliceCount` must fit: `start + sliceCount <= count`
    ///
    /// - Parameters:
    ///   - start: Starting byte position within the buffer.
    ///   - sliceCount: Number of bytes in the slice.
    /// - Returns: A mutable buffer over the slice, or nil if bounds are invalid.
    @inlinable
    public func slice(
        start: Index<UInt8>,
        count sliceCount: Index<UInt8>.Count
    ) -> Self? {
        // Bounds check: start must be valid endpoint
        guard start <= _count else {
            return nil
        }

        // Bounds check: slice must fit
        // remaining = buffer count - start position
        let startAsCount = Index<UInt8>.Count(start)
        let remaining = _count.count.subtract.saturating(startAsCount.count)

        guard sliceCount.count <= remaining else {
            return nil
        }

        // Compute new start using pointer arithmetic
        // _start is always non-null (sentinel-backed), so advanced(by:) is safe
        let newStart = unsafe Memory.Address.Mutable(
            _start._rawPointer.advanced(by: Int(start.position))
        )
        return Self(start: newStart, count: sliceCount)
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
    public func withRebound<T, Result>(
        to type: T.Type,
        _ body: (UnsafeMutableBufferPointer<T>) throws -> Result
    ) rethrows -> Result {
        try unsafe base.withMemoryRebound(to: type) { typedBuffer in
            try unsafe body(typedBuffer)
        }
    }
}

// MARK: - Conversion

extension Memory.Address.Buffer.Mutable {
    /// Creates an immutable buffer from this mutable buffer.
    @inlinable
    public var immutable: Memory.Address.Buffer {
        Memory.Address.Buffer(start: _start.immutable, count: _count)
    }
}

// MARK: - CustomStringConvertible

extension Memory.Address.Buffer.Mutable: CustomStringConvertible {
    public var description: String {
        "Memory.Address.Buffer.Mutable(start: \(_start), count: \(_count.count))"
    }
}

// MARK: - CustomDebugStringConvertible

extension Memory.Address.Buffer.Mutable: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Memory.Address.Buffer.Mutable(start: \(_start), count: \(_count.count))"
    }
}

// MARK: - Equatable

extension Memory.Address.Buffer.Mutable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        unsafe Int(bitPattern: lhs._start._rawPointer) == Int(bitPattern: rhs._start._rawPointer)
            && lhs._count == rhs._count
    }
}

// MARK: - Hashable

extension Memory.Address.Buffer.Mutable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(unsafe Int(bitPattern: _start._rawPointer))
        hasher.combine(_count.count)
    }
}
