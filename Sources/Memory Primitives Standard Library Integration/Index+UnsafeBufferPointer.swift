// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

// MARK: - UnsafeBufferPointer + Index

extension UnsafeBufferPointer where Element: ~Copyable {
    /// Creates a buffer pointer from a start address and typed count.
    ///
    /// - Parameters:
    ///   - start: A pointer to the start of the buffer.
    ///   - count: The number of elements in the buffer as a typed count.
    @inlinable
    public init(
        start: UnsafePointer<Element>?,
        count: Index_Primitives_Core.Index<Element>.Count
    ) {
        try! unsafe self.init(start: start, count: Int(count.count))
    }
}

extension UnsafeBufferPointer {
    /// Accesses the element at the given typed index.
    ///
    /// This subscript enables type-safe buffer access using `Index<Element>`:
    ///
    /// ```swift
    /// let buffer = UnsafeBufferPointer(start: pointer, count: count)
    /// for i in (0..<count) {
    ///     print(buffer[i])  // i is Index<Element>
    /// }
    /// ```
    ///
    /// - Parameter index: A typed index into the buffer.
    /// - Returns: The element at the specified index.
    @inlinable
    public subscript(
        _ index: Index_Primitives_Core.Index<Element>
    ) -> Element {
        try! unsafe self[Int(index.position)]
    }
}
