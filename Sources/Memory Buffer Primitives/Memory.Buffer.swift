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
nonisolated(unsafe) let _emptyBufferSentinel: UnsafeRawPointer = unsafe UnsafeRawPointer(_emptyBufferSentinelMutable)

extension Memory {
    /// A raw buffer with guaranteed non-null start address.
    ///
    /// `Memory.Buffer` provides a primitives-ecosystem type for
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
    /// let buffer: Memory.Buffer = ...
    /// let byte = buffer[Index<Memory>(5)]  // Valid if 5 < count
    /// let count = buffer.count
    /// ```
    ///
    /// ## Mutable Variant
    ///
    /// For read-write access, use `Memory.Buffer.Mutable`:
    ///
    /// ```swift
    /// var mutableBuffer: Memory.Buffer.Mutable = .allocate(count: 100, alignment: .doubleWord)
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
        internal let _count: Memory.Address.Count

        // MARK: - Initialization

        /// Creates a buffer from a start address and byte count.
        @inlinable
        public init(start: Memory.Address, count: Memory.Address.Count) {
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
            self._count = Memory.Address.Count(UInt(buffer.count))
        }
    }
}

// MARK: - Properties

extension Memory.Buffer {
    /// The start address of the buffer (guaranteed non-null).
    ///
    /// - Note: For empty buffers, this points to a sentinel address.
    ///   Only access memory within `0..<count`.
    @inlinable
    public var start: Memory.Address { _start }

    /// The number of bytes in the buffer.
    @inlinable
    public var count: Memory.Address.Count { _count }

    /// A Boolean value indicating whether the buffer is empty.
    @inlinable
    public var isEmpty: Bool { _count == .zero }
}


// MARK: - Element Access

extension Memory.Buffer {
    /// Accesses the byte at the given index.
    @inlinable
    public subscript(index: Index<Memory>) -> UInt8 {
        unsafe UnsafeRawPointer(_start).load(fromByteOffset: index, as: UInt8.self)
    }
}

// MARK: - Read

extension Memory.Buffer {
    /// Reads a value of the specified type from the buffer.
    ///
    /// - Parameters:
    ///   - offset: The byte offset from which to read.
    ///   - type: The type of value to read.
    /// - Returns: The value read from memory.
    @inlinable
    public func read<T>(from offset: Memory.Address.Offset = .zero, as type: T.Type) -> T {
        unsafe UnsafeRawPointer(_start).load(fromByteOffset: offset, as: type)
    }
}

// MARK: - Extraction (Slicing)


// MARK: - Safe Slicing

extension Memory.Buffer {
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
        start: Index<Memory>,
        count sliceCount: Memory.Address.Count
    ) -> Self? {
        // Bounds check: start must be valid endpoint
        guard start <= _count else {
            return nil
        }

        // Bounds check: slice must fit
        // remaining = buffer count - start position
        let remaining = _count.subtract.saturating(start.map(Cardinal.init))

        guard sliceCount <= remaining else {
            return nil
        }

        // _start is always non-null (sentinel-backed), so advanced(by:) is safe
        return Self(
            start: unsafe Memory.Address(UnsafeRawPointer(_start).advanced(by: start)),
            count: sliceCount
        )
    }
}

// MARK: - Type Reinterpretation

extension Memory.Buffer {
    /// Executes a closure with the buffer's memory temporarily bound to a typed buffer.
    ///
    /// - Parameters:
    ///   - type: The type to temporarily bind the memory to.
    ///   - body: A closure that receives the typed buffer.
    /// - Returns: The return value of the closure.
    @inlinable
    public func withRebound<T, Result, E: Swift.Error>(
        to type: T.Type,
        _ body: (UnsafeBufferPointer<T>) throws(E) -> Result
    ) throws(E) -> Result {
        try unsafe base.nullable.withMemoryRebound(to: type) { typedBuffer throws(E) in
            try unsafe body(typedBuffer)
        }
    }
}

// MARK: - CustomStringConvertible

extension Memory.Buffer: CustomStringConvertible {
    public var description: String {
        "Memory.Buffer(start: \(_start), count: \(_count.count))"
    }
}

// MARK: - CustomDebugStringConvertible

extension Memory.Buffer: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Memory.Buffer(start: \(_start), count: \(_count.count))"
    }
}

// MARK: - Equatable

extension Memory.Buffer {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._start == rhs._start && lhs._count == rhs._count
    }
}

// MARK: - Hashable

extension Memory.Buffer {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_start)
        hasher.combine(_count)
    }
}
