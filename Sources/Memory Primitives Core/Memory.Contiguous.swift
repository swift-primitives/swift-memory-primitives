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
    /// Namespace for contiguous memory access patterns.
    ///
    /// Types with contiguous storage can conform to ``Protocol`` to provide
    /// uniform access to their underlying memory.
    public enum Contiguous {}
}
