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

extension Memory.Alignment {
    /// Error from Alignment operations.
    public enum Error: Swift.Error, Sendable, Equatable {
        /// The value was not a power of 2.
        case notPowerOfTwo(Int)

        /// The shift exceeds the carrier's bit width.
        case shiftExceedsBitWidth(shift: UInt8, bitWidth: Int)
    }
}

extension Memory.Alignment.Error: CustomStringConvertible {
    /// A textual representation of the error.
    public var description: String {
        switch self {
        case .notPowerOfTwo(let value):
            return "alignment must be a power of 2 (was \(value))"

        case .shiftExceedsBitWidth(let shift, let bitWidth):
            return "shift \(shift) exceeds carrier bit width \(bitWidth)"
        }
    }
}
