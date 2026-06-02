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

// Borrowed-view pairing: the borrowed counterpart of
// ``Memory/Contiguous`` is the nominal struct ``Memory/Contiguous/Borrowed``
// declared in `Memory.Contiguous.Borrowed.swift`. The prior
// `Memory.Contiguous<Element>.View = Span<Element>` typealias was
// retired in favour of the nominal struct, which can host the
// `Memory.Contiguous.Borrowed.\`Protocol\`` typealias and matches the
// institute Type/Type.Borrowed convention for passive borrow-views
// (per `nested-view-vs-borrowed-naming.md` v1.2.0).

extension Memory.Contiguous: Memory.ContiguousProtocol {
    /// Safe, bounds-checked read access to the memory region.
    ///
    /// Returns a `Span` that borrows `self`, preventing the region from
    /// being destroyed while the span exists.
    ///
    /// - Complexity: O(1)
    public var span: Span<Element> {
        @_lifetime(borrow self)
        borrowing get {
            let s = unsafe Span(_unsafeStart: pointer, count: count)
            return unsafe _overrideLifetime(s, borrowing: self)
        }
    }

    /// Unsafe read access for C interop with unannotated APIs.
    ///
    /// - Parameter body: A closure that receives the buffer pointer.
    /// - Returns: The value returned by `body`.
    /// - Throws: Rethrows any error thrown by `body`.
    /// - Complexity: O(1) plus the complexity of `body`.
    /// - Warning: The buffer pointer is only valid within `body`.
    public func withUnsafeBufferPointer<R, E: Swift.Error>(
        _ body: (UnsafeBufferPointer<Element>) throws(E) -> R
    ) throws(E) -> R {
        try unsafe body(unsafe UnsafeBufferPointer(start: pointer, count: count))
    }
}
