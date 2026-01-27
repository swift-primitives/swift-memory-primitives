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

extension Memory.Arena {
    /// Errors that can occur during arena operations.
    public enum Error: Swift.Error, Equatable, Sendable {
        /// Insufficient space in arena.
        case insufficientCapacity(requested: Int, available: Int)
    }
}
