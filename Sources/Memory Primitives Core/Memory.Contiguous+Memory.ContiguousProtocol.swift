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
    /// The borrowed view of a contiguous memory region.
    ///
    /// Follows the Type/Type.View pattern:
    /// - `Memory.Contiguous<Element>` — owned
    /// - `Memory.Contiguous<Element>.View` (= `Span<Element>`) — borrowed
    public typealias View = Span<Element>
}

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
    /// - Complexity: O(1) plus the complexity of `body`.
    /// - Warning: The buffer pointer is only valid within `body`.
    public func withUnsafeBufferPointer<R, E: Swift.Error>(
        _ body: (UnsafeBufferPointer<Element>) throws(E) -> R
    ) throws(E) -> R {
        try unsafe body(unsafe UnsafeBufferPointer(start: pointer, count: count))
    }
}
