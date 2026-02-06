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

extension Memory.Contiguous {
    /// Protocol for types providing contiguous memory read access.
    ///
    /// Conforming types provide safe, bounds-checked read access to contiguous
    /// storage via ``span``, plus an unsafe escape hatch for C interop via
    /// ``withUnsafeBufferPointer(_:)``.
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
    ///
    ///     func withUnsafeBufferPointer<R, E: Swift.Error>(
    ///         _ body: (UnsafeBufferPointer<Element>) throws(E) -> R
    ///     ) throws(E) -> R {
    ///         // provide unsafe access for C interop
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
    /// ## Safe vs Unsafe Access
    ///
    /// | Method | Safety | Use Case |
    /// |--------|--------|----------|
    /// | ``span`` | Safe | Swift code, annotated C APIs |
    /// | ``withUnsafeBufferPointer(_:)`` | Unsafe | Unannotated C APIs |
    ///
    /// The safe property uses `Span` which is bounds-checked and lifetime-checked.
    /// The unsafe method provides raw pointer access for C interop with APIs that
    /// lack lifetime annotations.
    ///
    /// ## Topics
    ///
    /// ### Safe Access
    /// - ``span``
    ///
    /// ### Unsafe Access (C Interop)
    /// - ``withUnsafeBufferPointer(_:)``
    public protocol `Protocol`: ~Copyable {
        /// The type of element stored contiguously.
        ///
        /// - Note: Due to SE-0427 limitations, associated types cannot suppress
        ///   the Copyable requirement. Conforming types must have `Element: Copyable`.
        associatedtype Element

        /// Safe, bounds-checked read access to contiguous storage.
        ///
        /// Returns a `Span` that borrows `self`, preventing the container from
        /// being moved or mutated while the span exists. This makes the span
        /// safe for both heap-allocated and inline storage.
        ///
        /// - Complexity: O(1)
        var span: Span<Element> { get }

        /// Unsafe read access for C interop with unannotated APIs.
        ///
        /// Use this method when calling C functions that take pointer parameters
        /// without lifetime annotations. For annotated C APIs, prefer ``span``.
        ///
        /// - Parameter body: A closure that receives the buffer pointer.
        /// - Returns: The value returned by `body`.
        /// - Complexity: O(1) plus the complexity of `body`.
        /// - Warning: The buffer pointer is only valid within `body`.
        func withUnsafeBufferPointer<R, E: Swift.Error>(
            _ body: (UnsafeBufferPointer<Element>) throws(E) -> R
        ) throws(E) -> R
    }
}
