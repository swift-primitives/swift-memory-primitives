//
//  Index+UnsafeMutablePointer.Move.swift
//  swift-index-primitives
//
//  Created by Coen ten Thije Boonkkamp on 27/01/2026.
//

import Property_Primitives

// MARK: - Tag Type

extension UnsafeMutablePointer {
    /// Tag for move operations on typed pointers.
    public enum Move {}
}

// MARK: - Accessor

extension UnsafeMutablePointer {
    /// Namespace for move operations.
    ///
    /// Use this accessor for move-based initialization and update:
    ///
    /// ```swift
    /// pointer.move.initialize(from: source, count: count)
    /// pointer.move.update(from: source, count: count)
    /// ```
    @inlinable
    public var move: Property_Primitives.Property<Move, Self> {
        unsafe Property_Primitives.Property(self)
    }
}

// MARK: - Property Extension

extension Property_Primitives.Property {

    /// Moves instances from source memory into uninitialized memory.
    ///
    /// The source memory is left uninitialized after the move.
    ///
    /// - Parameters:
    ///   - source: A pointer to the values to move.
    ///   - count: The number of values to move.
    @inlinable
    public func initialize<Pointee>(
        from source: UnsafeMutablePointer<Pointee>,
        count: Index_Primitives_Core.Index<Pointee>.Count
    ) where Tag == UnsafeMutablePointer<Pointee>.Move, Base == UnsafeMutablePointer<Pointee> {
        unsafe base.moveInitialize(
            from: source,
            count: Int(bitPattern: count.count)
        )
    }

    /// Moves instances from source memory to replace values at this pointer.
    ///
    /// The source memory is left uninitialized after the move.
    /// The destination memory must already be initialized.
    ///
    /// - Parameters:
    ///   - source: A pointer to the values to move.
    ///   - count: The number of values to move.
    @inlinable
    public func update<Pointee>(
        from source: UnsafeMutablePointer<Pointee>,
        count: Index_Primitives_Core.Index<Pointee>.Count
    ) where Tag == UnsafeMutablePointer<Pointee>.Move, Base == UnsafeMutablePointer<Pointee> {
        unsafe base.moveUpdate(from: source, count: Int(bitPattern: count.count))
    }
}
