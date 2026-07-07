// Memory.Alignment.swift
// Type-safe power-of-2 alignment (exponent-backed).

public import Carrier_Primitives

extension Memory {
    /// A power-of-2 alignment value (exponent-backed).
    ///
    /// Alignment is stored as an exponent (shift count), with magnitude
    /// computed per carrier type. This eliminates Int-width portability
    /// issues and enables correct operation across all fixed-width scalars.
    ///
    /// ## Storage
    ///
    /// Stores only `shift: Memory.Shift` (the exponent). Magnitude (`2^shift`)
    /// is computed on demand in the caller's chosen carrier type.
    ///
    /// ## API Pattern
    ///
    /// - **Primary**: `init(shift:)` or `init(magnitude:) throws`
    /// - **Constants**: Pre-validated static constants for common values
    /// - **Operations**: All alignment ops compute in the operand's ring
    ///
    /// ## Example
    ///
    /// ```swift
    /// let page = Memory.Alignment.page4096
    /// page.isAligned(pointer)              // checks pointer alignment
    ///
    /// // Get magnitude in specific carrier
    /// let mag: UInt64 = page.magnitude()   // 4096
    /// ```
    public struct Alignment: Sendable, Equatable, Hashable {
        /// The shift count (exponent).
        ///
        /// Magnitude is `2^shift`.
        public let shift: Memory.Shift
    }
}

// MARK: - Initializers

extension Memory.Alignment {
    /// Creates an alignment from a magnitude (power of 2).
    ///
    /// - Parameter magnitude: The alignment value. Must be a positive power of 2.
    /// - Throws: `Memory.Alignment.Error.notPowerOfTwo` if invalid.
    public init(
        _ magnitude: Int
    ) throws(Self.Error) {
        guard magnitude > 0, magnitude & (magnitude - 1) == 0 else {
            throw .notPowerOfTwo(magnitude)
        }
        // Safe: magnitude is power of 2 > 0, so trailingZeroBitCount is in valid range
        self.shift = Memory.Shift(unchecked: UInt8(magnitude.trailingZeroBitCount))
    }
}

// MARK: - Unchecked Initializer (Internal)

extension Memory.Alignment {
    /// Creates an alignment without validation (internal use).
    @usableFromInline
    internal init(uncheckedShift: UInt8) {
        self.shift = Memory.Shift(unchecked: uncheckedShift)
    }
}

// MARK: - Common Values

extension Memory.Alignment {
    /// 1-byte alignment (no alignment requirement).
    public static let byte = Memory.Alignment(uncheckedShift: 0)
    /// 1-byte alignment.
    public static let `1` = Memory.Alignment(uncheckedShift: 0)

    /// 2-byte alignment.
    public static let `2` = Memory.Alignment(uncheckedShift: 1)

    /// 4-byte alignment.
    public static let word = Memory.Alignment(uncheckedShift: 2)
    /// 4-byte alignment.
    public static let `4` = Memory.Alignment(uncheckedShift: 2)

    /// 8-byte alignment.
    public static let `8` = Memory.Alignment(uncheckedShift: 3)

    /// 16-byte alignment.
    public static let `16` = Memory.Alignment(uncheckedShift: 4)

    /// 512-byte alignment (legacy disk sector).
    public static let `512` = Memory.Alignment(uncheckedShift: 9)

    /// 1024-byte alignment.
    public static let `1024` = Memory.Alignment(uncheckedShift: 10)

    /// 4096-byte alignment (modern SSD sector, x86 page).
    public static let `4096` = Memory.Alignment(uncheckedShift: 12)

    /// 8192-byte alignment.
    public static let `8192` = Memory.Alignment(uncheckedShift: 13)

    /// 16384-byte alignment (Apple Silicon page).
    public static let `16384` = Memory.Alignment(uncheckedShift: 14)
}

// MARK: - Magnitude Access

extension Memory.Alignment {
    /// The alignment magnitude in the specified carrier type.
    ///
    /// Computes `2^shift` in the carrier ring.
    ///
    /// - Precondition: `shift < Carrier.bitWidth`
    public func magnitude<Carrier: FixedWidthInteger>(
        as _: Carrier.Type = Carrier.self
    ) -> Carrier {
        shift.magnitude(as: Carrier.self)
    }

    /// The bitmask for extracting offset within an aligned block.
    ///
    /// Computes `(2^shift) - 1` in the carrier ring.
    ///
    /// - Precondition: `shift < Carrier.bitWidth`
    public func mask<Carrier: FixedWidthInteger>(
        as _: Carrier.Type = Carrier.self
    ) -> Carrier {
        shift.mask(as: Carrier.self)
    }

    /// Validates that this alignment is usable with the given carrier type.
    ///
    /// - Throws: `Memory.Alignment.Error.shiftExceedsBitWidth` if shift >= bit width.
    public func validated<Carrier: FixedWidthInteger>(
        for _: Carrier.Type
    ) throws(Self.Error) -> Self {
        // `shift.rawValue` is a `Bit.Index.Count` (= `Tagged<Bit, Cardinal>`);
        // reinterpret its bit pattern as `Int` for the bit-width comparison.
        // `Memory.Shift` (unlike `Tagged<Tag, Cardinal>`) has no direct
        // `Int(bitPattern:)` overload of its own, so `.rawValue` is the
        // required single-hop unwrap to reach the exact typed argument
        // ([INFRA-002] integration overload's bottom-out) — not a re-chain
        // past it.
        // swiftlint:disable:next bitpattern_rawvalue_chain_anti_pattern
        let shiftCount = Int(bitPattern: shift.rawValue)
        guard shiftCount < Carrier.bitWidth else {
            // The exponent is bounded `0...63`, so the narrowing to the
            // `UInt8` report field is in range.
            throw .shiftExceedsBitWidth(shift: UInt8(shiftCount), bitWidth: Carrier.bitWidth)
        }
        return self
    }
}

