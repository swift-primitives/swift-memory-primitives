public import Memory_Address_Primitives
public import Memory_Alignment_Primitives

extension UnsafeMutableRawPointer {

    @inlinable
    public static func allocate(
        count: Memory.Address.Count,
        alignment: Memory.Alignment
    ) -> Self {
        Self.allocate(byteCount: Int(bitPattern: count), alignment: alignment.magnitude())
    }

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
