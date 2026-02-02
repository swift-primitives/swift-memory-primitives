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
    /// Protocol for types providing contiguous memory access.
    ///
    /// Conforming types provide safe, bounds-checked access to contiguous storage
    /// via ``span`` and ``mutableSpan`` properties, plus unsafe escape hatches
    /// for C interop via ``withUnsafeBufferPointer(_:)`` and
    /// ``withUnsafeMutableBufferPointer(_:)``.
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
    ///         get { /* return span over storage */ }
    ///     }
    ///
    ///     var mutableSpan: MutableSpan<Element> {
    ///         @_lifetime(&self)
    ///         mutating get { /* return mutable span */ }
    ///     }
    ///
    ///     func withUnsafeBufferPointer<R, E: Swift.Error>(
    ///         _ body: (UnsafeBufferPointer<Element>) throws -> R
    ///     ) throws(E) -> R {
    ///         // provide unsafe access for C interop
    ///     }
    ///
    ///     mutating func withUnsafeMutableBufferPointer<R, E: Swift.Error>(
    ///         _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
    ///     ) throws(E) -> R {
    ///         // provide mutable unsafe access
    ///     }
    /// }
    /// ```
    ///
    /// ## Safe vs Unsafe Access
    ///
    /// | Method | Safety | Use Case |
    /// |--------|--------|----------|
    /// | ``span`` | Safe | Swift code, annotated C APIs |
    /// | ``mutableSpan`` | Safe | Swift code, annotated C APIs |
    /// | ``withUnsafeBufferPointer(_:)`` | Unsafe | Unannotated C APIs |
    /// | ``withUnsafeMutableBufferPointer(_:)`` | Unsafe | Unannotated C APIs |
    ///
    /// The safe properties use `Span`/`MutableSpan` which are bounds-checked and
    /// lifetime-checked. The unsafe methods provide raw pointer access for C interop
    /// with APIs that lack lifetime annotations.
    ///
    /// ## Topics
    ///
    /// ### Safe Access
    /// - ``span``
    /// - ``mutableSpan``
    ///
    /// ### Unsafe Access (C Interop)
    /// - ``withUnsafeBufferPointer(_:)``
    /// - ``withUnsafeMutableBufferPointer(_:)``
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

        /// Safe, bounds-checked write access to contiguous storage.
        ///
        /// Returns a `MutableSpan` that exclusively borrows `self`, preventing
        /// concurrent access. Changes made through the span are reflected in
        /// the container.
        ///
        /// - Complexity: O(1)
        var mutableSpan: MutableSpan<Element> { mutating get }

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

        /// Unsafe write access for C interop with unannotated APIs.
        ///
        /// Use this method when calling C functions that take mutable pointer
        /// parameters without lifetime annotations. For annotated C APIs,
        /// prefer ``mutableSpan``.
        ///
        /// - Parameter body: A closure that receives the mutable buffer pointer.
        /// - Returns: The value returned by `body`.
        /// - Complexity: O(1) plus the complexity of `body`.
        /// - Warning: The buffer pointer is only valid within `body`.
        mutating func withUnsafeMutableBufferPointer<R, E: Swift.Error>(
            _ body: (UnsafeMutableBufferPointer<Element>) throws(E) -> R
        ) throws(E) -> R
    }
}