// MARK: - Pointer Operations

extension Memory.Alignment {
    /// Checks if a pointer is aligned.
    ///
    /// - Parameter pointer: The pointer to check.
    /// - Returns: `true` if the pointer address is a multiple of this alignment.
    public func isAligned(_ pointer: UnsafeRawPointer) -> Bool {
        UInt(bitPattern: pointer) & shift.mask() == 0
    }

    /// Checks if a mutable pointer is aligned.
    ///
    /// - Parameter pointer: The pointer to check.
    /// - Returns: `true` if the pointer address is a multiple of this alignment.
    public func isAligned(_ pointer: UnsafeMutableRawPointer) -> Bool {
        UInt(bitPattern: pointer) & shift.mask() == 0
    }
}

// MARK: - Integer Operations

extension Memory.Alignment {
    /// Checks if an integer value is aligned.
    ///
    /// - Parameter value: The value to check.
    /// - Returns: `true` if the value is a multiple of this alignment.
    /// - Precondition: `shift < Scalar.bitWidth`
    @inlinable
    public func isAligned<Scalar: FixedWidthInteger>(_ value: Scalar) -> Bool {
        value & shift.mask() == 0
    }

    /// Rounds an integer value up to the nearest alignment boundary.
    ///
    /// Uses overflow-safe operators (`&+`) so the addition wraps rather than
    /// traps if `value` is near `Scalar.max`. The caller is responsible for
    /// ensuring the wrapped result is in the desired range.
    ///
    /// - Parameter value: The value to round up.
    /// - Returns: The smallest multiple of this alignment ≥ `value` (or wraps
    ///   if `value + mask` overflows `Scalar`).
    /// - Precondition: `shift < Scalar.bitWidth`
    @inlinable
    public func alignUp<Scalar: FixedWidthInteger>(_ value: Scalar) -> Scalar {
        let mask: Scalar = shift.mask()
        return (value &+ mask) & ~mask
    }

    /// Rounds an integer value down to the nearest alignment boundary.
    ///
    /// - Parameter value: The value to round down.
    /// - Returns: The largest multiple of this alignment ≤ `value`.
    /// - Precondition: `shift < Scalar.bitWidth`
    @inlinable
    public func alignDown<Scalar: FixedWidthInteger>(_ value: Scalar) -> Scalar {
        let mask: Scalar = shift.mask()
        return value & ~mask
    }
}

// MARK: - Carrier-Typed Alignment (Tagged-carried scalars)
//
// Lifts the FixedWidthInteger alignment operations above to any `Carrier.`Protocol``
// whose `Underlying` is a `FixedWidthInteger` — `Tagged<Tag, Int64>`, `Coordinate.X<Space>.Value<Int>`,
// `Binary.Aligned`-shaped wrappers, etc. The carrier abstraction is exactly the
// "wraps a scalar, round-trips via `init(_:Underlying)` and `.underlying`" shape these
// methods need, so a single overload covers every Tagged/Coordinate consumer.

extension Memory.Alignment {
    /// Checks if a Carrier-wrapped value is aligned.
    ///
    /// `@_disfavoredOverload` so a raw `FixedWidthInteger` scalar (e.g., `Int`,
    /// which also self-conforms to `Carrier.\`Protocol\`` via the
    /// `Underlying == Self` default) resolves to the scalar overload above
    /// rather than this Carrier-wrapped one.
    @_disfavoredOverload
    @inlinable
    public func isAligned<C: Carrier.`Protocol`>(_ value: C) -> Bool
    where C.Underlying: FixedWidthInteger {
        isAligned(value.underlying)
    }

    /// Rounds a Carrier-wrapped value up to the nearest alignment boundary.
    @_disfavoredOverload
    @inlinable
    public func alignUp<C: Carrier.`Protocol`>(_ value: C) -> C
    where C.Underlying: FixedWidthInteger {
        C(alignUp(value.underlying))
    }

    /// Rounds a Carrier-wrapped value down to the nearest alignment boundary.
    @_disfavoredOverload
    @inlinable
    public func alignDown<C: Carrier.`Protocol`>(_ value: C) -> C
    where C.Underlying: FixedWidthInteger {
        C(alignDown(value.underlying))
    }
}

// MARK: - Comparable

extension Memory.Alignment: Comparable {
    /// Returns whether `lhs` orders before `rhs`.
    public static func < (lhs: Memory.Alignment, rhs: Memory.Alignment) -> Bool {
        lhs.shift < rhs.shift
    }
}

// MARK: - CustomStringConvertible

extension Memory.Alignment: CustomStringConvertible {
    /// A textual representation of the value.
    public var description: String {
        "\(magnitude() as Int)"
    }
}
