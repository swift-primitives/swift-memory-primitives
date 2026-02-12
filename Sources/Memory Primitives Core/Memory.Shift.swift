// Memory.Shift.swift
// Type-safe bit shift count (exponent for power-of-2 values).

extension Memory {
    /// A bit shift count (exponent for power-of-2 values).
    ///
    /// Shift values represent the number of bit positions to shift,
    /// which is equivalent to log2 of the corresponding alignment.
    ///
    /// ## Invariant
    ///
    /// `rawValue` is always in `0...63` (sufficient for all fixed-width integers up to 64 bits).
    ///
    /// ## Relationship with Alignment
    ///
    /// - `alignment = 2^shift`
    /// - `shift = log2(alignment)`
    ///
    /// ## API Pattern
    ///
    /// - **Primary**: `init(_:) throws(Memory.Shift.Error)` — validates at runtime
    /// - **Constants**: Pre-validated static constants for common values
    ///
    /// ## Example
    ///
    /// ```swift
    /// let shift = try Memory.Shift(12)     // 12 bits
    /// let alignment = shift.alignment      // 4096 (2^12)
    /// ```
    public struct Shift: Sendable, Equatable, Hashable {
        /// The shift count (number of bit positions).
        ///
        /// Always in range `0...63`.
        public let rawValue: UInt8
    }
}

// MARK: - Constants

extension Memory.Shift {
    /// Maximum valid shift value (63 bits, covers UInt64).
    public static let maxValue: UInt8 = 63
}

// MARK: - Throwing Initializer

extension Memory.Shift {
    /// Creates a shift count with validation.
    ///
    /// - Parameter value: The number of bit positions. Must be in `0...63`.
    /// - Throws: `Memory.Shift.Error.outOfRange` if value is negative or > 63.
    @inlinable
    public init(_ value: Int) throws(Memory.Shift.Error) {
        guard value >= 0, value <= Int(Self.maxValue) else {
            throw .outOfRange(value: value, max: Self.maxValue)
        }
        self.rawValue = UInt8(value)
    }

    /// Creates a shift count from UInt8.
    ///
    /// - Parameter value: The number of bit positions. Must be <= 63.
    /// - Throws: `Memory.Shift.Error.outOfRange` if value > 63.
    @inlinable
    public init(_ value: UInt8) throws(Memory.Shift.Error) {
        guard value <= Self.maxValue else {
            throw .outOfRange(value: Int(value), max: Self.maxValue)
        }
        self.rawValue = value
    }
}

// MARK: - Unchecked Initializer (Internal)

extension Memory.Shift {
    /// Creates a shift count without validation.
    ///
    /// - Precondition: `value <= 63`
    @usableFromInline
    internal init(unchecked value: UInt8) {
        assert(value <= Self.maxValue, "Shift value out of range")
        self.rawValue = value
    }
}

// MARK: - Common Values

extension Memory.Shift {
    /// No shift (2^0 = 1).
    public static let zero = Memory.Shift(unchecked: 0)

    /// 1-bit shift (2^1 = 2).
    public static let one = Memory.Shift(unchecked: 1)

    /// 2-bit shift (2^2 = 4).
    public static let two = Memory.Shift(unchecked: 2)

    /// 3-bit shift (2^3 = 8).
    public static let three = Memory.Shift(unchecked: 3)

    /// 4-bit shift (2^4 = 16).
    public static let four = Memory.Shift(unchecked: 4)

    /// 9-bit shift (2^9 = 512, legacy sector).
    public static let nine = Memory.Shift(unchecked: 9)
    @available(*, deprecated, message: "Use '.nine'")
    public static let sector512 = Memory.Shift(unchecked: 9)

    /// 10-bit shift (2^10 = 1024).
    public static let kilo = Memory.Shift(unchecked: 10)

    /// 12-bit shift (2^12 = 4096, x86 page).
    public static let twelve = Memory.Shift(unchecked: 12)
    @available(*, deprecated, message: "Use '.twelve'")
    public static let page4096 = Memory.Shift(unchecked: 12)

    /// 13-bit shift (2^13 = 8192).
    public static let `8k` = Memory.Shift(unchecked: 13)

    /// 14-bit shift (2^14 = 16384, Apple Silicon page).
    public static let fourteen = Memory.Shift(unchecked: 14)
    @available(*, deprecated, message: "Use '.fourteen'")
    public static let page16384 = Memory.Shift(unchecked: 14)
}

// MARK: - Carrier-Specific Operations

extension Memory.Shift {
    /// Computes `2^shift` in the given carrier type.
    ///
    /// - Returns: The alignment magnitude in the carrier ring.
    /// - Precondition: `rawValue < Carrier.bitWidth`
    @inlinable
    public func magnitude<Carrier: FixedWidthInteger>(
        as _: Carrier.Type = Carrier.self
    ) -> Carrier {
        Carrier(1) << self
    }

    /// Computes the mask `(2^shift) - 1` in the given carrier type.
    ///
    /// - Returns: The low-bit mask in the carrier ring.
    /// - Precondition: `rawValue < Carrier.bitWidth`
    @inlinable
    public func mask<Carrier: FixedWidthInteger>(
        as _: Carrier.Type = Carrier.self
    ) -> Carrier {
        (Carrier(1) << self) &- 1
    }

    /// Validates that this shift is usable with the given carrier type.
    ///
    /// - Throws: `Memory.Shift.Error.outOfRange` if shift >= carrier bit width.
    @inlinable
    public func validated<Carrier: FixedWidthInteger>(
        for _: Carrier.Type
    ) throws(Memory.Shift.Error) -> Self {
        guard Int(rawValue) < Carrier.bitWidth else {
            throw .outOfRange(value: Int(rawValue), max: UInt8(Carrier.bitWidth - 1))
        }
        return self
    }
}

// MARK: - Comparable

extension Memory.Shift: Comparable {
    @inlinable
    public static func < (lhs: Memory.Shift, rhs: Memory.Shift) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
// MARK: - CustomStringConvertible

extension Memory.Shift: CustomStringConvertible {
    public var description: String {
        "\(rawValue)"
    }
}
