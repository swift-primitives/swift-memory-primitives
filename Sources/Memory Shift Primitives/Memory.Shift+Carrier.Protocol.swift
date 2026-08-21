public import Carrier_Primitives

extension Memory.Shift: Carrier.`Protocol` {

    public typealias Underlying = Cardinal

    public typealias Domain = Never

    @inlinable
    public var underlying: Cardinal {
        rawValue.underlying
    }

    @inlinable
    public init(_ underlying: Cardinal) {
        self.init(unchecked: UInt8(underlying.rawValue))
    }
}
