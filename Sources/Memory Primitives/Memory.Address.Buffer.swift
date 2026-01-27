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

/// Mutable singleton sentinel for empty buffers.
///
/// ## Invariants
///
/// - Allocated once at startup, never deallocated
/// - Page-aligned (4096 bytes) to maintain prior address invariant
/// - Provenance-correct: backed by real allocation, valid for pointer arithmetic
/// - Must NEVER be dereferenced (valid only as a sentinel address)
/// - Valid for empty buffers where count == 0
///
/// This approach:
/// - Provides valid pointer provenance for Swift 6.2+ strict memory safety
/// - Has no failure mode (allocation failure traps)
/// - Minimal overhead (single 1-byte allocation per process)
@usableFromInline
nonisolated(unsafe) let _emptyBufferSentinelMutable: UnsafeMutableRawPointer = {
    UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 4096)
}()

/// Immutable singleton sentinel derived from mutable sentinel.
///
/// See `_emptyBufferSentinelMutable` for invariants.
@usableFromInline
nonisolated(unsafe) let _emptyBufferSentinel: UnsafeRawPointer =
    UnsafeRawPointer(_emptyBufferSentinelMutable)

extension Memory.Address {
    /// A raw buffer with guaranteed non-null start address.
    ///
    /// `Memory.Address.Buffer` provides a primitives-ecosystem type for
    /// read-only raw buffer access with a **non-null guarantee**.
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
    /// let buffer: Memory.Address.Buffer = ...
    /// let byte = buffer[Index<UInt8>(5)]  // Valid if 5 < count
    /// let count = buffer.count
    /// ```
    ///
    /// ## Mutable Variant
    ///
    /// For read-write access, use `Memory.Address.Buffer.Mutable`:
    ///
    /// ```swift
    /// var mutableBuffer: Memory.Address.Buffer.Mutable = .allocate(count: 100, alignment: 8)
    /// mutableBuffer.copy(from: source)
    /// mutableBuffer.deallocate()
    /// ```
    @safe
    public struct Buffer: Hashable, @unchecked Sendable {

        // MARK: - Stored Properties

        /// Non-null start address. For empty buffers, points to sentinel.
        @usableFromInline
        internal let _start: Memory.Address

        /// Byte count.
        @usableFromInline
        internal let _count: Index<UInt8>.Count

        // MARK: - Initialization

        /// Creates a buffer from a start address and byte count.
        @inlinable
        public init(start: Memory.Address, count: Index<UInt8>.Count) {
            self._start = start
            self._count = count
        }

        /// Creates an empty buffer.
        @inlinable
        public init() {
            unsafe self._start = Memory.Address(_emptyBufferSentinel)
            self._count = .zero
        }

        /// Creates a buffer from an UnsafeRawBufferPointer.
        ///
        /// If the source buffer is empty (nil baseAddress), uses sentinel.
        @inlinable
        public init(_ buffer: UnsafeRawBufferPointer) {
            if let baseAddress = buffer.baseAddress {
                unsafe self._start = Memory.Address(baseAddress)
            } else {
                unsafe self._start = Memory.Address(_emptyBufferSentinel)
            }
            self._count = Index<UInt8>.Count(UInt(buffer.count))
        }
    }
}

// MARK: - Properties

extension Memory.Address.Buffer {
    /// The start address of the buffer (guaranteed non-null).
    ///
    /// - Note: For empty buffers, this points to a sentinel address.
    ///   Only access memory within `0..<count`.
    @inlinable
    public var start: Memory.Address { _start }

    /// The number of bytes in the buffer.
    @inlinable
    public var count: Index<UInt8>.Count { _count }

    /// A Boolean value indicating whether the buffer is empty.
    @inlinable
    public var isEmpty: Bool { _count == .zero }
}

// MARK: - Interop Views

extension Memory.Address.Buffer {
    /// The underlying stdlib buffer pointer (stdlib-normal form).
    ///
    /// For empty buffers, returns `(start: nil, count: 0)` per stdlib convention.
    /// Use this for idiomatic Swift stdlib interop.
    @inlinable
    public var base: UnsafeRawBufferPointer {
        if isEmpty {
            return unsafe UnsafeRawBufferPointer(start: nil, count: 0)
        }
        return unsafe UnsafeRawBufferPointer(
            start: _start._rawPointer,
            count: Int(_count.count.rawValue)
        )
    }

    /// The underlying stdlib buffer pointer with non-null start.
    ///
    /// For empty buffers, returns `(start: sentinel, count: 0)`.
    /// Use this for C APIs that reject null pointers even with size 0.
    @inlinable
    public var baseNonNull: UnsafeRawBufferPointer {
        unsafe UnsafeRawBufferPointer(
            start: _start._rawPointer,
            count: Int(_count.count.rawValue)
        )
    }
}

// MARK: - Element Access

extension Memory.Address.Buffer {
    /// Accesses the byte at the given index.
    @inlinable
    public subscript(index: Index<UInt8>) -> UInt8 {
        unsafe _start._rawPointer.load(fromByteOffset: Int(index.position.rawValue), as: UInt8.self)
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
        unsafe _start._rawPointer.load(fromByteOffset: offset.vector.rawValue, as: type)
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
        // _start is always non-null (sentinel-backed), so pointer arithmetic is safe
        let newStart = unsafe Memory.Address(
            _start._rawPointer.advanced(by: Int(bounds.start.position.rawValue))
        )
        let newCount = bounds.count.retag(UInt8.self)
        return Self(start: newStart, count: newCount)
    }
}

// MARK: - Safe Slicing

extension Memory.Address.Buffer {
    /// Returns a buffer slice if bounds are valid, nil otherwise.
    ///
    /// ## Bounds Validation
    ///
    /// - `start` must be a valid endpoint (`start <= count`)
    /// - `sliceCount` must fit: `start + sliceCount <= count`
    ///
    /// - Parameters:
    ///   - start: Starting byte position within the buffer.
    ///   - sliceCount: Number of bytes in the slice.
    /// - Returns: A buffer over the slice, or nil if bounds are invalid.
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
        let newStart = unsafe Memory.Address(
            _start._rawPointer.advanced(by: Int(start.position.rawValue))
        )
        return Self(start: newStart, count: sliceCount)
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
        try unsafe base.withMemoryRebound(to: type) { typedBuffer in
            try unsafe body(typedBuffer)
        }
    }
}

// MARK: - CustomStringConvertible

extension Memory.Address.Buffer: CustomStringConvertible {
    public var description: String {
        "Memory.Address.Buffer(start: \(_start), count: \(_count.count.rawValue))"
    }
}

// MARK: - CustomDebugStringConvertible

extension Memory.Address.Buffer: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Memory.Address.Buffer(start: \(_start), count: \(_count.count.rawValue))"
    }
}

// MARK: - Equatable

extension Memory.Address.Buffer {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        unsafe Int(bitPattern: lhs._start._rawPointer) == Int(bitPattern: rhs._start._rawPointer)
            && lhs._count == rhs._count
    }
}

// MARK: - Hashable

extension Memory.Address.Buffer {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(unsafe Int(bitPattern: _start._rawPointer))
        hasher.combine(_count.count.rawValue)
    }
}
