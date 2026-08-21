public import Carrier_Primitives

extension Memory.Alignment {

    public enum Align {}
}

extension Memory.Alignment {

    @inlinable
    public var align: Property<Align, Memory.Alignment> {
        .init(self)
    }
}

extension Property where Tag == Memory.Alignment.Align, Base == Memory.Alignment {

    @inlinable
    public func up<C: Carrier.`Protocol`<Cardinal>>(_ value: C) -> C {
        let mask: UInt = base.shift.mask()
        return C(Cardinal((value.underlying.rawValue &+ mask) & ~mask))
    }

    @inlinable
    public func down<C: Carrier.`Protocol`<Cardinal>>(_ value: C) -> C {
        C(Cardinal(value.underlying.rawValue & ~base.shift.mask()))
    }
}
