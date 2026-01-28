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

extension Tagged where Tag == Memory, RawValue == Ordinal {
    /// Errors that can occur when creating a memory address.
    public enum Error: Swift.Error, Equatable, Hashable, Sendable {
        /// The pointer was null.
        case null
    }
}
