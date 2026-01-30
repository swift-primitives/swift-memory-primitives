// Memory.Aligned.swift
// Protocol for types with power-of-2 alignment requirements.

extension Memory {
    /// A type with power-of-2 alignment requirements.
    ///
    /// Aligned types ensure all offsets and lengths snap to alignment boundaries,
    /// which is essential for Direct I/O, memory mapping, and block device operations.
    ///
    /// ## Mathematical Model
    ///
    /// An aligned type defines valid byte positions as multiples of the alignment:
    /// - The **alignment** `a` is a power of 2 (512, 4096, 16384, etc.)
    /// - Every valid offset is an integer multiple of `a`: offset = n × a
    /// - Alignment checks use efficient bitwise operations
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct Page4096Buffer: Memory.Aligned {
    ///     static var alignment: Memory.Alignment { .page4096 }
    ///     // ...
    /// }
    ///
    /// // Check if a value is aligned
    /// Page4096Buffer.alignment.isAligned(4096)  // true
    /// Page4096Buffer.alignment.isAligned(1000)  // false
    ///
    /// // Round to alignment boundary
    /// Page4096Buffer.alignment.alignUp(1000)    // 4096
    /// Page4096Buffer.alignment.alignDown(5000)  // 4096
    /// ```
    public protocol Aligned {
        /// The alignment requirement.
        static var alignment: Memory.Alignment { get }
    }
}
