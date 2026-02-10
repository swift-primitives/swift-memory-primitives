// Memory.Alignment.Align.swift
// Directional alignment operations on cardinal quantities.

extension Memory.Alignment {
    /// Tag for directional alignment operations.
    public enum Align {}
}

// MARK: - Accessor

extension Memory.Alignment {
    /// Directional alignment operations.
    ///
    /// Provides `.up(_:)` and `.down(_:)` for rounding any
    /// `Cardinal.Protocol` conformer to the nearest alignment boundary.
    /// Both bare `Cardinal` and tagged wrappers like `Index<T>.Count`
    /// are accepted and returned type-preserving.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let page = Memory.Alignment.page4096
    /// let aligned = page.align.up(Cardinal(5000))   // Cardinal(8192)
    /// let count: Index<Storage>.Count = ...
    /// let aligned = page.align.up(count)             // Index<Storage>.Count
    /// ```
    @inlinable
    public var align: Property<Align, Memory.Alignment> {
        .init(self)
    }
}

// MARK: - Operations

extension Property where Tag == Memory.Alignment.Align, Base == Memory.Alignment {
    /// Rounds a cardinal quantity up to the nearest alignment boundary.
    ///
    /// Accepts any `Cardinal.Protocol` conformer and preserves its type.
    ///
    /// - Parameter value: The quantity to align.
    /// - Returns: The smallest aligned value ≥ input.
    /// - Precondition: `shift < UInt.bitWidth`
    @inlinable
    public func up<C: Cardinal.`Protocol`>(_ value: C) -> C {
        let mask: UInt = base.shift.mask()
        return C(Cardinal((value.cardinal.rawValue &+ mask) & ~mask))
    }

    /// Rounds a cardinal quantity down to the nearest alignment boundary.
    ///
    /// Accepts any `Cardinal.Protocol` conformer and preserves its type.
    ///
    /// - Parameter value: The quantity to align.
    /// - Returns: The largest aligned value ≤ input.
    /// - Precondition: `shift < UInt.bitWidth`
    @inlinable
    public func down<C: Cardinal.`Protocol`>(_ value: C) -> C {
        let mask: UInt = base.shift.mask()
        return C(Cardinal(value.cardinal.rawValue & ~mask))
    }
}
