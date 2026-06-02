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

extension Memory.Shift {
    /// Error from Shift operations.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// The shift value was out of valid range.
        case outOfRange(value: Int, max: UInt8)
    }
}

extension Memory.Shift.Error: CustomStringConvertible {
    /// A textual representation of the error.
    public var description: String {
        switch self {
        case .outOfRange(let value, let max):
            return "shift out of range (was \(value), valid: 0...\(max))"
        }
    }
}
