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

extension Memory {
    /// Fixed-capacity typed memory region embedded inline in the containing struct.
    ///
    /// `Memory.Inline<Element, capacity>` provides zero-overhead typed inline
    /// storage using `@_rawLayout`. It does not track element initialization —
    /// callers manage lifecycle through the returned pointers.
    ///
    /// ## Relationship to Storage.Inline
    ///
    /// `Memory.Inline` is the raw memory layer. `Storage.Inline<N>` (in
    /// storage-primitives) composes `Memory.Inline` with per-slot initialization
    /// tracking (`Bit.Vector.Static<4>`) for lifecycle safety. Use `Memory.Inline`
    /// directly when you manage initialization yourself (e.g., generating
    /// iterators with a `Bool` flag).
    ///
    /// ## Zero Overhead
    ///
    /// The struct has exactly `MemoryLayout<Element>.stride × capacity` bytes
    /// of storage. No bitmap, no count, no metadata.
    ///
    /// ## ~Copyable Elements
    ///
    /// The `Element: ~Copyable` constraint means this type supports both
    /// `Copyable` and `~Copyable` element types. Since `@_rawLayout` uses
    /// raw memory, elements are initialized and deinitialized through pointers:
    ///
    /// ```swift
    /// var inline = Memory.Inline<Element, 1>()
    /// unsafe inline.pointer(at: 0).initialize(to: element)
    /// // ... use element through pointer ...
    /// unsafe inline.pointer(at: 0).deinitialize(count: 1)
    /// ```
    ///
    /// ## Naming
    ///
    /// "Inline" describes where the memory lives — inline within the containing
    /// struct — paralleling ``Memory/Contiguous`` which describes the heap
    /// counterpart.
    public struct Inline<Element: ~Copyable, let capacity: Int>: ~Copyable {
        /// Internal raw storage with automatic layout computation.
        ///
        /// Uses `@_rawLayout(likeArrayOf: Element, count: capacity)` to compute
        /// optimal layout at compile time:
        /// - Size: `MemoryLayout<Element>.stride × capacity`
        /// - Alignment: `MemoryLayout<Element>.alignment`
        @_rawLayout(likeArrayOf: Element, count: capacity)
        @usableFromInline
        package struct _Raw: ~Copyable {
            @usableFromInline
            init() {}
        }

        @usableFromInline
        package var _storage: _Raw

        /// Creates uninitialized inline memory.
        ///
        /// All `capacity` slots contain indeterminate memory. The caller is
        /// responsible for initializing elements through ``pointer(at:)-mut``
        /// before reading them, and for deinitializing them before this value
        /// is destroyed.
        @inlinable
        public init() {
            _storage = _Raw()
        }
    }
}
