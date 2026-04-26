// Memory.Shift+Cardinal.Protocol.swift
// Memory.Shift conforms to Carrier-of-Cardinal so that shift counts can
// be passed to APIs taking `some Carrier<Cardinal>`.
//
// File name preserved for git-history continuity; the conformance
// surface has migrated from the legacy `Cardinal.\`Protocol\`` to the
// parameterized `Carrier<Cardinal>` super-protocol.

public import Carrier_Primitives

extension Memory.Shift: Carrier {
    public typealias Underlying = Cardinal
    /// Shifts are unscoped (not phantom-typed).
    public typealias Domain = Never

    @inlinable
    public var underlying: Cardinal {
        Cardinal(UInt(rawValue))
    }

    @inlinable
    public init(_ underlying: Cardinal) {
        self.init(unchecked: UInt8(underlying.rawValue))
    }
}
