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
    /// Namespace for the tracked-leaf ledger capability.
    ///
    /// `Memory.Tracked.Protocol` is the narrow ledger seam — the leaf-tier
    /// replacement for the eliminated universal `Store.Tracked.Protocol`. Only the
    /// self-cleaning memory leaves (Heap, Inline, Small) conform; `Storage.Contiguous`
    /// forwards the ledger conditionally rather than conforming.
    public enum Tracked {}
}
