public import Index_Primitives
public import Memory_Address_Primitives
import Property_Primitives

extension Memory {

    public enum Move {}
}

extension Property_Primitives.Property
where Tag == Memory.Move, Base == UnsafeMutableRawPointer {

    @inlinable
    @discardableResult
    public func initialize<T>(
        as type: T.Type,
        from source: UnsafeMutablePointer<T>,
        count: Index_Primitives.Index<T>.Count
    ) -> UnsafeMutablePointer<T> {
        unsafe base.moveInitializeMemory(as: type, from: source, count: Int(bitPattern: count))
    }
}
