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

// `Memory.Contiguous` is an OWNED contiguous region, so it conforms to the
// namespace-neutral OWNED span-vending capability `Span.\`Protocol\`` from
// `swift-span-primitives` (the institute-neutral lift of the former owned
// Memory contiguous protocol, relocated out of the Memory namespace so
// byte/binary/memory each conform without a cross-domain edge). Borrowed
// contiguous views are bare `Swift.Span<Element>` surfaced via
// `Span.Borrowed.\`Protocol\``; there is no nominal borrowed-contiguous type at
// this layer (orthogonality decision — keep-nominal is reserved for
// Path/String). See
// swift-institute/Research/memory-byte-bit-domain-orthogonality.md and
// cross-layer-capability-protocol-model.md §12.

public import Span_Protocol_Primitives

extension Memory.Contiguous: Span.`Protocol` {
    /// Safe, bounds-checked read access to the memory region.
    ///
    /// Returns a `Span` that borrows `self`, preventing the region from
    /// being destroyed while the span exists.
    ///
    /// - Complexity: O(1)
    public var span: Swift.Span<Element> {
        @_lifetime(borrow self)
        borrowing get {
            let s = unsafe Swift.Span(_unsafeStart: pointer, count: count)
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
