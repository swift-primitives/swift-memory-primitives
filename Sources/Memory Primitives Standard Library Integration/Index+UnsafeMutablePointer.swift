//
//  Index+UnsafeMutablePointer.swift
//  swift-index-primitives
//
//  Created by Coen ten Thije Boonkkamp on 27/01/2026.
//

// MARK: - UnsafeMutablePointer + Index Arithmetic

/// Advances a mutable pointer by a typed index offset.
@_transparent
public func + <Pointee: ~Copyable>(
    lhs: UnsafeMutablePointer<Pointee>,
    rhs: Index<Pointee>
) -> UnsafeMutablePointer<Pointee> {
    try! unsafe lhs + Int(rhs.position)
}

/// Advances a mutable pointer by a typed index offset.
@_transparent
public func + <Pointee: ~Copyable>(
    lhs: Index<Pointee>,
    rhs: UnsafeMutablePointer<Pointee>
) -> UnsafeMutablePointer<Pointee> {
    try! unsafe rhs + Int(lhs.position)
}

/// Subtracts a typed index offset from a mutable pointer.
@_transparent
public func - <Pointee: ~Copyable>(
    lhs: UnsafeMutablePointer<Pointee>,
    rhs: Index<Pointee>
) -> UnsafeMutablePointer<Pointee> {
    try! unsafe lhs - Int(rhs.position)
}

// MARK: - UnsafeMutablePointer Subscript

extension UnsafeMutablePointer where Pointee: ~Copyable {
    /// Accesses the element at the given typed index.
    ///
    /// This subscript enables type-safe pointer access using `Index<Pointee>`:
    ///
    /// ```swift
    /// (0..<count).forEach { i in
    ///     body(elements[i])  // i is Index<Element>
    /// }
    /// ```
    ///
    /// - Parameter index: A typed index into the pointer's memory.
    /// - Returns: The element at the specified index.
    @inlinable @inline(__always)
    public subscript(index: Index<Pointee>) -> Pointee {
        @_transparent
        unsafeAddress {
            unsafe UnsafePointer(self + index)
        }
        @_transparent
        unsafeMutableAddress {
            unsafe self + index
        }
    }
}

// MARK: - UnsafeMutablePointer Lifecycle Operations

extension UnsafeMutablePointer {
    /// Initializes the pointer's memory with the specified number of consecutive
    /// copies of the given value.
    ///
    /// - Parameters:
    ///   - repeatedValue: The instance to initialize this pointer's memory with.
    ///   - count: The number of consecutive copies to initialize.
    @inlinable
    public func initialize(
        repeating repeatedValue: Pointee,
        count: Index_Primitives_Core.Index<Pointee>.Count
    ) {
        try! unsafe self.initialize(repeating: repeatedValue, count: Int(count.count))
    }

    /// Deinitializes the specified number of values starting at this pointer.
    ///
    /// - Parameter count: The number of consecutive instances to deinitialize.
    /// - Returns: A raw pointer to the same address as this pointer.
    @inlinable
    @discardableResult
    public func deinitialize(
        count: Index_Primitives_Core.Index<Pointee>.Count
    ) -> UnsafeMutableRawPointer {
        try! unsafe self.deinitialize(count: Int(count.count))
    }

    /// Updates this pointer's initialized memory with the specified number
    /// of consecutive copies of the given value.
    ///
    /// - Parameters:
    ///   - repeatedValue: The value with which to update this pointer's memory.
    ///   - count: The number of consecutive elements to update.
    @inlinable
    public func update(
        repeating repeatedValue: Pointee,
        count: Index_Primitives_Core.Index<Pointee>.Count
    ) {
        try! unsafe self.update(repeating: repeatedValue, count: Int(count.count))
    }
}
