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

// MARK: - Pointer Access

extension Memory.Inline where Element: ~Copyable {
    /// Returns a mutable pointer to the element at the given slot.
    ///
    /// This is the primitive address computation for inline memory.
    /// The pointer is derived from the `_storage` field's address and
    /// advanced by `slot × MemoryLayout<Element>.stride`.
    ///
    /// The pointer is valid for the lifetime of `self`. For ~Copyable
    /// `_storage` fields, `withUnsafePointer(to: _storage)` gives the
    /// in-place address (borrowing a ~Copyable type cannot create a copy).
    ///
    /// - Parameter slot: The zero-based slot index.
    /// - Returns: A mutable pointer to the element at `slot`.
    /// - Precondition: `slot` must be in `0 ..< capacity`.
    @unsafe
    @inlinable
    public func pointer(at slot: Int) -> UnsafeMutablePointer<Element> {
        precondition(slot >= 0 && slot < capacity, "Memory.Inline slot \(slot) out of range 0..<\(capacity)")
        return unsafe withUnsafePointer(to: _storage) { base in
            unsafe UnsafeMutablePointer(
                mutating: UnsafeRawPointer(base)
                    .advanced(by: slot * MemoryLayout<Element>.stride)
                    .assumingMemoryBound(to: Element.self)
            )
        }
    }

    /// Returns an immutable pointer to the element at the given slot.
    ///
    /// Disfavored overload — when both mutable and immutable overloads
    /// match, the compiler prefers the mutable variant.
    ///
    /// - Parameter slot: The zero-based slot index.
    /// - Returns: An immutable pointer to the element at `slot`.
    /// - Precondition: `slot` must be in `0 ..< capacity`.
    @unsafe
    @inlinable
    @_disfavoredOverload
    public func pointer(at slot: Int) -> UnsafePointer<Element> {
        unsafe UnsafePointer(pointer(at: slot) as UnsafeMutablePointer<Element>)
    }
}

// MARK: - Properties

extension Memory.Inline where Element: ~Copyable {
    /// The byte stride between consecutive elements.
    ///
    /// Equal to `MemoryLayout<Element>.stride`. Provided as a convenience
    /// for callers performing manual byte arithmetic.
    @inlinable
    public var elementStride: Int {
        MemoryLayout<Element>.stride
    }
}

// MARK: - Sendable

/// Sendable conformance for `Memory.Inline._Raw`.
///
/// ## Safety Invariant
///
/// `Memory.Inline._Raw` is a `@_rawLayout` `~Copyable` package struct.
/// `@_rawLayout` bypasses normal Sendable analysis — the type is a
/// compile-time layout directive, not a conventional struct. Unique
/// ownership (via `~Copyable`) guarantees the raw bytes transfer as one
/// block; there is no aliasing path that could race.
///
/// ## Intended Use
///
/// - Internal raw storage for `Memory.Inline<Element, capacity>`; not a
///   consumer-facing API.
///
/// ## Non-Goals
///
/// - Not intended for direct use outside `memory-primitives`; marked
///   `package` for this reason.
/// - Does not track element initialization — callers manage lifecycle
///   through pointers.
extension Memory.Inline._Raw: @unsafe @unchecked Sendable where Element: Sendable {}

/// Sendable conformance for `Memory.Inline`.
///
/// ## Safety Invariant
///
/// `Memory.Inline<Element, capacity>` is `~Copyable` and holds its
/// storage inline via `_Raw` (`@_rawLayout`). The actual safety argument
/// is unique ownership. Transfer across isolation boundaries moves the
/// inline bytes without aliasing.
///
/// ## Intended Use
///
/// - Fixed-capacity typed inline memory moved between phases of a
///   pipeline (e.g., generating iterators, small buffers).
/// - Stack-allocated raw-memory regions handed to worker threads.
///
/// ## Non-Goals
///
/// - Does not track per-slot initialization; callers retain that
///   responsibility.
/// - Not shareable — inline storage is bound to the current owner.
extension Memory.Inline: @unsafe @unchecked Sendable where Element: Sendable {}
