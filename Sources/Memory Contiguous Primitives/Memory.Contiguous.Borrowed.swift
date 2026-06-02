// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-memory-primitives open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-memory-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

extension Memory.Contiguous {
    /// Borrowed view of a contiguous memory region.
    ///
    /// `~Copyable & ~Escapable` borrow-view over `Swift.Span<Element>`,
    /// parallel to ``Byte/Borrowed``, ``String/Borrowed``, ``Path/Borrowed``,
    /// and ``Ownership/Borrow``. Replaces the prior
    /// `Memory.Contiguous<Element>.View = Span<Element>` typealias with a
    /// nominal struct that can host the canonical conformance protocol.
    ///
    /// ## Naming Convention
    ///
    /// Per `nested-view-vs-borrowed-naming.md` v1.2.0: Pattern 1 borrow-views
    /// (passive projections) use `.Borrowed`; Pattern 3 stateful cursors use
    /// `.View`. `Memory.Contiguous.Borrowed` is Pattern 1 — a passive
    /// projection over contiguous memory.
    ///
    /// ## Lifetime
    ///
    /// `~Copyable & ~Escapable`. The view cannot be duplicated and cannot
    /// outlive the source span it borrows. The compiler enforces this via
    /// `@_lifetime(borrow span)` on the initializer.
    ///
    /// ## Type-Level Invariant
    ///
    /// Encodes "this is a borrowed view of contiguous Element-typed memory."
    /// The span field is publicly readable to let consumers (cursors,
    /// parsers, serializers) access bytes directly without going through a
    /// closure-based accessor.
    ///
    /// ## Conformance to `Borrowed.Protocol`
    ///
    /// Self-conforms to ``Memory/Contiguous/Borrowed/Protocol`` — the
    /// hoisted protocol that ``Byte/Borrowed`` and ``Binary/Borrowed`` also
    /// conform to. The unified protocol enables `Cursor<DomainTag>`
    /// operations parameterized on
    /// `where DomainTag.Borrowed: Memory.Contiguous.Borrowed.\`Protocol\``.
    ///
    /// ## Safety Invariant
    ///
    /// Safe by construction — backing storage uses only stdlib safe types;
    /// `@safe` documents that this type performs no unsafe operations.
    @safe
    public struct Borrowed: ~Copyable, ~Escapable {
        @usableFromInline
        internal let _span: Swift.Span<Element>

        /// Creates a borrowed view from a span.
        ///
        /// The view's lifetime is bound to the span's lifetime.
        @inlinable
        @_lifetime(borrow span)
        public init(_ span: borrowing Swift.Span<Element>) {
            self._span = copy span
        }

        /// The borrowed span of elements.
        @inlinable
        public var span: Swift.Span<Element> {
            @_lifetime(copy self) get { _span }
        }

        /// The number of elements the borrowed view spans.
        @inlinable
        public var count: Int { _span.count }

        /// Canonical conformance path for the borrowed-contiguous-memory protocol.
        ///
        /// Conform via `extension Foo.Borrowed: Memory.Contiguous.Borrowed.\`Protocol\` {}`.
        /// The typealias resolves to the module-scope
        /// `__Memory_Contiguous_Borrowed_Protocol` (hoisted because SE-0404
        /// prohibits protocol nesting inside a generic struct).
        public typealias `Protocol` = __Memory_Contiguous_Borrowed_Protocol
    }
}

// Self-conformance is intentionally omitted (parallel to Ownership.Borrow
// which also does not self-conform). The `Protocol` typealias is hosted
// here as a canonical spelling for OTHER conformers (`Byte.Borrowed`,
// `Binary.Borrowed`, future borrowed-view types) to use via
// `extension Foo.Borrowed: Memory.Contiguous.Borrowed.\`Protocol\` {}`.
