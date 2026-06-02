// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Carrier_Primitives

// MARK: - Carrier.Protocol Conformance
//
// `Memory.Shift` conforms to Carrier-of-Cardinal so that shift counts can be
// passed to APIs taking `some Carrier<Cardinal>`.

extension Memory.Shift: Carrier.`Protocol` {
    /// The underlying scalar type carried by the shift.
    public typealias Underlying = Cardinal
    /// Shifts are unscoped (not phantom-typed).
    public typealias Domain = Never

    /// The shift count as its underlying cardinal value.
    @inlinable
    public var underlying: Cardinal {
        Cardinal(UInt(rawValue))
    }

    /// Creates a shift from its underlying cardinal value.
    @inlinable
    public init(_ underlying: Cardinal) {
        self.init(unchecked: UInt8(underlying.rawValue))
    }
}
