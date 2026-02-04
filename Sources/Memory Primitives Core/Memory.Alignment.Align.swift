// Memory.Alignment.Align.swift
// Directional alignment operations on Cardinal values.

extension Memory.Alignment {
    /// Directional alignment accessor.
    ///
    /// Provides `.up(_:)` and `.down(_:)` for rounding a `Cardinal`
    /// to the nearest alignment boundary in either direction.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let page = Memory.Alignment.page4096
    /// let aligned = page.align.up(Cardinal(5000))   // 8192
    /// let floored = page.align.down(Cardinal(5000)) // 4096
    /// ```
    public struct Align: Sendable {
        @usableFromInline
        internal let shift: Memory.Shift

        @inlinable
        internal init(shift: Memory.Shift) {
            self.shift = shift
        }
    }
}

// MARK: - Accessor

extension Memory.Alignment {
    /// Directional alignment operations.
    @inlinable
    public var align: Align {
        Align(shift: shift)
    }
}

// MARK: - Operations

extension Memory.Alignment.Align {
    /// Rounds a cardinal value up to the nearest alignment boundary.
    ///
    /// - Parameter value: The quantity to align.
    /// - Returns: The smallest aligned value ≥ input.
    /// - Precondition: `shift < UInt.bitWidth`
    @inlinable
    public func up(_ value: Cardinal) -> Cardinal {
        let mask: UInt = shift.mask()
        return Cardinal((value.rawValue &+ mask) & ~mask)
    }

    /// Rounds a cardinal value down to the nearest alignment boundary.
    ///
    /// - Parameter value: The quantity to align.
    /// - Returns: The largest aligned value ≤ input.
    /// - Precondition: `shift < UInt.bitWidth`
    @inlinable
    public func down(_ value: Cardinal) -> Cardinal {
        let mask: UInt = shift.mask()
        return Cardinal(value.rawValue & ~mask)
    }
}
