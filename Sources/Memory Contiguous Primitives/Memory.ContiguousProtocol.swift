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
    /// Protocol for types providing contiguous memory read access.
    ///
    /// Conforming types provide safe, bounds-checked read access to contiguous
    /// storage via ``span`` — the protocol's single requirement. Raw pointer access
    /// for C interop derives from the span (`span.withUnsafeBufferPointer { … }`).
    ///
    /// ## Design Rationale
    ///
    /// This protocol is **read-only by default**. Mutable access is type-specific:
    ///
    /// - **Structs** can provide `var mutableSpan: MutableSpan<Element> { mutating get }`
    /// - **Classes** must use closure-based `func withMutableSpan(_:)` (no mutating getters)
    ///
    /// The protocol captures what ALL conforming types can provide. Read access is
    /// universal; write access varies by type.
    ///
    /// ## Conforming to Memory.Contiguous.Protocol
    ///
    /// Types with contiguous storage should conform regardless of storage strategy
    /// (heap or inline). The ``span`` property works safely for both because
    /// Swift's `@lifetime` annotation ensures the container cannot be moved or
    /// mutated while the span exists.
    ///
    /// ```swift
    /// extension MyContainer: Memory.Contiguous.Protocol {
    ///     var span: Span<Element> {
    ///         @_lifetime(borrow self)
    ///         borrowing get {
    ///             let ptr = /* get pointer to storage */
    ///             let span = Span(_unsafeStart: ptr, count: count)
    ///             return _overrideLifetime(span, borrowing: self)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// ## Mutable Access (Type-Specific)
    ///
    /// Conforming types provide mutable access through type-specific APIs:
    ///
    /// ```swift
    /// // Struct: property-based
    /// var mutableSpan: MutableSpan<Element> {
    ///     @_lifetime(&self)
    ///     mutating get { ... }
    /// }
    ///
    /// // Class: closure-based
    /// func withMutableSpan<R, E: Swift.Error>(
    ///     _ body: (inout MutableSpan<Element>) throws(E) -> R
    /// ) throws(E) -> R { ... }
    /// ```
    ///
    /// ## Raw Pointer Access (C Interop)
    ///
    /// `span` is bounds- and lifetime-checked. For unannotated C APIs that need a
    /// raw pointer, call `withUnsafeBufferPointer(_:)` **on the span**
    /// (`mySpan.withUnsafeBufferPointer { … }`) — there is no container-level escape
    /// hatch to provide; the span is the surface.
    ///
    /// ## Topics
    ///
    /// ### Access
    /// - ``span``
    public protocol ContiguousProtocol: ~Copyable {
        /// The type of element stored contiguously.
        associatedtype Element: ~Copyable

        /// Safe, bounds-checked read access to contiguous storage.
        ///
        /// Returns a `Span` that borrows `self`, preventing the container from
        /// being moved or mutated while the span exists. This makes the span
        /// safe for both heap-allocated and inline storage.
        ///
        /// Raw pointer access for C interop is available on the returned span
        /// itself (`span.withUnsafeBufferPointer { … }`); the protocol's single
        /// requirement is `span`, and everything else derives from it.
        ///
        /// - Complexity: O(1)
        var span: Span<Element> { get }
    }
}
