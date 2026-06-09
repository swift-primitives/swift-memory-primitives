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
    /// Namespace for the element-free raw-region capability.
    ///
    /// `Memory.Region.Protocol` is the seam an allocator carves within: a stable base address
    /// plus a byte capacity, nothing element-typed. It is conformed by the raw byte resources
    /// (`Memory.Heap`, `Memory.Inline`, `Memory.Contiguous<Byte>`) and required by
    /// `Memory.Allocator<Resource>` of its `Resource`. It is seam/Storage *implementation*
    /// structure — a convenience that lets a generic allocator read its resource's base — NOT a
    /// new layer; the tower stays Memory → Allocator → Storage → Buffer → ADT.
    public enum Region {}
}
