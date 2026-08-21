public import Index_Primitives
public import Memory_Address_Primitives

extension UnsafeRawBufferPointer {

    @inlinable
    @_disfavoredOverload
    public init(
        start: UnsafeRawPointer?,
        count: Memory.Address.Count
    ) {
        unsafe self.init(
            start: start,
            count: Int(bitPattern: count)
        )
    }

    @inlinable
    public subscript(
        _ index: Index_Primitives.Index<Memory>
    ) -> UInt8 {
        unsafe self[Int(bitPattern: index.position)]
    }

    @inlinable
    public func load<T>(
        fromByteOffset offset: Memory.Address.Offset,
        as type: T.Type
    ) -> T {
        unsafe self.load(fromByteOffset: offset.vector.rawValue, as: type)
    }
}
