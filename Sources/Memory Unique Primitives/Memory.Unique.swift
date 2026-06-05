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

public import Memory_Primitive

extension Memory {
    /// Namespace for the copy-on-write uniqueness capability.
    ///
    /// `Memory.Unique.Protocol` is the narrow CoW seam: a value-type façade over a
    /// shareable backing (an ARC class) that can check sole ownership and, when
    /// shared, deep-copy its live extent. Only the SHARING leaves conform (the
    /// ARC-backed `Memory.Heap` where its elements are `Copyable`); value-type leaves
    /// (`Memory.Inline`) never share and do NOT conform. `Storage.Contiguous` forwards
    /// the capability when its substrate has it. It lets the growable buffer
    /// disciplines partition their mutation surface by element-copyability —
    /// `where S.Element: Copyable` (CoW: `ensureUnique()` first) vs
    /// `where S.Element: ~Copyable` (no CoW; statically unique) — non-overlapping by
    /// Swift specificity, with NO `@_disfavoredOverload` priority hint.
    public enum Unique {}
}
