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

public import Byte_Primitives

// MARK: - Memory.Contiguous.Borrowed.`Protocol` Conformance
//
// Conforms `Byte.Borrowed` to the institute's
// `Memory.Contiguous.Borrowed.Protocol` with `Element == Byte` — the
// `~Copyable & ~Escapable` protocol that captures the borrowed-contiguous-
// span read-access contract. This conformance is what makes
// `Cursor<Byte>` (and `Cursor<Text>`, and `Cursor<Binary>`) share a single
// operation extension parameterized on
// `where DomainTag.Borrowed: Memory.Contiguous<Byte>.Borrowed.\`Protocol\``,
// `DomainTag.Borrowed.Element == Byte`.
//
// Dependency-direction note: this conformance lives in memory-primitives
// (not byte-primitives) because byte is the larger / more foundational
// domain — bytes exist independently of memory abstractions. Memory is
// the smaller / more specific domain (structured operations on regions of
// byte-sized data). Per the institute's "smaller domain depends on larger
// domain" rule, memory-primitives depends on byte-primitives.

extension Byte.Borrowed: Memory.Contiguous<Byte>.Borrowed.`Protocol` {
    /// The element type.
    public typealias Element = Byte
}
