//
//  Index+UnsafeMutableRawPointer.Memory.Move.swift
//  swift-index-primitives
//
//  Created by Coen ten Thije Boonkkamp on 27/01/2026.
//

import Property_Primitives
public import Memory_Primitives_Core

// MARK: - Tag Type

extension Memory {
    /// Tag for move operations on raw pointer memory.
    public enum Move {}
}

// MARK: - Property Extension

extension Property_Primitives.Property
where Tag == Memory.Move, Base == UnsafeMutableRawPointer {

    /// Initializes memory by moving values from a source.
    ///
    /// The source memory is left uninitialized after the move.
    ///
    /// - Parameters:
    ///   - type: The type to initialize memory as.
    ///   - source: A pointer to the values to move.
    ///   - count: The number of instances to move.
    /// - Returns: A typed pointer to the initialized memory.
    @inlinable
    @discardableResult
    public func initialize<T>(
        as type: T.Type,
        from source: UnsafeMutablePointer<T>,
        count: Index_Primitives_Core.Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe base.moveInitializeMemory(as: type, from: source, count: Int(bitPattern: count.count))
    }
}
