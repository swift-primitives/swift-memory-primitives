// Memory.Alignment.swift
// Type-safe power-of-2 alignment (exponent-backed).

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
        /// The shift count (exponent). Magnitude is `2^shift`.
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
    ) throws(Memory.Alignment.Error) {
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
    public static let `1` = Memory.Alignment(uncheckedShift: 0)

    /// 2-byte alignment.
    public static let halfWord = Memory.Alignment(uncheckedShift: 1)
    public static let `2` = Memory.Alignment(uncheckedShift: 1)

    /// 4-byte alignment.
    public static let word = Memory.Alignment(uncheckedShift: 2)
    public static let `4` = Memory.Alignment(uncheckedShift: 2)

    /// 8-byte alignment.
    public static let doubleWord = Memory.Alignment(uncheckedShift: 3)
    public static let `8` = Memory.Alignment(uncheckedShift: 3)

    /// 16-byte alignment.
    public static let quadWord = Memory.Alignment(uncheckedShift: 4)
    public static let `16` = Memory.Alignment(uncheckedShift: 4)

    /// 512-byte alignment (legacy disk sector).
    public static let sector512 = Memory.Alignment(uncheckedShift: 9)
    public static let `512` = Memory.Alignment(uncheckedShift: 9)

    /// 1024-byte alignment.
    public static let `1024` = Memory.Alignment(uncheckedShift: 10)

    /// 4096-byte alignment (modern SSD sector, x86 page).
    public static let page4096 = Memory.Alignment(uncheckedShift: 12)
    public static let `4096` = Memory.Alignment(uncheckedShift: 12)

    /// 8192-byte alignment.
    public static let `8192` = Memory.Alignment(uncheckedShift: 13)

    /// 16384-byte alignment (Apple Silicon page).
    public static let page16384 = Memory.Alignment(uncheckedShift: 14)
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
    ) throws(Memory.Alignment.Error) -> Self {
        guard Int(shift.rawValue) < Carrier.bitWidth else {
            throw .shiftExceedsBitWidth(shift: shift.rawValue, bitWidth: Carrier.bitWidth)
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
        let address = UInt(bitPattern: pointer)
        let mask: UInt = shift.mask()
        return address & mask == 0
    }

    /// Checks if a mutable pointer is aligned.
    ///
    /// - Parameter pointer: The pointer to check.
    /// - Returns: `true` if the pointer address is a multiple of this alignment.
    public func isAligned(_ pointer: UnsafeMutableRawPointer) -> Bool {
        let address = UInt(bitPattern: pointer)
        let mask: UInt = shift.mask()
        return address & mask == 0
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
        let mask: Scalar = shift.mask()
        return value & mask == 0
    }
}

// MARK: - Comparable

extension Memory.Alignment: Comparable {
    public static func < (lhs: Memory.Alignment, rhs: Memory.Alignment) -> Bool {
        lhs.shift < rhs.shift
    }
}

// MARK: - CustomStringConvertible

extension Memory.Alignment: CustomStringConvertible {
    public var description: String {
        let mag: Int = magnitude()
        return "\(mag)"
    }
}
