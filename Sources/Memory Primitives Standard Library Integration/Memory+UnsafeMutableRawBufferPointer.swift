public import Index_Primitives
public import Memory_Address_Primitives
public import Memory_Alignment_Primitives

extension UnsafeMutableRawBufferPointer {

    @inlinable
    @_disfavoredOverload
    public init(
        start: UnsafeMutableRawPointer?,
        count: Memory.Address.Count
    ) {
        unsafe self.init(
            start: start,
            count: Int(bitPattern: count)
        )
    }

    @inlinable
    @_disfavoredOverload
    public static func allocate(
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) -> Self {
        Self.allocate(
            byteCount: Int(bitPattern: count),
            alignment: alignment.magnitude()
        )
    }

    @inlinable
    public subscript(
        _ index: Index_Primitives.Index<Memory>
    ) -> UInt8 {
        get {
            unsafe self[Int(bitPattern: index.position)]
        }
        nonmutating set {
            unsafe self[Int(bitPattern: index.position)] = newValue
        }
    }

    @inlinable
    public func load<T>(
        fromByteOffset offset: Memory.Address.Offset,
        as type: T.Type
    ) -> T {
        unsafe self.load(fromByteOffset: offset.vector.rawValue, as: type)
    }
}
