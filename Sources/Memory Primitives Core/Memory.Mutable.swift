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

extension Memory {
    /// Marker type for mutable memory access.
    ///
    /// Used as a phantom tag for mutable buffer types like `Memory.Buffer.Mutable`.
    public enum Mutable {}
}
