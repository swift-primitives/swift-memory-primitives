public import Memory_Address_Primitives

extension UnsafeRawPointer {

    @inlinable
    public func advanced(
        by offset: Memory.Address.Offset
    ) -> Self {
        unsafe self.advanced(by: offset.vector.rawValue)
    }

    @inlinable
    public func load<T>(
        fromByteOffset offset: Memory.Address.Offset,
        as type: T.Type
    ) -> T {
        unsafe self.load(fromByteOffset: offset.vector.rawValue, as: type)
    }
}
