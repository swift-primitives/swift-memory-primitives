// Memory.Shift+Cardinal.Protocol.swift
// Cardinal.Protocol conformance for Memory.Shift.

extension Memory.Shift: Cardinal.`Protocol` {
    @inlinable
    public var cardinal: Cardinal {
        Cardinal(UInt(rawValue))
    }

    @inlinable
    public init(_ cardinal: Cardinal) {
        self.init(unchecked: UInt8(cardinal.rawValue))
    }
}
