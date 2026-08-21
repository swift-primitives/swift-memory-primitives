extension Memory.Shift {

    public enum Error: Swift.Error, Sendable, Equatable {

        case outOfRange(value: Int, max: UInt8)
    }
}

extension Memory.Shift.Error: CustomStringConvertible {

    public var description: String {
        switch self {
        case .outOfRange(let value, let max):
            return "shift out of range (was \(value), valid: 0...\(max))"
        }
    }
}
