extension Memory {

    public struct Shift: Sendable, Equatable, Hashable {

        public let rawValue: Bit.Index.Count
    }
}

extension Memory.Shift {

    public static let maxValue: UInt8 = 63
}

extension Memory.Shift {

    @inlinable
    public init(_ value: Int) throws(Self.Error) {
        guard value >= 0, value <= Int(Self.maxValue) else {
            throw .outOfRange(value: value, max: Self.maxValue)
        }

        self.rawValue = Bit.Index.Count(UInt(value))
    }

    @inlinable
    public init(_ value: UInt8) throws(Self.Error) {
        guard value <= Self.maxValue else {
            throw .outOfRange(value: Int(value), max: Self.maxValue)
        }
        self.rawValue = Bit.Index.Count(UInt(value))
    }
}

extension Memory.Shift {

    @inlinable
    package init(unchecked value: UInt8) {
        assert(value <= Self.maxValue, "Shift value out of range")
        self.rawValue = Bit.Index.Count(UInt(value))
    }
}

extension Memory.Shift {

    public static let zero = Memory.Shift(unchecked: 0)

    public static let one = Memory.Shift(unchecked: 1)

    public static let two = Memory.Shift(unchecked: 2)

    public static let three = Memory.Shift(unchecked: 3)

    public static let four = Memory.Shift(unchecked: 4)

    public static let nine = Memory.Shift(unchecked: 9)

    public static let kilo = Memory.Shift(unchecked: 10)

    public static let twelve = Memory.Shift(unchecked: 12)

    public static let `8k` = Memory.Shift(unchecked: 13)

    public static let fourteen = Memory.Shift(unchecked: 14)
}

extension Memory.Shift {

    @inlinable
    public func magnitude<Carrier: FixedWidthInteger>(
        as _: Carrier.Type = Carrier.self
    ) -> Carrier {
        do throws(Self.Error) {
            _ = try validated(for: Carrier.self)
        } catch {
            preconditionFailure(
                "Memory.Shift \(rawValue) exceeds \(Carrier.bitWidth)-bit carrier width"
            )
        }
        return Carrier(1) << self
    }

    @inlinable
    public func mask<Carrier: FixedWidthInteger>(
        as _: Carrier.Type = Carrier.self
    ) -> Carrier {
        do throws(Self.Error) {
            _ = try validated(for: Carrier.self)
        } catch {
            preconditionFailure(
                "Memory.Shift \(rawValue) exceeds \(Carrier.bitWidth)-bit carrier width"
            )
        }
        return (Carrier(1) << self) &- 1
    }

    @inlinable
    public func validated<Carrier: FixedWidthInteger>(
        for _: Carrier.Type
    ) throws(Self.Error) -> Self {
        let count = Int(bitPattern: rawValue)
        guard count < Carrier.bitWidth else {
            throw .outOfRange(value: count, max: UInt8(Carrier.bitWidth - 1))
        }
        return self
    }
}

extension Memory.Shift: Comparable {

    @inlinable
    public static func < (lhs: Memory.Shift, rhs: Memory.Shift) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Memory.Shift: CustomStringConvertible {

    public var description: String {
        "\(rawValue)"
    }
}
