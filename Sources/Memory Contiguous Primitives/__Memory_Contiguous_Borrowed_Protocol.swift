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

/// Module-scope hoisted protocol for ``Memory/Contiguous/Borrowed/Protocol``.
///
/// Use the canonical spelling `Memory.Contiguous.Borrowed.\`Protocol\`` at
/// conformance sites. This `__`-prefixed declaration is the
/// implementation-detail target of the nested typealias inside
/// ``Memory/Contiguous/Borrowed`` and is not intended for direct reference.
///
/// Conformers expose a `Span<Element>` view of a contiguous byte region with
/// `~Copyable & ~Escapable` lifetime semantics. The canonical conformers are:
///
/// - ``Memory/Contiguous/Borrowed`` itself (trivial self-conformance).
/// - ``Byte/Borrowed`` from `swift-byte-primitives` (Element = Byte).
/// - ``Binary/Borrowed`` from `swift-binary-primitives` (Element = Byte).
///
/// This protocol is the sibling-shaped counterpart to
/// ``Memory/Contiguous/Protocol`` (which is for OWNED contiguous storage like
/// ``Memory/Contiguous`` itself, requiring Escapable Self). The two protocols
/// are kept separate because their lifetime contracts are structurally
/// distinct: owned conformers borrow self and return Span via
/// `_overrideLifetime(borrowing: self)`; borrowed conformers ARE
/// `~Escapable` Self with lifetime flowing from the original borrow
/// scope. A single protocol cannot polymorphically express both — the
/// witness-table contract for `var span: Span<Element> { get }` differs
/// across the two lifetime regimes.
///
/// Precedent for the hoisting pattern: `__Ownership_Borrow_Protocol` in
/// `swift-ownership-primitives`. SE-0404 opened non-generic protocol nesting
/// only; direct nesting inside the generic struct
/// ``Memory/Contiguous/Borrowed`` remains prohibited on Swift 6.3.1.
public protocol __Memory_Contiguous_Borrowed_Protocol: ~Copyable, ~Escapable {
    /// The type of element stored contiguously.
    associatedtype Element: ~Copyable

    /// Safe, bounds-checked read access to the borrowed contiguous span.
    ///
    /// The span's lifetime flows from the borrowed source — conformers
    /// typically store the span directly and return it without any
    /// lifetime-override machinery, since `Self` is `~Escapable` and its
    /// scope IS the lifetime.
    ///
    /// - Complexity: O(1)
    var span: Swift.Span<Element> {
        @_lifetime(copy self) get
    }
}
