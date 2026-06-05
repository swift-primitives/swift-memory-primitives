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
    /// Namespace for the allocatable-leaf capability.
    ///
    /// `Memory.Allocatable.Protocol` adds sized self-allocation (`create`) and bulk
    /// relocation to `Memory.Tracked.Protocol` — the leaf-tier replacement for the
    /// eliminated `Store.Creatable.Protocol`. Conformed by the growable contiguous
    /// leaves (`Memory.Heap`, `Memory.Small`); fixed-capacity `Memory.Inline` does
    /// NOT conform (it cannot allocate). The growable buffer disciplines gate their
    /// grow surface on `where S == Storage.Contiguous<M>, M: Memory.Allocatable.Protocol`.
    public enum Allocatable {}
}
