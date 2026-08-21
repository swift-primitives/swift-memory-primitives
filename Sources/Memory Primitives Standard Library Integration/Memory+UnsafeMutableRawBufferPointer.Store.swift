public import Memory_Address_Primitives
import Property_Primitives

extension UnsafeMutableRawBufferPointer {

    public enum Store {}
}

extension UnsafeMutableRawBufferPointer {

    @inlinable
    public var store: Property_Primitives.Property<Store, Self> {
        unsafe Property_Primitives.Property(self)
    }
}

extension Property_Primitives.Property
where Tag == UnsafeMutableRawBufferPointer.Store, Base == UnsafeMutableRawBufferPointer {

    @inlinable
    public func bytes<T>(
        of value: T,
        at offset: Memory.Address.Offset,
        as type: T.Type
    ) {
        unsafe base.storeBytes(of: value, toByteOffset: offset.vector.rawValue, as: type)
    }
}
